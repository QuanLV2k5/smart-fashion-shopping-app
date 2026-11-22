"""Orders REST/JWT and race integration test for a disposable Supabase local database."""
from concurrent.futures import ThreadPoolExecutor
from contextlib import contextmanager
from argparse import ArgumentParser
import json
import os
from pathlib import Path
import subprocess
import time
from urllib.error import HTTPError
from urllib.parse import urlsplit
from urllib.request import Request, urlopen
from uuid import UUID, uuid4


LOCAL_HOSTS = {"localhost", "127.0.0.1", "::1"}


def require_local(name, schemes):
    value = os.environ[name]
    parsed = urlsplit(value)
    if parsed.scheme not in schemes or parsed.hostname not in LOCAL_HOSTS or parsed.query or parsed.fragment:
        raise ValueError(f"{name} must point to the disposable local instance")
    return value


def expect(condition, label):
    if not condition:
        raise AssertionError(label)


class OrdersTest:
    def __init__(self):
        self.url = require_local("ORDERS_TEST_API_URL", {"http", "https"}).rstrip("/")
        self.dsn = require_local("ORDERS_TEST_DB_URL", {"postgres", "postgresql"})
        self.key = os.environ["ORDERS_TEST_ANON_KEY"]
        self.tokens = {role: os.environ[f"ORDERS_TEST_{role}_JWT"] for role in ("A", "B", "ADMIN")}
        self.psql = ["psql", "-X", "-qAt", "-v", "ON_ERROR_STOP=1", "--dbname", self.dsn]

    def http(self, role, route, payload=None, method=None, status=200, error=None):
        headers = {"apikey": self.key, "Content-Type": "application/json", "Prefer": "return=representation"}
        if role:
            headers["Authorization"] = f"Bearer {self.tokens[role]}"
        request = Request(f"{self.url}/rest/v1/{route}",
                          data=None if payload is None else json.dumps(payload).encode(),
                          headers=headers, method=method)
        try:
            with urlopen(request, timeout=25) as response:
                actual, body = response.status, response.read()
        except HTTPError as response:
            actual, body = response.code, response.read()
        result = json.loads(body) if body else None
        if isinstance(status, tuple):
            expect(actual in status, f"{role} {route}: unexpected HTTP {actual}")
            return actual, result
        expect(actual == status, f"{role} {route}: expected HTTP {status}, got {actual}")
        if error is not None:
            expect(result.get("message") == error, f"{role} {route}: expected {error}")
        return result

    def rpc(self, role, name, payload=None, **kwargs):
        return self.http(role, f"rpc/{name}", payload if payload is not None else {}, **kwargs)

    def sql(self, command):
        result = subprocess.run([*self.psql, "-c", command], capture_output=True, text=True, timeout=10)
        expect(result.returncode == 0, "local psql probe failed")
        return result.stdout.strip()

    @contextmanager
    def gate(self, table, row_id):
        # Only constant table names and normalized UUIDs reach SQL.
        expect(table in {"product_variants", "orders"}, "unexpected gate table")
        row_id = str(UUID(row_id))
        with subprocess.Popen(self.psql, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                              stderr=subprocess.DEVNULL, text=True) as process:
            try:
                process.stdin.write(f"begin;\nselect id from public.{table} where id = '{row_id}' "
                                    "for update;\nselect pg_backend_pid();\n")
                process.stdin.flush()
                expect(process.stdout.readline().strip() == row_id, "could not acquire race gate")
                pid = int(process.stdout.readline().strip())
                yield pid
            finally:
                # Closing the connection also releases the lock if an assertion fails.
                process.stdin.close()
                process.wait(timeout=5)
                expect(process.returncode == 0, "local psql race gate failed")

    def wait_until_blocked(self, pid):
        deadline = time.monotonic() + 8
        while time.monotonic() < deadline:
            blockers = self.sql(f"""
                with recursive waiting(pid) as (
                  select {int(pid)}
                  union
                  select activity.pid from pg_stat_activity activity
                  join waiting w on w.pid = any(pg_blocking_pids(activity.pid))
                ) select count(*) - 1 from waiting
            """)
            if int(blockers) >= 2:
                return
            time.sleep(0.1)
        raise AssertionError("two requests were not observed waiting on the database gate")

    def race(self, table, row_id, rpc_name, requests):
        with ThreadPoolExecutor(max_workers=2) as executor:
            with self.gate(table, row_id) as pid:
                futures = [executor.submit(self.race_call, rpc_name, role, args) for role, args in requests]
                self.wait_until_blocked(pid)
            outcomes = [future.result() for future in futures]
        successes = [(role, body) for role, status, body in outcomes if status == 200]
        conflicts = [body["message"] for _, status, body in outcomes if status == 409]
        expect(len(successes) == 1 and len(conflicts) == 1, f"{rpc_name}: expected one success and one conflict")
        return successes[0], conflicts[0]

    def race_call(self, name, role, args):
        status, body = self.http(role, f"rpc/{name}", args, status=(200, 409))
        return role, status, body

    def run(self):
        rows = self.http("ADMIN", "product_variants?sku=eq.SF01-WHITE-M&select=id,stock_revision")
        expect(len(rows) == 1, "missing demo variant")
        variant = rows[0]
        prepared = self.rpc("ADMIN", "set_variant_stock", {
            "p_variant_id": variant["id"], "p_expected_revision": variant["stock_revision"], "p_new_stock": 1
        })
        quotes = {}
        for role in ("A", "B"):
            expect(self.rpc(role, "list_my_orders")["items"] == [], f"{role} must be a fresh test account")
            expect(self.rpc(role, "get_cart")["items"] == [], f"{role} must have an empty cart")
            address = self.http(role, "addresses", {
                "recipient_name": f"Orders test {role}", "phone": "0900000001", "address_line": "1 Fixture Street",
                "ward": "Fixture Ward", "district": "Fixture District", "city": "Fixture City",
            }, status=201)[0]
            self.rpc(role, "mutate_cart", {
                "p_variant_id": variant["id"], "p_quantity": 1, "p_operation": "add", "p_request_id": str(uuid4())
            })
            quote = self.rpc(role, "create_checkout_quote", {"p_address_id": address["id"]})
            expect(quote["subtotal_vnd"] == 199000 and quote["shipping_vnd"] == 25000
                   and quote["total_vnd"] == 224000, "server pricing")
            quotes[role] = {"p_quote_id": quote["quote_id"], "p_request_id": str(uuid4())}

        (owner, placed), conflict = self.race("product_variants", variant["id"], "place_cod_order", quotes.items())
        expect(conflict == "SF_STOCK_CHANGED", f"stock race: unexpected error {conflict}")
        other = "B" if owner == "A" else "A"
        order_id = placed["result"]["order_id"]
        self.rpc(other, "get_order", {"p_order_id": order_id}, status=404, error="SF_ORDER_NOT_FOUND")
        self.rpc(other, "list_admin_orders", status=403, error="SF_FORBIDDEN")
        self.http(owner, f"orders?id=eq.{order_id}", status=403)
        self.http("ADMIN", f"orders?id=eq.{order_id}", {"status": "completed"}, method="PATCH", status=403)
        expect(self.rpc(owner, "place_cod_order", quotes[owner])["replayed"], "REST retry")
        self.rpc(owner, "place_cod_order", {
            "p_quote_id": quotes[other]["p_quote_id"], "p_request_id": quotes[owner]["p_request_id"]
        }, status=409, error="SF_REQUEST_CONFLICT")
        expect(not self.rpc(other, "lookup_order_request",
                            {"p_request_id": quotes[owner]["p_request_id"]})["found"], "receipt isolation")
        self.rpc("ADMIN", "set_variant_stock", {
            "p_variant_id": variant["id"], "p_expected_revision": prepared["stock_revision"], "p_new_stock": 1
        }, status=409, error="SF_STOCK_VERSION_CONFLICT")
        expect(self.http("ADMIN", f"product_variants?id=eq.{variant['id']}&select=stock")[0]["stock"] == 0,
               "last unit was consumed once")

        (actor, changed), conflict = self.race("orders", order_id, "change_order_status", [
            ("ADMIN", {"p_order_id": order_id, "p_target_status": "confirmed",
                       "p_expected_version": 1, "p_request_id": str(uuid4())}),
            (owner, {"p_order_id": order_id, "p_target_status": "cancelled", "p_reason_code": "customer_requested",
                     "p_expected_version": 1, "p_request_id": str(uuid4())}),
        ])
        expect(conflict == "SF_ORDER_VERSION_CONFLICT", f"version race: unexpected error {conflict}")
        final = self.rpc("ADMIN", "get_order", {"p_order_id": order_id})
        final_status = "confirmed" if actor == "ADMIN" else "cancelled"
        stock = self.http("ADMIN", f"product_variants?id=eq.{variant['id']}&select=stock")[0]["stock"]
        expect(final["version"] == 2 and len(final["events"]) == 2 and stock == int(final_status == "cancelled")
               and final["status"] == final_status == changed["result"]["status"], "transition committed once")
        print("PASS: REST JWT ownership, admin authorization, last-unit race and status-version race")


if __name__ == "__main__":
    parser = ArgumentParser()
    parser.add_argument("--bootstrap", type=Path, metavar="STATUS_JSON",
                        help="create fresh test users using disposable Supabase CLI status JSON")
    args = parser.parse_args()
    if args.bootstrap:
        settings = json.loads(args.bootstrap.read_text(encoding="utf-8"))
        for name in ("API_URL", "DB_URL", "ANON_KEY"):
            os.environ[f"ORDERS_TEST_{name}"] = settings[name]
        api = require_local("ORDERS_TEST_API_URL", {"http", "https"}).rstrip("/")
        dsn = require_local("ORDERS_TEST_DB_URL", {"postgres", "postgresql"})

        def auth_post(route, key, body):
            request = Request(f"{api}/auth/v1/{route}", data=json.dumps(body).encode(),
                              headers={"apikey": key, "Authorization": f"Bearer {key}",
                                       "Content-Type": "application/json"})
            try:
                with urlopen(request, timeout=15) as response:
                    return json.load(response)
            except HTTPError as error:
                raise AssertionError(f"local Auth {route}: HTTP {error.code}") from None

        for role in ("A", "B", "ADMIN"):
            credentials = {"email": f"orders-{role.lower()}-{uuid4().hex}@example.com",
                           "password": uuid4().hex}
            user = auth_post("admin/users", settings["SERVICE_ROLE_KEY"], {**credentials, "email_confirm": True})
            if role == "ADMIN":
                user_id = str(UUID(user["id"]))
                result = subprocess.run(
                    ["psql", "-X", "-qAt", "-v", "ON_ERROR_STOP=1", "--dbname", dsn, "-c",
                     f"update public.user_roles set role = 'admin' where user_id = '{user_id}' returning user_id"],
                    capture_output=True, text=True, timeout=10,
                )
                expect(result.returncode == 0 and result.stdout.strip() == user_id, "could not assign local admin")
            session = auth_post("token?grant_type=password", settings["ANON_KEY"], credentials)
            os.environ[f"ORDERS_TEST_{role}_JWT"] = session["access_token"]
    OrdersTest().run()
