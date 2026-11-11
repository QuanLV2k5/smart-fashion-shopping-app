# Nhật ký điều chỉnh ước lượng R3 ngày 04/11/2026

Trạng thái: cập nhật kế hoạch/nội dung Issue theo yêu cầu của Quân; chưa phải dữ liệu Actual hay phê duyệt của giảng viên. Bản trước nằm trong history/truoc-dieu-chinh-uoc-luong-2026-11-04.

## Căn cứ và giả định

Quân tự đánh giá Q01 + Q02 khoảng 2 giờ. Chia dự toán thành Q01 0,5 giờ và Q02 1,5 giờ; giờ thực tế chưa được cung cấp. Các gói còn lại được ước lượng lại theo đầu ra MVP dùng thiết kế/mẫu sẵn có, không nhân một hệ số giảm đồng loạt. Chưa có dữ liệu tốc độ của Hải/Phúc; rà lại sau hai buổi làm đầu tiên và cuối Sprint 1.

## Thay đổi phạm vi gói và cân bằng

- Q01: tạo dự thảo/tập hợp thông tin/sending ban đầu. Review/phê duyệt, WBS hoàn thiện và chữ ký tiếp tục trong Q07/Q10/Q14/H07/H11. Không bỏ hồ sơ bắt buộc.
- Q02: bootstrap và cấu hình chạy bản đầu trong 90 phút. Phần dữ liệu catalog, seed, kiểm chứng quyền và hoàn thiện CI/ERD/README/onboarding có effort riêng tại Q03.
- Q03: Quân nhận Data repository/model/truy vấn catalog từ H02, cùng kiểm chứng và bàn giao. Đây là việc kỹ thuật thật được chuyển người, không tăng giờ hỗ trợ để bù số.
- Q03 phân bổ 6 giờ: Data repository 3; quyền 1; CI/ERD/README 0,5; onboarding 0,5; phối hợp Sprint 1. Nhịp họp được rút gọn, không cộng một quỹ họp ngoài tổng giờ.
- H02: Hải làm UI/Riverpod/presentation/domain và tích hợp repository Q03. Không viết lại phần Data Quân đã nhận.
- P01 xác định dữ liệu/trường hợp test; Q03 triển khai seed tái tạo. Việc test, review và tài liệu nằm trong gói tương ứng; không tính hai lần.
- Due date Q01/Q02 là 04/11 cho bản khởi tạo; Q03 07/11; H01 08/11; P01 05/11. Các mốc demo/UAT/nộp giữ theo kế hoạch.
- CPM được tính lại để bootstrap không chiếm ba ngày; giờ công và cửa sổ ngày lịch được phân biệt.
- Đây là điều chỉnh estimate và ranh giới gói trong kế hoạch, không tự gọi là Approved Change Request của học phần.

## Tổng dự toán

| Sprint | Quân | Hải | Phúc | Tổng |
|---|---:|---:|---:|---:|
| 1 | 8 | 8.5 | 8.5 | 25 |
| 2 | 11 | 11 | 11 | 33 |
| 3 | 10 | 11 | 10 | 31 |
| 4 | 11 | 10 | 11 | 32 |
| Tổng | 40 | 40.5 | 40.5 | 121 |

Thêm 8 giờ dự phòng/người, chưa tính vào Planned hours Issue hoặc Actual hours. Chênh lệch 0,5 giờ là nhỏ; không ép số giờ thực tế/SP bằng nhau. Ngưỡng lệch effort hơn 15% hoặc vượt dự toán gói đáng kể là trigger cùng nhóm xem lại task chưa bắt đầu.

## So sánh 48 gói công việc

| Mã | Người | Sprint | Dự toán trước | Dự toán R3 |
|---|---|---:|---:|---:|
| Q01 | Quân | 1 | 6 | 0.5 |
| Q02 | Quân | 1 | 10 | 1.5 |
| Q03 | Quân | 1 | 4 | 6 |
| H01 | Hải | 1 | 10 | 4 |
| H02 | Hải | 1 | 8 | 3 |
| H03 | Hải | 1 | 2 | 1.5 |
| P01 | Phúc | 1 | 6 | 2 |
| P02 | Phúc | 1 | 10 | 4.5 |
| P03 | Phúc | 1 | 4 | 2 |
| Q04 | Quân | 2 | 7 | 4 |
| Q05 | Quân | 2 | 6 | 3 |
| Q06 | Quân | 2 | 3 | 2 |
| Q07 | Quân | 2 | 4 | 2 |
| H04 | Hải | 2 | 10 | 6 |
| H05 | Hải | 2 | 4 | 2 |
| H06 | Hải | 2 | 4 | 2 |
| H07 | Hải | 2 | 2 | 1 |
| P04 | Phúc | 2 | 8 | 5 |
| P05 | Phúc | 2 | 7 | 4 |
| P06 | Phúc | 2 | 3 | 1.5 |
| P07 | Phúc | 2 | 2 | 0.5 |
| Q08 | Quân | 3 | 6 | 4 |
| Q09 | Quân | 3 | 5 | 2 |
| Q10 | Quân | 3 | 5 | 2 |
| Q11 | Quân | 3 | 4 | 2 |
| H08 | Hải | 3 | 6 | 4 |
| H09 | Hải | 3 | 4 | 2 |
| H10 | Hải | 3 | 4 | 2 |
| H11 | Hải | 3 | 6 | 3 |
| P08 | Phúc | 3 | 6 | 3 |
| P09 | Phúc | 3 | 6 | 3 |
| P10 | Phúc | 3 | 4 | 2 |
| P11 | Phúc | 3 | 4 | 2 |
| Q12 | Quân | 4 | 4 | 2 |
| Q13 | Quân | 4 | 6 | 4 |
| Q14 | Quân | 4 | 3 | 1 |
| Q15 | Quân | 4 | 4 | 3 |
| Q16 | Quân | 4 | 3 | 1 |
| H12 | Hải | 4 | 4 | 2 |
| H13 | Hải | 4 | 6 | 4 |
| H14 | Hải | 4 | 3 | 1 |
| H15 | Hải | 4 | 4 | 2 |
| H16 | Hải | 4 | 3 | 1 |
| P12 | Phúc | 4 | 4 | 2 |
| P13 | Phúc | 4 | 6 | 4 |
| P14 | Phúc | 4 | 3 | 1 |
| P15 | Phúc | 4 | 4 | 3 |
| P16 | Phúc | 4 | 3 | 1 |


## Nội dung comment cho Issue Q01 #1 đang có

Cập nhật ước lượng R3 ngày 04/11/2026: Planned hours Q01 đổi từ 6 xuống 0.5 giờ. Phạm vi Q01 là khởi tạo dự thảo Charter/scope từ kế hoạch và mẫu có sẵn, liên kết WBS và gửi đề nghị ban đầu. Phần review/phê duyệt/chữ ký và cập nhật hồ sơ tiếp tục trong Q07/Q10/Q14/H07/H11, có giờ riêng. Q02 dự kiến 1.5 giờ bootstrap, tổng Q01+Q02 là 2 giờ theo đánh giá của Quân. Actual hours sẽ ghi theo thực tế; không chỉnh hồi tố lịch sử cũ.

Thay mô tả bằng nội dung issues/Q01.md từ Mục tiêu xuống dưới; cập nhật Planned hours = 0.5 và Due date = 04/11/2026 trong Project. Giữ Issue #1, không xóa hoặc tạo lại. Với Q02 nếu đã tạo, cập nhật body/field theo file mới; nếu chưa có thì dùng file mới khi tạo.

## Những gì đã và chưa cập nhật

Đã cập nhật 48 estimate trong kế hoạch tháng, 9 file Issue Sprint 1, hai hướng dẫn GitHub và mẫu metrics. Chưa tạo file Issue cho Sprint 2–4 vì các sprint đó mới có gói trong kế hoạch; khi tạo Issue phải lấy estimate R3 trong bảng. Không tự sửa Issue/Project trên GitHub trong lần chạy này; không có kết nối GitHub ghi được sẵn có trong phiên. Gói nguồn để sao chép giữ đúng tên mã để tránh tạo trùng.
