********************************
*     STARFIELD-SIMULATION     *
*                              *
*      BY MARC GOLOMBECK       *
*                              *
*   VERSION 1.00 / 02.04.2018  *
********************************
*
 	DSK 	starfield3D
 	MX   	%11
        ORG 	$6000
*
Temp		EQU 	$FD
ADRHIR		EQU	$FE		; + $FF
PRNG		EQU	$06		; pseudo random number generator EOR-val
MATOR		EQU	$07
ANDMSK		EQU	$08
PSLO      	EQU 	$D8     	; USING FAC-ADRESS RANGE
PSHI      	EQU 	$DA     	; FOR POINTER IN MULT-TAB
PDLO      	EQU 	$DC     	; USING ARG-ADRESS RANGE
PDHI      	EQU 	$DE     	; FOR POINTER IN MULT-TAB
*
HCLR      	EQU 	$F3F2   	; CLEAR HIRES SCREEN TO BLACK1
WAIT		EQU	$FCA8		; wait a bit
*
INIT	
		STA 	$C010   	; delete keystrobe
		LDA 	$C050		; text
		LDA 	$C054		; page 1
		LDA 	$C052 		; mixed off
		LDA 	$C057		; hires
        	LDA 	#32
        	STA  	$E6         	; DRAW ON 1
		JSR	HCLR		; clear screen
		STZ	PRNG
		LDA 	#SSQLO/256  	; SETUP MULT-TAB
        	STA 	PSLO+1
        	LDA 	#SSQHI/256
        	STA 	PSHI+1
       	 	LDA 	#DSQLO/256
        	STA 	PDLO+1
        	LDA 	#DSQHI/256
        	STA 	PDHI+1
*
MAIN
_BP1		LDX 	#60		; number of stars
_BP		DEC 	STAR_Z,X	; decrease star z-distance
		BMI 	_reset		; reset Z-distance 
		TXA
		AND	#%00000011	; every fourth star has double the z-speed
		BNE	_noDEC1
		DEC	STAR_Z,X
		BMI	_reset
		TXA
_noDEC1		AND	#%00000111	; every eigth star has triple the z-speed
		BNE	_noDEC2
		DEC	STAR_Z,X
		BMI	_reset
		DEC	STAR_Z,X
		BMI	_reset
_noDEC2		LDA	#10		; slow down value for WAIT-routine
		JSR	WAIT		; slow down the animation, approx 660 cycles for A=10
		BRA	_action		; move a star
_cont		DEX			; 
		BPL 	_BP		; 
		BRA 	_BP1
_reset		LDA	#30
		STA	STAR_Z,X
		LDA	Temp 		; calculate new star base speed
		ADC	STAR_X,X
		ASL
		BEQ	noEOR1
		BCC	noEOR1
		INC	PRNG
		EOR	PRNG		; pseudo random number generation
noEOR1		;STA	Temp	
		BNE	noFIX1		; avoid zero value
		ADC	PRNG
noFIX1		STA	STAR_X,X	; save generated pseudo random star base speed
		ADC	STAR_Y,X
		ASL
		BEQ	noEOR2
		BCC	noEOR2
		EOR	PRNG		; pseudo random number generation
noEOR2		STA	Temp
		BNE	noFIX2
		ADC	PRNG
noFIX2		STA	STAR_Y,X	; save generated pseudo random star base speed
		JMP	_cont		
*				
_action 	PHX			; save X index
		LDY	STAR_PLOT_Y,X	; move Star y pos to Y-reg
		LDA 	YLOOKLO,Y	; 
		STA 	ADRHIR		; calc HIRES line bas address
		LDA 	YLOOKHI,Y	; 
		ORA	#$20		; draw on page 1
		STA 	ADRHIR+1	; 
		LDA	STAR_PLOT_X,X
		TAX
LOTABLE2  	LDY 	DIV7LO,X
          	LDA 	MOD7LO,X
GOTTAB2   	TAX
          	LDA 	CLRMASK,X
          	STA 	ANDMSK
          	LDA	(ADRHIR),Y
          	AND	ANDMSK
          	STA	(ADRHIR),Y
		PLX
*
		PHX			; calc XPLOT = STAR_X/STAR_Z
		LDA	STAR_X,X	; can be a signed value here
		TAY
		LDA	STAR_Z,X
		TAX
		LDA	PROJTAB,X
		STA	MATOR
		PLX
		STA	PSHI
		EOR	#$FF
		STA	PDHI
		SEC
		LDA	(PSHI),Y
		SBC	(PDHI),Y
		LDY	STAR_X,X
		BPL	starx_done
		SEC
		SBC	MATOR
starx_done	CLC
		ADC	#140		; add xoffset 140 pixel
;		BCC	addHIGH		; X-value > 255 -> plotting at right screen edge
		STA	STAR_PLOT_X,X
		STZ	STAR_PLOT_XH,X
		BRA	doY
addHIGH		STA	STAR_PLOT_X,X
		LDA	#1
		STA	STAR_PLOT_XH,X
doY		PHX			; calc XPLOT = STAR_X/STAR_Z
		LDA	STAR_Y,X	; can be a signed value here
		TAY
		LDA	STAR_Z,X
		TAX
		LDA	PROJTAB,X
		STA	MATOR
		PLX
		STA	PSHI
		EOR	#$FF
		STA	PDHI
		SEC
		LDA	(PSHI),Y
		SBC	(PDHI),Y
		LDY	STAR_Y,X
		BPL	stary_done
		SEC
		SBC	MATOR
stary_done	CLC
		ADC	#96		; add yoffset 96 pixel
		STA	STAR_PLOT_Y,X
		CMP	#192		; check for illegal line numbers!
		BCS	_doCONT
		PHX
		TAY			; move Star y-pos to Y-reg
		LDA 	YLOOKLO,Y	; 
		STA 	ADRHIR		; 
		LDA 	YLOOKHI,Y	; 
		ORA	#$20		; draw on page 1
		STA 	ADRHIR+1	; 
		LDA	STAR_PLOT_XH,X	; x-coordinate > 255?
		BEQ	doLOTABLE
		LDA	STAR_PLOT_X,X
		CMP 	#25
		BCS	_doCONT1	; if x > 279 then do not plot!
		TAX
		LDY	DIV7HI,X
		LDA	MOD7HI,X
		BRA	GOTTAB
doLOTABLE	LDA	STAR_PLOT_X,X
		TAX				
LOTABLE   	LDY 	DIV7LO,X
          	LDA 	MOD7LO,X
GOTTAB    	TAX
          	LDA 	ANDMASK,X
          	STA 	ANDMSK
          	LDA	(ADRHIR),Y
          	ORA	ANDMSK
          	STA	(ADRHIR),Y
_doCONT1	PLX			; pull X-register back from stack
*	
_doCONT		JMP	_cont			
*
* intermediate star X,Y,Z-data storage with initial values
*
STAR_Y 		DFB 	120,-20,40,-60,80,-100,120,-70,4,-45,60,-5,90,-75,110,-95,80,-17
		DFB	12,-7,8,-24,31,115,120,125,130,135,140,145,150,155
		DFB	160,165,170,175,180,185,190
		DFB	10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10
		DFB	10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10
		DFB	10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10
STAR_X 		DFB 	120,100,80,60,-40,-60,-80,-100,70,10,43,122,-23,-70,-92,-5,15,12
		DFB	39,05,-34,-21,-14,-35,08,13,19,25,11,03,20,30,37,18,04,16
		DFB	17,09,38
		DFB	10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10
		DFB	10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10
		DFB	10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10
STAR_Z		DFB 	25,30,35,60,35,50,32,17,05,47,23,59,17,31,5,52,16,38,20,41,13,39
		DFB	2,36
		DFB	10,15,20,25,30,35,40,45,40,35,30,25,20,15,10,05,10,15,20,25,30,35
		DFB	40,34,29,24,19,14,09,04,08,13,18,23,28,33,38,43,39,34,29,24,19,14,9
		DFB	4,7,12,17,22,27,32,37,42,47,46,41,36,31,26,21,16,11,6,1
STAR_PLOT_X	DFB	00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
   		DFB	00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
   		DFB	00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
   		DFB	00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
		DFB	00,00,00
STAR_PLOT_XH	DFB	00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
   		DFB	00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
   		DFB	00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
   		DFB	00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
		DFB	00,00,00
STAR_PLOT_Y	DFB	00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
   		DFB	00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
   		DFB	00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
   		DFB	00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
		DFB	00,00,00
*
* pixel masks for setting and clearing a pixel in a HIRES-byte
*
ANDMASK   	DFB 	$81,$82,$84,$88,$90,$a0,$c0
CLRMASK		DFB	$7E,$7D,$7B,$77,$6F,$5F,$3F		
*
          	DS \	; page alignment
YLOOKLO   	HEX 	0000000000000000
          	HEX 	8080808080808080
                HEX   	0000000000000000
                HEX   	8080808080808080
                HEX   	0000000000000000
                HEX  	8080808080808080
                HEX   	0000000000000000
                HEX   	8080808080808080
                HEX   	2828282828282828
                HEX   	a8a8a8a8a8a8a8a8
                HEX   	2828282828282828
                HEX   	a8a8a8a8a8a8a8a8
                HEX   	2828282828282828
                HEX   	a8a8a8a8a8a8a8a8
                HEX   	2828282828282828
                HEX   	a8a8a8a8a8a8a8a8
                HEX   	5050505050505050
                HEX   	d0d0d0d0d0d0d0d0
                HEX   	5050505050505050
                HEX   	d0d0d0d0d0d0d0d0
                HEX   	5050505050505050
                HEX   	d0d0d0d0d0d0d0d0
                HEX   	5050505050505050
                HEX   	d0d0d0d0d0d0d0d0
          	DS \
*                  
YLOOKHI   	HEX 	0004080c1014181c
                HEX   	0004080c1014181c
                HEX   	0105090d1115191d
                HEX   	0105090d1115191d
                HEX   	02060a0e12161a1e
                HEX   	02060a0e12161a1e
                HEX  	03070b0f13171b1f
                HEX   	03070b0f13171b1f
                HEX   	0004080c1014181c
                HEX   	0004080c1014181c
                HEX   	0105090d1115191d
                HEX   	0105090d1115191d
                HEX   	02060a0e12161a1e
                HEX   	02060a0e12161a1e
                HEX   	03070b0f13171b1f
                HEX   	03070b0f13171b1f
                HEX   	0004080c1014181c
                HEX   	0004080c1014181c
                HEX   	0105090d1115191d
                HEX   	0105090d1115191d
                HEX   	02060a0e12161a1e
                HEX   	02060a0e12161a1e
                HEX   	03070b0f13171b1f
                HEX   	03070b0f13171b1f
		DS \
*
* Table for 1/Z-calculus
*
PROJTAB   	HEX 	FFF0
 		HEX 	E8D5C4B6AA9F96
 		HEX 	8E8680797A6F6A
 		HEX 	66625E5B585552
 		HEX 	504D4B49474543
 		HEX 	41403E3D3B3A39
 		HEX 	37363534333231
 		HEX 	302F2E2C2927
          	HEX 	24211E1B19171614
          	HEX 	1312110F0E0D0C0B
          	HEX 	0A0A090908080707
          	HEX 	0707060606060505
          	HEX 	0505050505040404
		DS \
*
* division by 7 tables for pixel positioning
*
DIV7HI    	HEX   	2424242525252525
          	HEX   	2525262626262626
          	HEX   	2627272727272727
MOD7HI    	HEX   	0405060001020304
          	HEX   	0506000102030405
         	HEX   	0600010203040506
          	DS \
*
DIV7LO          HEX   	0000000000000001
                HEX  	0101010101010202
                HEX   	0202020202030303
                HEX   	0303030304040404
                HEX   	0404040505050505
                HEX  	0505060606060606
                HEX   	0607070707070707
                HEX   	0808080808080809
                HEX   	0909090909090a0a
                HEX   	0a0a0a0a0a0b0b0b
                HEX   	0b0b0b0b0c0c0c0c
                HEX   	0c0c0c0d0d0d0d0d
                HEX   	0d0d0e0e0e0e0e0e
                HEX   	0e0f0f0f0f0f0f0f
                HEX   	1010101010101011
                HEX   	1111111111111212
                HEX   	1212121212131313
                HEX   	1313131314141414
                HEX   	1414141515151515
                HEX   	1515161616161616
                HEX   	1617171717171717
                HEX   	1818181818181819
                HEX   	1919191919191a1a
                HEX   	1a1a1a1a1a1b1b1b
                HEX   	1b1b1b1b1c1c1c1c
                HEX   	1c1c1c1d1d1d1d1d
                HEX   	1d1d1e1e1e1e1e1e
                HEX   	1e1f1f1f1f1f1f1f
                HEX   	2020202020202021
                HEX   	2121212121212222
                HEX   	2222222222232323
                HEX   	2323232324242424
          
MOD7LO          HEX   	0001020304050600
                HEX   	0102030405060001
                HEX   	0203040506000102
                HEX   	0304050600010203
                HEX   	0405060001020304
                HEX   	0506000102030405
                HEX   	0600010203040506
                HEX   	0001020304050600
                HEX   	0102030405060001
                HEX   	0203040506000102
                HEX   	0304050600010203
                HEX   	0405060001020304
                HEX   	0506000102030405
                HEX   	0600010203040506
                HEX   	0001020304050600
                HEX   	0102030405060001
                HEX   	0203040506000102
                HEX   	0304050600010203
                HEX   	0405060001020304
                HEX   	0506000102030405
                HEX   	0600010203040506
                HEX   	0001020304050600
                HEX   	0102030405060001
                HEX   	0203040506000102
                HEX   	0304050600010203
                HEX   	0405060001020304
                HEX   	0506000102030405
                HEX   	0600010203040506
                HEX   	0001020304050600
                HEX  	0102030405060001
                HEX   	0203040506000102
                HEX   	0304050600010203
*
* multiplication tables
*
SSQLO            DFB $00,$00,$01,$02,$04,$06,$09,$0C
                 DFB $10,$14,$19,$1E,$24,$2A,$31,$38
                 DFB $40,$48,$51,$5A,$64,$6E,$79,$84
                 DFB $90,$9C,$A9,$B6,$C4,$D2,$E1,$F0
                 DFB $00,$10,$21,$32,$44,$56,$69,$7C
                 DFB $90,$A4,$B9,$CE,$E4,$FA,$11,$28
                 DFB $40,$58,$71,$8A,$A4,$BE,$D9,$F4
                 DFB $10,$2C,$49,$66,$84,$A2,$C1,$E0
                 DFB $00,$20,$41,$62,$84,$A6,$C9,$EC
                 DFB $10,$34,$59,$7E,$A4,$CA,$F1,$18
                 DFB $40,$68,$91,$BA,$E4,$0E,$39,$64
                 DFB $90,$BC,$E9,$16,$44,$72,$A1,$D0
                 DFB $00,$30,$61,$92,$C4,$F6,$29,$5C
                 DFB $90,$C4,$F9,$2E,$64,$9A,$D1,$08
                 DFB $40,$78,$B1,$EA,$24,$5E,$99,$D4
                 DFB $10,$4C,$89,$C6,$04,$42,$81,$C0
                 DFB $00,$40,$81,$C2,$04,$46,$89,$CC
                 DFB $10,$54,$99,$DE,$24,$6A,$B1,$F8
                 DFB $40,$88,$D1,$1A,$64,$AE,$F9,$44
                 DFB $90,$DC,$29,$76,$C4,$12,$61,$B0
                 DFB $00,$50,$A1,$F2,$44,$96,$E9,$3C
                 DFB $90,$E4,$39,$8E,$E4,$3A,$91,$E8
                 DFB $40,$98,$F1,$4A,$A4,$FE,$59,$B4
                 DFB $10,$6C,$C9,$26,$84,$E2,$41,$A0
                 DFB $00,$60,$C1,$22,$84,$E6,$49,$AC
                 DFB $10,$74,$D9,$3E,$A4,$0A,$71,$D8
                 DFB $40,$A8,$11,$7A,$E4,$4E,$B9,$24
                 DFB $90,$FC,$69,$D6,$44,$B2,$21,$90
                 DFB $00,$70,$E1,$52,$C4,$36,$A9,$1C
                 DFB $90,$04,$79,$EE,$64,$DA,$51,$C8
                 DFB $40,$B8,$31,$AA,$24,$9E,$19,$94
                 DFB $10,$8C,$09,$86,$04,$82,$01,$80
                 DFB $00,$80,$01,$82,$04,$86,$09,$8C
                 DFB $10,$94,$19,$9E,$24,$AA,$31,$B8
                 DFB $40,$C8,$51,$DA,$64,$EE,$79,$04
                 DFB $90,$1C,$A9,$36,$C4,$52,$E1,$70
                 DFB $00,$90,$21,$B2,$44,$D6,$69,$FC
                 DFB $90,$24,$B9,$4E,$E4,$7A,$11,$A8
                 DFB $40,$D8,$71,$0A,$A4,$3E,$D9,$74
                 DFB $10,$AC,$49,$E6,$84,$22,$C1,$60
                 DFB $00,$A0,$41,$E2,$84,$26,$C9,$6C
                 DFB $10,$B4,$59,$FE,$A4,$4A,$F1,$98
                 DFB $40,$E8,$91,$3A,$E4,$8E,$39,$E4
                 DFB $90,$3C,$E9,$96,$44,$F2,$A1,$50
                 DFB $00,$B0,$61,$12,$C4,$76,$29,$DC
                 DFB $90,$44,$F9,$AE,$64,$1A,$D1,$88
                 DFB $40,$F8,$B1,$6A,$24,$DE,$99,$54
                 DFB $10,$CC,$89,$46,$04,$C2,$81,$40
                 DFB $00,$C0,$81,$42,$04,$C6,$89,$4C
                 DFB $10,$D4,$99,$5E,$24,$EA,$B1,$78
                 DFB $40,$08,$D1,$9A,$64,$2E,$F9,$C4
                 DFB $90,$5C,$29,$F6,$C4,$92,$61,$30
                 DFB $00,$D0,$A1,$72,$44,$16,$E9,$BC
                 DFB $90,$64,$39,$0E,$E4,$BA,$91,$68
                 DFB $40,$18,$F1,$CA,$A4,$7E,$59,$34
                 DFB $10,$EC,$C9,$A6,$84,$62,$41,$20
                 DFB $00,$E0,$C1,$A2,$84,$66,$49,$2C
                 DFB $10,$F4,$D9,$BE,$A4,$8A,$71,$58
                 DFB $40,$28,$11,$FA,$E4,$CE,$B9,$A4
                 DFB $90,$7C,$69,$56,$44,$32,$21,$10
                 DFB $00,$F0,$E1,$D2,$C4,$B6,$A9,$9C
                 DFB $90,$84,$79,$6E,$64,$5A,$51,$48
                 DFB $40,$38,$31,$2A,$24,$1E,$19,$14
                 DFB $10,$0C,$09,$06,$04,$02,$01,$00
*
SSQHI            DFB $00,$00,$00,$00,$00,$00,$00,$00
                 DFB $00,$00,$00,$00,$00,$00,$00,$00
                 DFB $00,$00,$00,$00,$00,$00,$00,$00
                 DFB $00,$00,$00,$00,$00,$00,$00,$00
                 DFB $01,$01,$01,$01,$01,$01,$01,$01
                 DFB $01,$01,$01,$01,$01,$01,$02,$02
                 DFB $02,$02,$02,$02,$02,$02,$02,$02
                 DFB $03,$03,$03,$03,$03,$03,$03,$03
                 DFB $04,$04,$04,$04,$04,$04,$04,$04
                 DFB $05,$05,$05,$05,$05,$05,$05,$06
                 DFB $06,$06,$06,$06,$06,$07,$07,$07
                 DFB $07,$07,$07,$08,$08,$08,$08,$08
                 DFB $09,$09,$09,$09,$09,$09,$0A,$0A
                 DFB $0A,$0A,$0A,$0B,$0B,$0B,$0B,$0C
                 DFB $0C,$0C,$0C,$0C,$0D,$0D,$0D,$0D
                 DFB $0E,$0E,$0E,$0E,$0F,$0F,$0F,$0F
                 DFB $10,$10,$10,$10,$11,$11,$11,$11
                 DFB $12,$12,$12,$12,$13,$13,$13,$13
                 DFB $14,$14,$14,$15,$15,$15,$15,$16
                 DFB $16,$16,$17,$17,$17,$18,$18,$18
                 DFB $19,$19,$19,$19,$1A,$1A,$1A,$1B
                 DFB $1B,$1B,$1C,$1C,$1C,$1D,$1D,$1D
                 DFB $1E,$1E,$1E,$1F,$1F,$1F,$20,$20
                 DFB $21,$21,$21,$22,$22,$22,$23,$23
                 DFB $24,$24,$24,$25,$25,$25,$26,$26
                 DFB $27,$27,$27,$28,$28,$29,$29,$29
                 DFB $2A,$2A,$2B,$2B,$2B,$2C,$2C,$2D
                 DFB $2D,$2D,$2E,$2E,$2F,$2F,$30,$30
                 DFB $31,$31,$31,$32,$32,$33,$33,$34
                 DFB $34,$35,$35,$35,$36,$36,$37,$37
                 DFB $38,$38,$39,$39,$3A,$3A,$3B,$3B
                 DFB $3C,$3C,$3D,$3D,$3E,$3E,$3F,$3F
                 DFB $40,$40,$41,$41,$42,$42,$43,$43
                 DFB $44,$44,$45,$45,$46,$46,$47,$47
                 DFB $48,$48,$49,$49,$4A,$4A,$4B,$4C
                 DFB $4C,$4D,$4D,$4E,$4E,$4F,$4F,$50
                 DFB $51,$51,$52,$52,$53,$53,$54,$54
                 DFB $55,$56,$56,$57,$57,$58,$59,$59
                 DFB $5A,$5A,$5B,$5C,$5C,$5D,$5D,$5E
                 DFB $5F,$5F,$60,$60,$61,$62,$62,$63
                 DFB $64,$64,$65,$65,$66,$67,$67,$68
                 DFB $69,$69,$6A,$6A,$6B,$6C,$6C,$6D
                 DFB $6E,$6E,$6F,$70,$70,$71,$72,$72
                 DFB $73,$74,$74,$75,$76,$76,$77,$78
                 DFB $79,$79,$7A,$7B,$7B,$7C,$7D,$7D
                 DFB $7E,$7F,$7F,$80,$81,$82,$82,$83
                 DFB $84,$84,$85,$86,$87,$87,$88,$89
                 DFB $8A,$8A,$8B,$8C,$8D,$8D,$8E,$8F
                 DFB $90,$90,$91,$92,$93,$93,$94,$95
                 DFB $96,$96,$97,$98,$99,$99,$9A,$9B
                 DFB $9C,$9D,$9D,$9E,$9F,$A0,$A0,$A1
                 DFB $A2,$A3,$A4,$A4,$A5,$A6,$A7,$A8
                 DFB $A9,$A9,$AA,$AB,$AC,$AD,$AD,$AE
                 DFB $AF,$B0,$B1,$B2,$B2,$B3,$B4,$B5
                 DFB $B6,$B7,$B7,$B8,$B9,$BA,$BB,$BC
                 DFB $BD,$BD,$BE,$BF,$C0,$C1,$C2,$C3
                 DFB $C4,$C4,$C5,$C6,$C7,$C8,$C9,$CA
                 DFB $CB,$CB,$CC,$CD,$CE,$CF,$D0,$D1
                 DFB $D2,$D3,$D4,$D4,$D5,$D6,$D7,$D8
                 DFB $D9,$DA,$DB,$DC,$DD,$DE,$DF,$E0
                 DFB $E1,$E1,$E2,$E3,$E4,$E5,$E6,$E7
                 DFB $E8,$E9,$EA,$EB,$EC,$ED,$EE,$EF
                 DFB $F0,$F1,$F2,$F3,$F4,$F5,$F6,$F7
                 DFB $F8,$F9,$FA,$FB,$FC,$FD,$FE,$00
*
DSQLO            DFB $80,$01,$82,$04,$86,$09,$8C,$10
                 DFB $94,$19,$9E,$24,$AA,$31,$B8,$40
                 DFB $C8,$51,$DA,$64,$EE,$79,$04,$90
                 DFB $1C,$A9,$36,$C4,$52,$E1,$70,$00
                 DFB $90,$21,$B2,$44,$D6,$69,$FC,$90
                 DFB $24,$B9,$4E,$E4,$7A,$11,$A8,$40
                 DFB $D8,$71,$0A,$A4,$3E,$D9,$74,$10
                 DFB $AC,$49,$E6,$84,$22,$C1,$60,$00
                 DFB $A0,$41,$E2,$84,$26,$C9,$6C,$10
                 DFB $B4,$59,$FE,$A4,$4A,$F1,$98,$40
                 DFB $E8,$91,$3A,$E4,$8E,$39,$E4,$90
                 DFB $3C,$E9,$96,$44,$F2,$A1,$50,$00
                 DFB $B0,$61,$12,$C4,$76,$29,$DC,$90
                 DFB $44,$F9,$AE,$64,$1A,$D1,$88,$40
                 DFB $F8,$B1,$6A,$24,$DE,$99,$54,$10
                 DFB $CC,$89,$46,$04,$C2,$81,$40,$00
                 DFB $C0,$81,$42,$04,$C6,$89,$4C,$10
                 DFB $D4,$99,$5E,$24,$EA,$B1,$78,$40
                 DFB $08,$D1,$9A,$64,$2E,$F9,$C4,$90
                 DFB $5C,$29,$F6,$C4,$92,$61,$30,$00
                 DFB $D0,$A1,$72,$44,$16,$E9,$BC,$90
                 DFB $64,$39,$0E,$E4,$BA,$91,$68,$40
                 DFB $18,$F1,$CA,$A4,$7E,$59,$34,$10
                 DFB $EC,$C9,$A6,$84,$62,$41,$20,$00
                 DFB $E0,$C1,$A2,$84,$66,$49,$2C,$10
                 DFB $F4,$D9,$BE,$A4,$8A,$71,$58,$40
                 DFB $28,$11,$FA,$E4,$CE,$B9,$A4,$90
                 DFB $7C,$69,$56,$44,$32,$21,$10,$00
                 DFB $F0,$E1,$D2,$C4,$B6,$A9,$9C,$90
                 DFB $84,$79,$6E,$64,$5A,$51,$48,$40
                 DFB $38,$31,$2A,$24,$1E,$19,$14,$10
                 DFB $0C,$09,$06,$04,$02,$01,$00,$00
                 DFB $00,$01,$02,$04,$06,$09,$0C,$10
                 DFB $14,$19,$1E,$24,$2A,$31,$38,$40
                 DFB $48,$51,$5A,$64,$6E,$79,$84,$90
                 DFB $9C,$A9,$B6,$C4,$D2,$E1,$F0,$00
                 DFB $10,$21,$32,$44,$56,$69,$7C,$90
                 DFB $A4,$B9,$CE,$E4,$FA,$11,$28,$40
                 DFB $58,$71,$8A,$A4,$BE,$D9,$F4,$10
                 DFB $2C,$49,$66,$84,$A2,$C1,$E0,$00
                 DFB $20,$41,$62,$84,$A6,$C9,$EC,$10
                 DFB $34,$59,$7E,$A4,$CA,$F1,$18,$40
                 DFB $68,$91,$BA,$E4,$0E,$39,$64,$90
                 DFB $BC,$E9,$16,$44,$72,$A1,$D0,$00
                 DFB $30,$61,$92,$C4,$F6,$29,$5C,$90
                 DFB $C4,$F9,$2E,$64,$9A,$D1,$08,$40
                 DFB $78,$B1,$EA,$24,$5E,$99,$D4,$10
                 DFB $4C,$89,$C6,$04,$42,$81,$C0,$00
                 DFB $40,$81,$C2,$04,$46,$89,$CC,$10
                 DFB $54,$99,$DE,$24,$6A,$B1,$F8,$40
                 DFB $88,$D1,$1A,$64,$AE,$F9,$44,$90
                 DFB $DC,$29,$76,$C4,$12,$61,$B0,$00
                 DFB $50,$A1,$F2,$44,$96,$E9,$3C,$90
                 DFB $E4,$39,$8E,$E4,$3A,$91,$E8,$40
                 DFB $98,$F1,$4A,$A4,$FE,$59,$B4,$10
                 DFB $6C,$C9,$26,$84,$E2,$41,$A0,$00
                 DFB $60,$C1,$22,$84,$E6,$49,$AC,$10
                 DFB $74,$D9,$3E,$A4,$0A,$71,$D8,$40
                 DFB $A8,$11,$7A,$E4,$4E,$B9,$24,$90
                 DFB $FC,$69,$D6,$44,$B2,$21,$90,$00
                 DFB $70,$E1,$52,$C4,$36,$A9,$1C,$90
                 DFB $04,$79,$EE,$64,$DA,$51,$C8,$40
                 DFB $B8,$31,$AA,$24,$9E,$19,$94,$10
                 DFB $8C,$09,$86,$04,$82,$01,$80,$00
*
DSQHI            DFB $3F,$3F,$3E,$3E,$3D,$3D,$3C,$3C
                 DFB $3B,$3B,$3A,$3A,$39,$39,$38,$38
                 DFB $37,$37,$36,$36,$35,$35,$35,$34
                 DFB $34,$33,$33,$32,$32,$31,$31,$31
                 DFB $30,$30,$2F,$2F,$2E,$2E,$2D,$2D
                 DFB $2D,$2C,$2C,$2B,$2B,$2B,$2A,$2A
                 DFB $29,$29,$29,$28,$28,$27,$27,$27
                 DFB $26,$26,$25,$25,$25,$24,$24,$24
                 DFB $23,$23,$22,$22,$22,$21,$21,$21
                 DFB $20,$20,$1F,$1F,$1F,$1E,$1E,$1E
                 DFB $1D,$1D,$1D,$1C,$1C,$1C,$1B,$1B
                 DFB $1B,$1A,$1A,$1A,$19,$19,$19,$19
                 DFB $18,$18,$18,$17,$17,$17,$16,$16
                 DFB $16,$15,$15,$15,$15,$14,$14,$14
                 DFB $13,$13,$13,$13,$12,$12,$12,$12
                 DFB $11,$11,$11,$11,$10,$10,$10,$10
                 DFB $0F,$0F,$0F,$0F,$0E,$0E,$0E,$0E
                 DFB $0D,$0D,$0D,$0D,$0C,$0C,$0C,$0C
                 DFB $0C,$0B,$0B,$0B,$0B,$0A,$0A,$0A
                 DFB $0A,$0A,$09,$09,$09,$09,$09,$09
                 DFB $08,$08,$08,$08,$08,$07,$07,$07
                 DFB $07,$07,$07,$06,$06,$06,$06,$06
                 DFB $06,$05,$05,$05,$05,$05,$05,$05
                 DFB $04,$04,$04,$04,$04,$04,$04,$04
                 DFB $03,$03,$03,$03,$03,$03,$03,$03
                 DFB $02,$02,$02,$02,$02,$02,$02,$02
                 DFB $02,$02,$01,$01,$01,$01,$01,$01
                 DFB $01,$01,$01,$01,$01,$01,$01,$01
                 DFB $00,$00,$00,$00,$00,$00,$00,$00
                 DFB $00,$00,$00,$00,$00,$00,$00,$00
                 DFB $00,$00,$00,$00,$00,$00,$00,$00
                 DFB $00,$00,$00,$00,$00,$00,$00,$00
                 DFB $00,$00,$00,$00,$00,$00,$00,$00
                 DFB $00,$00,$00,$00,$00,$00,$00,$00
                 DFB $00,$00,$00,$00,$00,$00,$00,$00
                 DFB $00,$00,$00,$00,$00,$00,$00,$01
                 DFB $01,$01,$01,$01,$01,$01,$01,$01
                 DFB $01,$01,$01,$01,$01,$02,$02,$02
                 DFB $02,$02,$02,$02,$02,$02,$02,$03
                 DFB $03,$03,$03,$03,$03,$03,$03,$04
                 DFB $04,$04,$04,$04,$04,$04,$04,$05
                 DFB $05,$05,$05,$05,$05,$05,$06,$06
                 DFB $06,$06,$06,$06,$07,$07,$07,$07
                 DFB $07,$07,$08,$08,$08,$08,$08,$09
                 DFB $09,$09,$09,$09,$09,$0A,$0A,$0A
                 DFB $0A,$0A,$0B,$0B,$0B,$0B,$0C,$0C
                 DFB $0C,$0C,$0C,$0D,$0D,$0D,$0D,$0E
                 DFB $0E,$0E,$0E,$0F,$0F,$0F,$0F,$10
                 DFB $10,$10,$10,$11,$11,$11,$11,$12
                 DFB $12,$12,$12,$13,$13,$13,$13,$14
                 DFB $14,$14,$15,$15,$15,$15,$16,$16
                 DFB $16,$17,$17,$17,$18,$18,$18,$19
                 DFB $19,$19,$19,$1A,$1A,$1A,$1B,$1B
                 DFB $1B,$1C,$1C,$1C,$1D,$1D,$1D,$1E
                 DFB $1E,$1E,$1F,$1F,$1F,$20,$20,$21
                 DFB $21,$21,$22,$22,$22,$23,$23,$24
                 DFB $24,$24,$25,$25,$25,$26,$26,$27
                 DFB $27,$27,$28,$28,$29,$29,$29,$2A
                 DFB $2A,$2B,$2B,$2B,$2C,$2C,$2D,$2D
                 DFB $2D,$2E,$2E,$2F,$2F,$30,$30,$31
                 DFB $31,$31,$32,$32,$33,$33,$34,$34
                 DFB $35,$35,$35,$36,$36,$37,$37,$38
                 DFB $38,$39,$39,$3A,$3A,$3B,$3B,$3C
                 DFB $3C,$3D,$3D,$3E,$3E,$3F,$3F,$00
*
* end of program
*
