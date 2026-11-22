"""Auth/JWT/API tests against a fresh loopback Supabase only. No shared cloud."""
import argparse
import base64
import json
import subprocess
from urllib.parse import urlparse
from urllib.request import Request, urlopen
from urllib.error import HTTPError
from uuid import uuid4


def expect(condition, label):
    if not condition:
        raise AssertionError(label)


def local_url(value, schemes):
    parsed = urlparse(value)
    expect(parsed.scheme in schemes and parsed.hostname in {"localhost", "127.0.0.1", "::1"},
           "Tests require disposable loopback Supabase")
    return value


def run(status):
    api = local_url(status["API_URL"], {"http", "https"}).rstrip("/")
    db = local_url(status["DB_URL"], {"postgres", "postgresql"})
    anon, service = status["ANON_KEY"], status["SERVICE_ROLE_KEY"]

    def http(path, token=anon, data=None, method=None, code=200, error=None, raw=None):
        headers = {"apikey": anon, "Authorization": f"Bearer {token}"}
        body = raw
        if data is not None:
            body = json.dumps(data).encode()
            headers["Content-Type"] = "application/json"
        if raw is not None:
            headers["Content-Type"] = "image/png"
        request = Request(f"{api}/{path}", data=body, headers=headers, method=method)
        try:
            with urlopen(request, timeout=20) as response:
                actual, result = response.status, response.read()
        except HTTPError as failure:
            actual, result = failure.code, failure.read()
        expect(actual == code, f"{path.split('?')[0]}: expected {code}, got {actual}")
        decoded = json.loads(result) if result else None
        if error:
            expect(decoded.get("message") == error, f"{path}: unexpected error code")
        return decoded

    def rpc(name, token=anon, data=None, **kwargs):
        return http(f"rest/v1/rpc/{name}", token, {} if data is None else data, **kwargs)

    def sql(statement):
        result = subprocess.run(["psql", "-X", "-qAt", "-v", "ON_ERROR_STOP=1", db, "-c", statement],
                                capture_output=True, text=True, timeout=15)
        expect(result.returncode == 0, "isolated database fixture setup")
        return result.stdout.strip()

    accounts = {}
    for role in ("A", "B", "ADMIN"):
        credentials = {"email": f"q06-{role.lower()}-{uuid4().hex}@example.com", "password": uuid4().hex}
        user = http("auth/v1/admin/users", service, {**credentials, "email_confirm": True,
                    "user_metadata": {"full_name": f"Q06 {role}", "role": "admin"}})
        if role == "ADMIN":
            sql(f"update public.user_roles set role='admin' where user_id='{user['id']}'")
        session = http("auth/v1/token?grant_type=password", data=credentials)
        accounts[role] = (user["id"], session["access_token"])
    a_id, a = accounts["A"]
    b_id, b = accounts["B"]
    admin_id, admin = accounts["ADMIN"]

    expect(not rpc("get_my_access", a)["is_admin"], "metadata must not grant admin")
    rpc("list_app_users", a, code=403, error="SF_FORBIDDEN")
    http("rest/v1/user_roles", a, {"role": "admin"}, "PATCH", code=403)
    product = http("rest/v1/products?select=id,product_variants(id)&code=eq.SF01", a)[0]
    pid, variant = product["id"], product["product_variants"][0]["id"]
    sql(f"update public.product_variants set stock=10 where id='{variant}'")
    favorite = {"p_product_id": pid, "p_favorite": True}
    rpc("set_favorite", a, favorite, code=204)
    rpc("set_favorite", a, favorite, code=204)
    expect(len(rpc("get_favorites", a)["items"]) == 1, "favorite retry must not duplicate")
    expect(not rpc("get_favorites", b)["items"], "favorite A/B JWT isolation")

    review = {"p_product_id": pid, "p_rating": 5, "p_body": "Chất liệu tốt"}
    rpc("submit_product_review", a, review, code=403, error="SF_REVIEW_PURCHASE_REQUIRED")
    address = {"user_id": a_id, "recipient_name": "Q06 A", "phone": "0901234567", "address_line": "1 Test",
               "ward": "Ward", "district": "District", "city": "City"}
    http("rest/v1/addresses", a, address, code=201)
    address_id = http(f"rest/v1/addresses?select=id&user_id=eq.{a_id}", a)[0]["id"]
    rpc("mutate_cart", a, {"p_variant_id": variant, "p_quantity": 1, "p_operation": "add", "p_request_id": str(uuid4())})
    quote = rpc("create_checkout_quote", a, {"p_address_id": address_id})
    placed = rpc("place_cod_order", a, {"p_quote_id": quote["quote_id"], "p_request_id": str(uuid4())})
    order_id = placed["result"]["order_id"]
    rpc("submit_product_review", a, review, code=403, error="SF_REVIEW_PURCHASE_REQUIRED")
    for version, target in enumerate(("confirmed", "shipping", "completed"), start=1):
        rpc("change_order_status", admin, {"p_order_id": order_id, "p_target_status": target,
            "p_expected_version": version, "p_request_id": str(uuid4())})
    rpc("submit_product_review", b, review, code=403, error="SF_REVIEW_PURCHASE_REQUIRED")
    rpc("submit_product_review", a, review, code=204)
    rpc("submit_product_review", a, review, code=204)
    public_reviews = rpc("get_product_reviews", data={"p_product_id": pid})
    expect(public_reviews["count"] == 1 and public_reviews["average"] == 5, "verified review/retry/rating")
    expect(not ({"user_id", "email", "phone"} & public_reviews["items"][0].keys()), "public reviewer privacy")
    expect(not rpc("get_product_reviews", b, {"p_product_id": pid})["can_review"], "review eligibility A/B")

    png = base64.b64decode("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aXxkAAAAASUVORK5CYII=")
    http(f"storage/v1/object/avatars/{a_id}/q06-active.png", a, raw=png)
    rpc("set_user_access", admin, {"p_user_id": admin_id, "p_blocked": True, "p_expected_version": 0},
        code=403, error="SF_PROTECTED_ACCOUNT")
    rpc("set_user_access", admin, {"p_user_id": a_id, "p_blocked": True, "p_expected_version": 0})
    rpc("set_user_access", admin, {"p_user_id": a_id, "p_blocked": False, "p_expected_version": 0},
        code=409, error="SF_ACCESS_VERSION_CONFLICT")
    # Keep using the JWT issued BEFORE blocking: immediate database checks must reject it.
    for name in ("get_cart", "get_favorites", "consume_ai_request", "list_my_orders", "get_my_access"):
        rpc(name, a, code=403, error="SF_ACCESS_BLOCKED")
    http("rest/v1/products?select=id", a, code=403, error="SF_ACCESS_BLOCKED")
    http(f"storage/v1/object/avatars/{a_id}/q06-blocked.png", a, raw=png, code=403)
    expect(rpc("get_product_reviews", data={"p_product_id": pid})["count"] == 1, "blocking preserves public review history")
    rpc("set_user_access", admin, {"p_user_id": a_id, "p_blocked": False, "p_expected_version": 1})
    expect(len(rpc("get_favorites", a)["items"]) == 1, "unblock preserves favorites")
    expect(rpc("get_order", a, {"p_order_id": order_id})["status"] == "completed", "unblock preserves order history")
    print("PASS: real Auth/JWT favorite ownership, completed COD review, duplicate retry, admin/role, existing-session block, Storage and unblock")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--bootstrap", required=True)
    args = parser.parse_args()
    with open(args.bootstrap, encoding="utf-8") as status_file:
        run(json.load(status_file))
