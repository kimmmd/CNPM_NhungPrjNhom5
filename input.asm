RND_INIT_TIMER0:
        CLR     TR0             ; dung de nap gia tri ban dau
        MOV     TH0,#00H
        MOV     TL0,#00H
        CLR     TF0
        SETB    TR0             ; Timer0 bat dau dem lien tuc
        RET

GET_RANDOM:
RND_READ:
        MOV     A,TL0           ; lay mau bo dem 8 bit
        MOV     R5,A            ; giu mau goc de chia
        CLR     C
        SUBB    A,#0FCH         ; so sanh mau voi 252
        JNC     RND_READ        ; mau >= 252: doc lai

        MOV     A,R5            ; khoi phuc mau 0..251
        MOV     B,#06H
        DIV     AB              ; B = mau mod 6
        MOV     A,B
        INC     A               ; 0..5 -> 1..6
        RET
