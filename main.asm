; ==============================================================================
; CHUONG TRINH CHINH - main.asm
; Tac gia : Kim (nguoi 1 & nguoi 4)
; Mo ta   : Xuc xac dien tu 8051
;           Nhan nut -> hieu ung quay -> dung o so ngau nhien 1-6 -> giu 3s
; Chip    : AT89C51, 12 MHz (1 chu ky may = 1 us)
; Quy uoc : Xem quy_uoc.inc
; Build   : Chi build file nay trong Keil (Add main.asm vao project)
;           display.asm va input.asm duoc include tu dong
; ==============================================================================

$INCLUDE (quy_uoc.inc)

; ------------------------------------------------------------------------------
; VUNG VECTOR NGAT
; ------------------------------------------------------------------------------
        ORG     0000H
        LJMP    START           ; Vector reset -> nhay thang vao START

; (Cac vector ngat khac khong dung, bo trong)

; ------------------------------------------------------------------------------
; CHUONG TRINH CHINH
; ------------------------------------------------------------------------------
        ORG     0030H

START:
        ; --- Khoi tao he thong ---
        MOV     SP,   #60H      ; Doi Stack len 60H, tranh de len vung thanh ghi va bit
        MOV     TMOD, #11H      ; Timer0 Mode1 (16-bit), Timer1 Mode1 (16-bit)
                                ; Chi MAIN duoc ghi TMOD, chuong trinh con khong duoc đung vao

        LCALL   RND_INIT_TIMER0 ; Bat Timer0 chay tu do (lay so ngau nhien)

; ------------------------------------------------------------------------------
; VONG LAP CHINH (May trang thai)
;   S0 - CHO : WAIT_IDLE chay hieu ung vien, cho nhan nut
;   S1 - QUAY: (Kim tu viet hieu ung dem cham dan o day)
;   S2 - NGAU NHIEN : GET_RANDOM lay ket qua
;   S3 - HIEN THI   : DISPLAY hien so, giu 3 giay
;   -> quay lai S0
; ------------------------------------------------------------------------------

MAIN_LOOP:

        ; === TRANG THAI S0: CHO NUT NHAN ===
        ; WAIT_IDLE chay hieu ung xoay vien LED, tu dong thoat khi nhan nut
        ; (da chong rung va cho nha nut ben trong WAIT_IDLE)
        LCALL   WAIT_IDLE

        ; === TRANG THAI S1: HIEU UNG QUAY CHAM DAN ===
        ; Kim tu viet va them vao day sau khi merge
        ; R2 = mat dang hien (1..6), R3 = delay hien tai (ms)
        ; Sau hieu ung, Accumulator A chua ket qua ngau nhien (1..6)

        ; === TRANG THAI S2: LAY SO NGAU NHIEN ===
        LCALL   GET_RANDOM      ; A = 1..6 (dung thuat toan bo mau >= 252)
        MOV     R4, A           ; Luu ket qua vao R4 (chi MAIN dung R4)

        ; === TRANG THAI S3: HIEN THI KET QUA VA GIU 3 GIAY ===
        MOV     A, R4
        LCALL   DISPLAY         ; Hien so ra LED 7 doan

        ; Giu ket qua 3000 ms (12 lan x 250 ms)
        MOV     R2, #12
MAIN_HOLD:
        MOV     R7, #250
        LCALL   DELAY_MS
        DJNZ    R2, MAIN_HOLD

        ; Quay lai vong lap, cho nhan nut lan tiep
        SJMP    MAIN_LOOP

; ------------------------------------------------------------------------------
; INCLUDE CAC MODULE CHUONG TRINH CON
; (Dat sau code chinh de CPU khong chay lot vao giua chuong trinh con khi reset)
; ------------------------------------------------------------------------------
$INCLUDE (display.asm)          ; DISPLAY, DELAY_MS, WAIT_IDLE  - tac gia: Khoa
$INCLUDE (input.asm)            ; RND_INIT_TIMER0, GET_RANDOM   - tac gia: Cuong

        END
