; ==============================================================================
; MODULE HIEU UNG - effect.asm
; Tac gia : Kim
; Mo ta   : Hieu ung sau khi nhan nut:
;           1. Xoay tron chieu kim dong ho 3s (tai su dung IDL_PAT cua Khoa)
;           2. Nhap nhay toan bo LED 3 lan
;           3. Hien ket qua ngau nhien + nhap nhay ket qua 3 lan
; Quy tac : Khong co ORG va END. Tien to EFF_.
; Dau vao : A = ket qua ngau nhien (1..6)
; Dau ra  : Khong co (hien thi va nhap nhay xong roi thoat)
; Thanh ghi bi thay doi: A, R5, R6, R7
; ==============================================================================

EFF_SPIN_AND_BLINK:
        PUSH    ACC             ; Luu ket qua ngau nhien vao stack

        ; ===== BUOC 1: XOAY TRON CHIEU KIM DONG HO TRONG 3 GIAY =====
        ; Tai su dung bang IDL_PAT cua Khoa: a->b->c->d->e->f
        ; 100ms/buoc x 6 buoc = 600ms/vong x 5 vong = 3000ms
        MOV     R6, #5                  ; R6 = so vong (5 vong)

EFF_SPIN_CYCLE:
        MOV     R5, #0                  ; R5 = chi so doan (0..5)

EFF_SPIN_STEP:
        MOV     A, R5
        MOV     DPTR, #IDL_PAT          ; Bang cua Khoa (display.asm)
        MOVC    A, @A+DPTR
        MOV     LED_PORT, A

        MOV     R7, #100
        LCALL   DELAY_MS                ; Giu moi doan 100ms

        INC     R5
        CJNE    R5, #6, EFF_SPIN_STEP   ; Chua du 6 doan -> quay lai
        DJNZ    R6, EFF_SPIN_CYCLE      ; Chua du 5 vong -> quay lai

        ; ===== BUOC 2: NHAP NHAY TOAN BO LED 3 LAN =====
        MOV     R5, #3                  ; R5 = so lan nhap nhay

EFF_BLINK_ALL:
        MOV     LED_PORT, #7FH          ; Bat tat ca doan a-g
        MOV     R7, #200
        LCALL   DELAY_MS

        MOV     LED_PORT, #00H          ; Tat tat ca
        MOV     R7, #200
        LCALL   DELAY_MS

        DJNZ    R5, EFF_BLINK_ALL

        ; ===== BUOC 3: HIEN KET QUA VA NHAP NHAY KET QUA 3 LAN =====
        POP     ACC                     ; Lay lai ket qua ngau nhien
        MOV     R6, A                   ; Luu vao R6 de dung lai trong vong lap
        LCALL   DISPLAY                 ; Hien so len LED

        MOV     R5, #3                  ; R5 = so lan nhap nhay ket qua

EFF_BLINK_RESULT:
        MOV     R7, #200
        LCALL   DELAY_MS                ; Giu hien thi

        MOV     LED_PORT, #00H          ; Tat LED
        MOV     R7, #200
        LCALL   DELAY_MS

        MOV     A, R6
        LCALL   DISPLAY                 ; Hien lai so

        DJNZ    R5, EFF_BLINK_RESULT

        RET
