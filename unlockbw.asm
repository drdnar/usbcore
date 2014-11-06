UnlockFlash:
;Unlocks Flash protection.
;Destroys: pagedCount                        
;          pagedGetPtr
;          arcInfo
;          iMathPtr5
;          pagedBuf
;          ramCode

;        di
        in      a, (06)
        push    af

        ld      hl, returnPoint+$8214-$81E3
        ld      de, $8214
        ld      a, e
        ld      (arcInfo), a            ;should be 08-15
        ld      (pagedCount), a         ;just has to be over 2
        ld      bc, $8214-$8167
        lddr
        ld      (iMathPtr5), de         ;must be 8167
        ld      iy, 0056h-25h           ;permanent flags

        add     a, e
        ld      (pagedBuf), a           ;needs to be large, but under 80
        call    translatePage
        ld      hl, ($5092)
        ld      a, ($5094)
        call    translatePage
        ld      a, 16
        cpir
        jp      (hl)

returnPoint:
        ld      hl, $0018
        ld      (hl), $C3               ;dummy write
flashWait:
        ld      iy, flags
        djnz    flashWait               ;wait for write to finish
        add     hl, sp
        ld      sp, hl
        pop     af
translatePage:
        b_call(_NZIf83Plus)
        jr      z, not83
        and     $1F
not83:
        out     (06), a
        ret