# Chốt Sprint 1 — thao tác tối giản cho Quân, Hải, Phúc

## 1. Hiểu đúng trạng thái

App S1 đã chạy theo xác nhận của Quân và hai thành viên; đây không phải tuyên bố checkout/AI/admin S2 đã xong. Hồ sơ mới chỉ rút gọn checklist và gom evidence, không thay code Flutter/quyền/migration. Các ca bổ sung vẫn được giữ ở #21, việc phê duyệt/ước lượng/cải tiến ở #23.

## 2. Hải review một lần

1. Mở PR nhánh `docs/sprint1-closeout-evidence` do Quân tạo.
2. Đọc `sprint-1-closeout-decision.md`, `sprint-1-evidence-index.md` và diff DoD. Kiểm tra ảnh SQL có PASS và ảnh rollback có 0 fixture; SQL role/claim không bị gọi là REST JWT.
3. Kiểm tra source/ảnh hoặc chức năng phần mình nếu cần. Không bắt chụp lại tất cả màn đã có evidence; nếu thấy lỗi thật, dùng Request changes và mô tả cách tái hiện.
4. Khi đồng ý: Files changed → Review changes → Approve → Submit review. Approve chỉ được bấm bằng tài khoản Hải, Codex/Quân không làm thay.

## 3. Phúc xác nhận ngắn

Đọc report cart/Retro/matrix trong PR. Nếu đúng, phản hồi trong review/Issue #23: “Tôi đã đọc phần giỏ/địa chỉ, matrix và ghi nhận Retro 13/11; thống nhất áp dụng từ 17/11 việc cập nhật main trước PR, giữ regression Profile và evidence theo commit/build.” Đây là mẫu để **Phúc tự xác nhận khi đúng**, không phải phát biểu đã có. Phúc không cần gửi mật khẩu/JWT hoặc dựng lại cuộc họp.

## 4. Quân merge và chốt

1. Chờ ít nhất một peer approval đúng HEAD và CI xanh; không bypass main ruleset. Nếu thêm commit sau approve, kiểm tra approval còn hợp lệ.
2. Create a merge commit → Merge pull request → Confirm merge. PR dùng `Closes #1`…`Closes #9`, GitHub đóng các Issue S1 khi merge vào main; giữ commit tác giả.
3. Mở milestone S1 kiểm tra 0 Issue mở. Nếu Project chưa tự đồng bộ, chuyển đúng các Issue đã Closed sang Done; không chuyển #21/#23 sang Done. Sau đó Close milestone S1. Nếu có Issue bị thành viên mở lại vì lỗi thật, đọc lý do và xử lý trước, không đóng đè để đủ số.
4. Pull main `git switch main` rồi `git pull --ff-only`. Không dùng reset/clean để xóa thay đổi cá nhân. Bản `.vscode/settings.json` hiện có trên máy Quân được giữ nguyên.

## 5. Việc sau chốt vẫn có người theo dõi

- Quân: #23, phản hồi giảng viên về Charter/phạm vi/lịch/đầu ra, ghi ngày/kênh hoặc bằng chứng được phép chia sẻ; chưa có phản hồi thì ghi đang chờ. Không cần đưa email/chat riêng tư lên repo.
- Cả ba: xác nhận cải tiến và ước lượng S2 từ thời điểm thật; S1 không có SP thì không dựng Poker/velocity.
- Phúc tổng hợp, Quân/Hải phối hợp theo module: #21 kiểm thử REST JWT/mạng/phân quyền trước release #22. Không gửi JWT/mật khẩu trong chat hoặc PR.
- App đầy đủ theo R4 vẫn phải hoàn thiện **25/11/2026**; không dùng việc chốt S1 để bỏ chức năng còn lại.
