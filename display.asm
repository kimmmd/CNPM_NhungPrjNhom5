; ==============================================================================
; THƯ VIỆN HIỂN THỊ, DELAY VÀ HIỆU ỨNG CHỜ (display.asm)
; Tác giả: Khoa
; Quy tắc: Không chứa lệnh ORG và END. Sử dụng tiền tố DSP_, DLY_, IDL_.
; Quy ước chung: Cần $INCLUDE (quy_uoc.inc) ở main.asm trước khi include file này.
; ==============================================================================

; ------------------------------------------------------------------------------
; CHƯƠNG TRÌNH CON: DISPLAY
; Chức năng : Hiển thị số (0-6) hoặc dấu "-" (7 hoặc DASH) lên LED 7 đoạn (Cathode chung)
; Đầu vào   : A = 0..6 (hiển thị số 0..6), A = 7 / DASH (hiển thị dấu "-")
; Đầu ra    : Xuất mã điều khiển ra LED_PORT (P1)
; Thanh ghi : DPTR, A (bảo toàn DPH, DPL qua Stack)
; ------------------------------------------------------------------------------
DISPLAY:
    PUSH    DPH
    PUSH    DPL
    MOV     DPTR, #DSP_TAB
    MOVC    A, @A+DPTR
    MOV     LED_PORT, A        ; Xuất mã LED ra cổng P1 (quy định trong quy_uoc.inc)
    POP     DPL
    POP     DPH
    RET

; Bảng mã LED 7 đoạn Cathode chung (Chân a->g nối P1.0->P1.6, mức 1 là sáng)
DSP_TAB:
    DB      3FH     ; 0: a, b, c, d, e, f
    DB      06H     ; 1: b, c
    DB      5BH     ; 2: a, b, d, e, g
    DB      4FH     ; 3: a, b, c, d, g
    DB      66H     ; 4: b, c, f, g
    DB      6DH     ; 5: a, c, d, f, g
    DB      7DH     ; 6: a, c, d, e, f, g
    DB      40H     ; 7 / DASH: g (Hiển thị dấu "-")

; ------------------------------------------------------------------------------
; CHƯƠNG TRÌNH CON: DELAY_MS
; Chức năng : Tạo thời gian trễ tính bằng miligiây sử dụng Timer1 (Mode 1 - 16 bit)
; Đầu vào   : R7 = số ms cần delay (1 .. 255)
; Đầu ra    : Sau khi gọi R7 bị thay đổi (giảm về 0)
; Thanh ghi : R7, Timer1 (TH1, TL1, TR1, TF1)
; Tần số    : Thạch anh 12MHz (1 chu kỳ máy = 1 µs) -> Nạp 64536 (0FC18H) cho 1ms
; ------------------------------------------------------------------------------
DELAY_MS:
DLY_LOOP:
    MOV     TH1, #0FCH          ; Nạp byte cao (65536 - 1000 = 64536 = FC18H)
    MOV     TL1, #018H          ; Nạp byte thấp
    SETB    TR1                 ; Bắt đầu chạy Timer1

DLY_WAIT:
    JNB     TF1, DLY_WAIT       ; Chờ cờ tràn TF1 báo đủ 1ms
    CLR     TR1                 ; Dừng Timer1
    CLR     TF1                 ; Xóa cờ tràn
    DJNZ    R7, DLY_LOOP        ; Giảm R7, lặp lại cho đến khi R7 = 0
    RET

; ------------------------------------------------------------------------------
; CHƯƠNG TRÌNH CON: WAIT_IDLE
; Chức năng : Chạy hiệu ứng xoay viền (a->b->c->d->e->f) trong lúc chờ nhấn nút.
;             Thực hiện quét nút nhấn, chống rung và chờ nhả nút trước khi thoát.
; Đầu vào   : Không có
; Đầu ra    : Không có
; Thanh ghi : R5 (chỉ số bước viền), R6 (đếm thời gian quét), R7, A, DPTR
; ------------------------------------------------------------------------------
WAIT_IDLE:
    MOV     R5, #0              ; Khởi tạo R5 = 0 (bắt đầu từ đoạn a)

IDL_MAIN_LOOP:
    ; 1. Lấy mã thanh viền LED và xuất ra LED_PORT
    MOV     A, R5
    MOV     DPTR, #IDL_PAT
    MOVC    A, @A+DPTR
    MOV     LED_PORT, A

    ; 2. Delay 100ms cho mỗi bước viền, đồng thời quét nút bấm liên tục
    MOV     R6, #10             ; Lặp 10 lần x 10ms = 100ms

IDL_CHECK_BTN:
    JB      BTN, IDL_NO_PRESS   ; BTN = 1 (chưa nhấn, tích cực mức 0) -> tiếp tục lặp

    ; Phát hiện BTN = 0 (nhấn nút): Tiến hành chống rung 20ms
    MOV     R7, #20
    LCALL   DELAY_MS

    JB      BTN, IDL_NO_PRESS   ; Kiểm tra lại: nếu BTN = 1 (do nhiễu) -> bỏ qua

IDL_WAIT_RELEASE:
    ; Nút bấm đã được xác nhận nhấn hợp lệ -> Chờ người dùng nhả nút (BTN = 1)
    JNB     BTN, IDL_WAIT_RELEASE

    ; Nút đã được nhả -> Thoát khỏi chương trình con WAIT_IDLE
    RET

IDL_NO_PRESS:
    MOV     R7, #10
    LCALL   DELAY_MS            ; Delay 10ms mỗi chu kỳ quét
    DJNZ    R6, IDL_CHECK_BTN   ; Giảm R6 và quét lại nút

    ; 3. Chuyển sang thanh viền tiếp theo (0 -> 1 -> ... -> 5 -> 0)
    INC     R5
    CJNE    R5, #6, IDL_MAIN_LOOP
    MOV     R5, #0
    SJMP    IDL_MAIN_LOOP

; Bảng mã 6 thanh LED ngoài viền 7 đoạn (Cathode chung)
IDL_PAT:
    DB      01H     ; Đoạn a (P1.0)
    DB      02H     ; Đoạn b (P1.1)
    DB      04H     ; Đoạn c (P1.2)
    DB      08H     ; Đoạn d (P1.3)
    DB      10H     ; Đoạn e (P1.4)
    DB      20H     ; Đoạn f (P1.5)
