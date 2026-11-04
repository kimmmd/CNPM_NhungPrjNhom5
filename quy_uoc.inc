
--- Phan cung ---
; Chip AT89C51, thach anh 12 MHz (1 chu ky may = 1 us)
; LED 7 doan CATHODE CHUNG (muc 1 la sang)
; LED a..g noi P1.0..P1.6

LED_PORT  EQU  P1          ; cong noi LED 7 doan
BTN       BIT  P3.2        ; nut nhan, nhan = 0

; --- Ma dac biet cho DISPLAY ---
; A = 0..6 hien so, A = 7 hien dau "-"
DASH      EQU  7