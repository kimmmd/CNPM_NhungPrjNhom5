# CNPM_NhungPrjNhom5
# Xúc xắc điện tử 8051

**Chức năng:** nhấn nút, LED chạy hiệu ứng đếm chậm dần, rồi dừng ở một số ngẫu nhiên từ 1 đến 6 và hiển thị trên LED 7 đoạn.

**Công cụ:**
- SimulIDE: mô phỏng mạch.
- Keil: viết ASM và build ra file `.hex`.
- Python: mô phỏng thuật toán random, vẽ biểu đồ, minh họa trực quan.

**Sản phẩm nộp:** file `.asm`, file `.hex`, file mạch SimulIDE, script Python.

---

## Cấu trúc thư mục

- `main.asm`: chương trình chính (người 1)
- `display.asm`: hiển thị, delay, hiệu ứng chờ (người 2)
- `input.asm`: random (người 3)
- `quy_uoc.inc`: khai báo chung, sửa phải báo cả nhóm
- `python/`: script mô phỏng và vẽ biểu đồ
- `simulide/`: file mạch SimulIDE

---

## 1. Thống nhất chung

### Phần cứng
- Chip: AT89C51 (8051).
- Thạch anh: 12 MHz (1 chu kỳ máy = 1 µs), phải đặt đúng 12 MHz trong SimulIDE.
- LED 7 đoạn: cathode chung (mức 1 là sáng).
- Chân LED a→g nối P1.0 → P1.6.
- Nút nhấn nối P3.2, một đầu xuống GND, có pull-up (nhấn = mức 0).

### Tài nguyên chip
- Timer0 (mode 1): chạy tự do liên tục để lấy số ngẫu nhiên.
- Timer1 (mode 1): dùng cho delay.
- TMOD: chỉ chương trình chính được ghi, chương trình con không đụng vào.
- Stack: `SP = 60H`. Sau reset SP mặc định là 07H, stack sẽ đè lên vùng thanh ghi và vùng bit, nên dời lên 60H để tránh xa vùng biến.

### Chương trình con
- `DISPLAY` (người 2): vào A = 0–6 thì hiện số, A = 7 thì hiện dấu "-"; không có đầu ra.
- `DELAY_MS` (người 2): vào R7 = số ms (1–255); sau khi gọi R7 mất giá trị.
- `WAIT_IDLE` (người 2): không có đầu vào; chạy hiệu ứng chờ, quay về khi đã nhấn nút, chống rung và nhả nút.
- `GET_RANDOM` (người 3): không có đầu vào; ra A = 1–6.
- `MAIN` (người 1): chờ → quay chậm dần → dừng ở số ngẫu nhiên → giữ khoảng 3 giây → quay lại chờ.

### Phân vùng thanh ghi và RAM
- R2, R3, R4: chỉ MAIN dùng (mặt đang hiện, delay hiện tại, kết quả random).
- R5, R6, R7: chương trình con dùng (R7 là tham số của `DELAY_MS`).
- R0, R1: dự phòng, ai dùng phải báo nhóm.
- A, B, DPTR: tự do, nhưng chương trình con nào làm hỏng thì phải ghi chú.
- RAM 30H–3FH: dành cho MAIN.
- RAM từ 40H trở đi: xin cấp riêng khi cần.

### Thuật toán random (ASM và Python phải giống nhau)
Đọc TL0 lúc nhấn nút. Nếu giá trị ≥ 252 thì đọc lại, vì 256 không chia hết cho 6 nên nếu không bỏ thì mặt 1–4 sẽ ra nhiều hơn mặt 5–6. Sau đó lấy `(TL0 mod 6) + 1`.

### Quy tắc làm việc
- Mỗi file một người sửa; riêng `quy_uoc.inc` sửa phải báo cả nhóm.
- Chỉ `main.asm` có `ORG` và `END`, và chỉ `main.asm` được build ra hex.
- Nhãn trong chương trình con phải có tiền tố riêng để khỏi trùng giữa các file: `DLY_`, `IDL_`, `BTN_`, `RND_`, `EFF_`.
- Trong `quy_uoc.inc`, chân bit khai báo bằng `BIT` (ví dụ `BTN BIT P3.2`), không dùng `EQU`. Hằng số và cổng (như `LED_PORT EQU P1`) thì dùng `EQU`.
- Khi chưa có file của bạn kia, dùng bản giả (stub) chỉ gồm nhãn rồi `RET` để build thử.

---

## 2. Danh sách công việc

### Người 1: Mạch SimulIDE
- [ ] Kiểm tra SimulIDE nạp được `.hex` của 8051 (làm ngay ngày đầu, đây là rủi ro lớn nhất).
- [ ] Dựng mạch: 8051, thạch anh, reset, LED 7 đoạn kèm điện trở 220–330Ω, nút nhấn kèm pull-up.
- [ ] Viết chương trình test phần cứng nhỏ (sáng từng đoạn LED, đọc nút) để chắc mạch đúng.

### Người 2: ASM hiển thị, delay, hiệu ứng chờ
- [ ] Làm bảng mã 7 đoạn, tra bằng `MOVC A,@A+DPTR`.
- [ ] Viết `DISPLAY`.
- [ ] Viết `DELAY_MS` (Timer1), kiểm tra đúng 1 ms trong SimulIDE.
- [ ] Viết `WAIT_IDLE`: chạy một đoạn LED vòng quanh trong lúc chờ nhấn, đồng thời kiểm tra nút, chống rung, chờ nhả nút.

### Người 3: ASM random
- [ ] Cho Timer0 chạy tự do.
- [ ] Viết `GET_RANDOM` theo thuật toán đã chốt.
- [ ] (Tùy chọn) Làm thêm phương án LFSR để so sánh.

### Người 4: ASM chương trình chính
- [ ] Viết `MAIN` theo máy trạng thái.
- [ ] Viết hiệu ứng đếm chậm dần: LED chạy 1→6 lặp lại, mỗi bước tăng delay, rồi dừng ở số ngẫu nhiên.
- [ ] Giữ kết quả khoảng 3 giây rồi quay lại hiệu ứng chờ.
- [ ] Ghép code các file, build ra `.hex`, chạy trên SimulIDE.
- [ ] (Tùy chọn) Buzzer kêu theo nhịp hiệu ứng.

### Người 5: Python
- [ ] Viết lại đúng thuật toán random của ASM (bản bỏ ≥ 252, và bản `TL0 mod 6` thô để so sánh).
- [ ] Chạy hàng chục nghìn lần, vẽ histogram phân bố 6 mặt, cho thấy độ lệch giữa các phương án.
- [ ] Vẽ LED 7 đoạn bằng `tkinter` hoặc `matplotlib` và chạy lại hiệu ứng đếm chậm dần.
- [ ] (Tùy chọn) Ghi 50–100 kết quả nhấn thật trong SimulIDE, nhập vào Python, vẽ so với lý thuyết.
- [ ] (Tùy chọn, khó) Nếu SimulIDE có UART thì cho 8051 gửi kết quả ra serial để Python đọc tự động.

### Phân công
- Người 1: Kim (main, hiệu ứng đếm, ghép code).
- Người 2: Khoa (display, delay, hiệu ứng chờ).
- Người 3: Cường (random).
- Người 4: Kim làm và nhóm check chung (mạch SimulIDE).
- Người 5: Toản (Python)
---

## 3. Hướng dẫn ghép code bằng `$INCLUDE`

`$INCLUDE` chèn nguyên nội dung file kia vào chỗ bạn viết, như copy-paste tự động. Tất cả vẫn là một chương trình duy nhất, chỉ chia nhỏ file cho dễ làm nhóm.

### Khung `main.asm`

```asm
$INCLUDE (quy_uoc.inc)
        ORG 0000H
        LJMP START
        ORG 0030H
START:  ...            ; chương trình chính
        ...
$INCLUDE (display.asm)
$INCLUDE (input.asm)
        END
```

### Quy tắc khi include
- Chỉ `main.asm` có `ORG` và `END`. File được include không có `END`, nếu không assembler sẽ dừng sớm.
- Đặt `$INCLUDE` của các file chương trình con sau code chính (sau `LJMP START`) để CPU không chạy lọt vào giữa chương trình con khi reset.
- Nhãn không được trùng giữa các file, dùng tiền tố đã quy ước.

### Trong Keil
- Tạo project, chỉ Add `main.asm`. Các file còn lại nằm cùng thư mục là Keil tự tìm thấy.
- Vào Options for Target → Output, tick **Create HEX File**.
- Nếu Add cả `display.asm` và `input.asm` vào project mà vẫn `$INCLUDE`, Keil sẽ assemble hai lần và báo lỗi trùng nhãn. Chọn một trong hai cách.
- Nếu sửa file include mà hex không đổi, dùng **Rebuild all target files**.
- Nếu Keil không tìm thấy file, kiểm tra file có cùng thư mục không, hoặc thêm đường dẫn vào Include Paths trong Options.

### Ai cần file nào
- Người viết riêng một phần chỉ cần file của mình, `quy_uoc.inc` và một `main_test.asm` tạm để gọi thử.
- Người ghép (người 1) cần đủ các file mới build được hex cuối. Hex cuối chỉ lấy từ `main.asm` thật.

### Cách chia sẻ file
- Dùng git trên repo này: mỗi người commit file của mình, người ghép `git pull`. Nếu chưa quen git thì dùng GitHub Desktop.
- Mỗi người làm trên nhánh riêng (ví dụ `nguoi2-display`), xong thì tạo Pull Request vào `main`. Cách này tránh ghi đè file của nhau.

Mình có hai gợi ý nhỏ khi up lên GitHub. Một là thay "Người 1–4" bằng tên thật của từng bạn cho dễ theo dõi. Hai là thêm mục "Cách chạy" (mở file SimulIDE, nạp hex nào) sau khi dự án xong, để thầy cô hoặc người khác chạy lại được.
