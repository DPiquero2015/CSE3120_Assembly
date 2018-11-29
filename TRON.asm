; TRON Style Line Game
; Created by Dmitri Piquero & Eric Pereira
; CSE 3120 : Computer Architecture & Assembly
; Programming Contest

INCLUDE Irvine32.inc

rows	EQU		30
cols	EQU		80
gridS	EQU		rows * cols

.data
mRow	BYTE	?
mCol	BYTE	?
hRow	BYTE	?
hCol	BYTE	?
count	BYTE	0

grid	BYTE	gridS DUP(0)

p1Pos	COORD	<>
p2Pos	COORD	<>
p1Dir	BYTE	?	; 0 1 2 3
p2Dir	BYTE	?	; N E S W

p1Win	BYTE	"Player 1 Wins",0
p2Win	BYTE	"Player 2 Wins",0
tie		BYTE	"It's a Draw",0
retry	BYTE	"Press r to Retry",0

borT	BYTE	cols + 2 DUP("*"),0
borM	BYTE	"*"
		BYTE	cols DUP(" ")
		BYTE	"*",0

.code
main PROC
L0:
	call	Clrscr
	call	init

L1:
	call	input

	cmp p1Dir, 4		; exit
	je LExit
	cmp p2Dir, 4		; exit
	je LExit

	inc count
	cmp count, 5		; keep checking for input
	jb L1

L2:
	call	update
	call	check

	cmp EAX, 4			; retry
	je L0
	cmp EAX, 0			; exit
	jne LExit

	call	drawPs
	mov count, 0		; start checking input for next loop
	jmp L1

LExit:					; reset
	mov AL, white
	mov AH, black
	call	SetTextColor
	call	Clrscr

	exit
main ENDP

init PROC USES EAX EBX
	mov mRow, rows
	mov mCol, cols

	mov BL, 2
	
	movzx AX, mRow
	div BL
	mov hRow, AL		; half number of rows

	movzx AX, mCol
	div BL
	mov hCol, AL		; half number of columns

	dec mRow
	dec mCol

	mov AX, 10
	mov p1Pos.x, AX
	movzx AX, hRow
	mov p1Pos.y, AX		; player 1 default position
	
	mov p1Dir, 1		; player 1 default direction


	movzx AX, mCol
	sub AX, 10
	mov p2Pos.x, AX
	movzx AX, hRow
	mov p2Pos.y, AX		; player 2 default position

	mov p2Dir, 3		; player 2 default direction

	mov ECX, gridS
	mov ESI, 0
L1:
	mov grid[ESI], 0	; clear matrix
	inc ESI

	loop L1

	mov AL, white
	mov AH, black
	call	SetTextColor

	mov DL, 0
	mov DH, 0
	call	Gotoxy			; top row
	mov EDX, OFFSET borT
	call	WriteString		; draw top border

	mov ECX, rows
	mov ESI, 0
L2:
	inc ESI
	mov AX, SI
	mov DL, 0
	mov DH, AL
	call	Gotoxy			; update the row
	mov EDX, OFFSET borM
	call	WriteString		; draw side borders

	loop L2

	mov DL, 0
	mov DH, rows + 1
	call	Gotoxy			; move to last row
	mov EDX, OFFSET borT
	call	WriteString		; draw bottom border

	ret
init ENDP

input PROC USES EAX EDX
LKey:
    mov  EAX, 10
    call Delay

    call ReadKey			; is there a key to read
    jz LNKey

	; exit if escape
	.IF DX == VK_ESCAPE
		mov p1Dir, 4
		mov p2Dir, 4
		jmp LNKey
	; player 1 directional
	; AND conditions prevent going back on yourself
	.ELSEIF DX == 'W' && p1Dir != 2
		mov p1Dir, 0
	.ELSEIF DX == 'A' && p1Dir != 1
		mov p1Dir, 3
	.ELSEIF DX == 'S' && p1Dir != 0
		mov p1Dir, 2
	.ELSEIF DX == 'D' && p1Dir != 3
		mov p1Dir, 1
	; player 2 directional
	; AND conditions prevent going back on yourself
	.ELSEIF DX == VK_UP && p2Dir != 2
		mov p2Dir, 0
	.ELSEIF DX == VK_LEFT && p2Dir != 1
		mov p2Dir, 3
	.ELSEIF DX == VK_DOWN && p2Dir != 0
		mov p2Dir, 2
	.ELSEIF DX == VK_RIGHT && p2Dir != 3
		mov p2Dir, 1
	.ENDIF

LNKey:
	ret
input ENDP

update PROC USES EBX ECX EDX ESI
	.IF p1Dir == 0			; update player 1 position
		dec p1Pos.y
	.ELSEIF p1Dir == 1
		inc p1Pos.x
	.ELSEIF p1Dir == 2
		inc p1Pos.y
	.ELSEIF p1Dir == 3
		dec p1Pos.x
	.ENDIF

	.IF p2Dir == 0			; update player 2 position
		dec p2Pos.y
	.ELSEIF p2Dir == 1
		inc p2Pos.x
	.ELSEIF p2Dir == 2
		inc p2Pos.y
	.ELSEIF p2Dir == 3
		dec p2Pos.x
	.ENDIF

	movzx BX, mCol
	movzx CX, mRow

	mov EDX, 0

	; player 1 out of bounds
	.IF p1Pos.x < 0 || p1Pos.x > BX || p1Pos.y < 0 || p1Pos.y > CX
		add EDX, 1			; player 1 loses
	.ELSE
		; get the value from the matrix given player 1's coordinates
		lea ESI, grid
		movzx EAX, p1Pos.y
		mov EBX, cols
		mul EBX
		add ESI, EAX
		movzx EAX, p1Pos.x
		add ESI, EAX
		movzx EAX, BYTE PTR [ESI]

		.IF EAX > 0			; did player 1 crash
			add EDX, 1
		.ENDIF
		
		mov AL, 1
		mov [ESI], AL		; update the grid
	.ENDIF

	push EDX				; save edx for output

	movzx BX, mCol
	movzx CX, mRow

	; player 2 out of bounds
	.IF p2Pos.x < 0 || p2Pos.x > BX || p2Pos.y < 0 || p2Pos.y > CX
		pop EDX

		add EDX, 2			; player 2 loses
	.ELSE
		; get the value from the matrix given player 2's coordinates
		lea ESI, grid
		movzx EAX, p2Pos.y
		mov EBX, cols
		mul EBX
		add ESI, EAX
		movzx EAX, p2Pos.x
		add ESI, EAX
		movzx EAX, BYTE PTR [ESI]

		pop EDX

		.IF EAX > 0			; did player 2 crash
			add EDX, 2
		.ENDIF
		
		mov AL, 1
		mov [ESI],  AL		; update the grid
	.ENDIF

	; send result to output
	mov EAX, EDX

	ret
update ENDP

check PROC USES EDX
	push EAX

	mov AL, white
	mov AH, black
	call	SetTextColor

	pop EAX

	cmp EAX, 2		; player 2 loses, player 1 wins
	je LP1W
	cmp EAX, 1		; player 1 loses, player 2 wins
	je LP2W
	cmp EAX, 3		; both lose, it's a tie
	je LTie
	jmp LFin

LP1W:
	mov DL, hCol
	sub DL, 5
	mov DH, 1
	call	Gotoxy
	mov EDX, OFFSET p1Win
	call	WriteString		; print player 1 victory
	jmp LTry

LP2W:
	mov DL, hCol
	sub DL, 5
	mov DH, 1
	call	Gotoxy
	mov EDX, OFFSET p2Win
	call	WriteString		; print player 2 victory
	jmp LTry

LTie:
	mov DL, hCol
	sub DL, 6
	mov DH, 1
	call	Gotoxy
	mov EDX, OFFSET tie
	call	WriteString		; print tie
	jmp LTry

LTry:
	mov DL, hCol
	sub DL, 7
	mov DH, 2
	call Gotoxy
	mov EDX, OFFSET retry	; print retry text
	call WriteString

LKey:
	call ReadKey			; check for retry / exit
	jz LKey

	.IF DX == 'R'
		mov EAX, 4			; enable retry
	.ELSEIF DX == VK_ESCAPE
		mov EAX, 1			; enable exit
	.ELSE
		jmp LKey
	.ENDIF
	
LFin:
	ret
check ENDP


drawPs PROC USES EAX EDX
	mov AX, p1Pos.x
	inc AX					; border offset x
	mov DL, AL
	mov AX, p1Pos.y
	inc AX					; border offset y
	mov DH, AL
	call	Gotoxy
	mov AL, red				; player 1's color
	mov AH, black
	call	SetTextColor
	mov AX, '#'
	call	WriteChar		; draw at player 1 position

	mov AX, p2Pos.x
	inc AX					; border offset x
	mov DL, AL
	mov AX, p2Pos.y
	inc AX					; border offset y
	mov DH, AL
	call	Gotoxy
	mov AL, blue			; player 2's color
	mov AH, black
	call	SetTextColor
	mov AX, '#'
	call	WriteChar		; draw at player 2 position

	ret
drawPs ENDP

END main