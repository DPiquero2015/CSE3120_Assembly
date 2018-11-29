; Conway's Game of Life
; Created by Dmitri Piquero & Eric Pereira
; CSE 3120 : Computer Architecture & Assembly
; Programming Contest

INCLUDE Irvine32.inc

rows	EQU		28
cols	EQU		100
gridS	EQU		rows * cols
mrows	EQU		rows - 1
mcols	EQU		cols - 1

.data
grid	BYTE	gridS DUP(0)
cursor	COORD	<>
dir		BYTE	?
icount	BYTE	?
ucount	BYTE	?
iflag	BYTE	?
paused	BYTE	?
speed	BYTE	?
iter	BYTE	?

tTtle1	BYTE	"Conway's",0
tTtle2	BYTE	"Game of Life",0
tCntrl	BYTE	"Controls",0
tMove1	BYTE	"Move",0
tMove2	BYTE	"Arrow Keys",0
tTgle1	BYTE	"Toggle Cells",0
tTgle2	BYTE	"Spacebar",0
tSped1	BYTE	"Change Speed",0
tSped2	BYTE	"1, 2, 3, 4",0
tPase1	BYTE	"Pause Game",0
tPase2	BYTE	"Enter / Return",0
tRsrt1	BYTE	"Restart Game",0
tRsrt2	BYTE	"r or R",0
tLeav1	BYTE	"Quit",0
tLeav2	BYTE	"Escape",0
tPause	BYTE	"Paused",0
tPsSpc	BYTE	"      ",0
tSpeed	BYTE	"Speed: 1",0
tIters	BYTE	"Cycle: 0        ",0

borV	BYTE	cols + 2 DUP("*"),0
borH	BYTE	"*"
		BYTE	cols DUP(" ")
		BYTE	"*",0

.code
main PROC
LR:
	call	Init		; init / restart

LG:						; game loop
	mov iflag, 0		; reset input flag
	mov dir, 0			; reset player direction

LI:						; input loop
	call	Input
	cmp iflag, 1		; quit?
	je LExit
	cmp iflag, 2		; restart?
	je LR
	
	inc icount
	cmp icount, 5		; keep checking for input
	jb LI

	call	Update
	mov icount, 0
	jmp LG				; continue game

; exit
LExit:
	call	Clrscr
	exit
main ENDP

Init PROC USES EAX EBX ECX EDX ESI
	; reset position
	mov BX, 2
	
	mov DX, 0
	mov AX, cols
	div BX
	mov cursor.x, AX
	mov DX, 0
	mov AX, rows
	div BX
	mov cursor.y, AX

	; reset everything else
	mov dir, 0
	mov icount, 0
	mov ucount, 0
	mov iflag, 0
	mov paused, 1
	mov speed, 20
	mov iter, 0

	; reset the grid
	mov ECX, gridS
	mov ESI, 0
LG:
	mov grid[ESI], 0
	inc ESI

	loop LG

	call	DrawInfoBar

	; draw the border
	mov DL, 0
	mov DH, 0
	call	Gotoxy			; top row
	mov EDX, OFFSET borV
	call	WriteString		; draw top border

	mov ECX, rows
	mov ESI, 0
LB:
	inc ESI
	mov AX, SI
	mov DL, 0
	mov DH, AL
	call	Gotoxy			; update the row
	mov EDX, OFFSET borH
	call	WriteString		; draw side borders

	loop LB

	mov DL, 0
	mov DH, rows + 1
	call	Gotoxy			; move to last row
	mov EDX, OFFSET borV
	call	WriteString		; draw bottom border

	ret
Init ENDP

Input PROC uses EAX EDX
	mov EAX, 10
	call	Delay

	call	ReadKey
	jz LNK

	; quit
	.IF DX == VK_ESCAPE
		mov iflag, 1
	; restart
	.ELSEIF DX == 'R'
		mov iflag, 2
	; toggle
	.ELSEIF DX == VK_SPACE
		mov iflag, 3
	; pause
	.ELSEIF DX == VK_RETURN
		mov AL, 1
		sub AL, paused
		mov paused, AL

		mov DL, cols
		add DL, 3
		mov DH, rows
		call	Gotoxy

		.IF paused == 1
			mov EDX, OFFSET tPause
		.ELSE
			mov EDX, OFFSET tPsSpc
		.ENDIF

		call	WriteString

	; move the cursor
	.ELSEIF DX == VK_UP
		mov dir, 1
	.ELSEIF DX == VK_RIGHT
		mov dir, 2
	.ELSEIF DX == VK_DOWN
		mov dir, 3
	.ELSEIF DX == VK_LEFT
		mov dir, 4

	; speed of simulation
	.ELSEIF DX == '1'
		mov speed, 32
	.ELSEIF DX == '2'
		mov speed, 16
	.ELSEIF DX == '3'
		mov speed, 8
	.ELSEIF DX == '4'
		mov speed, 2
	.ENDIF

	.IF AL >= '1' && AL <= '4'
		mov DL, cols
		add DL, 10
		mov DH, mrows
		call	Gotoxy
		call	WriteChar
	.ENDIF

; no key pressed
LNK:
	ret
Input ENDP

Update PROC
	; placed a thing
	cmp iflag, 3
	jne LU

	; toggle cell state
	call	GridAtCursor
	mov ESI, EAX
	mov EAX, 1
	sub EAX, [ESI]
	mov [ESI], AL

LU:
	; skip if simulation paused
	cmp paused, 1
	je LC

	mov AL, speed
	inc ucount
	cmp ucount, AL
	jb LC

	call	UpdateCells
	mov ucount, 0

LC:
	; draw a cell if its at the cursor's position
	call	DrawCursorBG

	; update the cursor's position
	.IF dir == 1 && cursor.y > 0
		dec cursor.y
	.ELSEIF dir == 2 && cursor.x < mcols
		inc cursor.x
	.ELSEIF dir == 3 && cursor.y < mrows
		inc cursor.y
	.ELSEIF dir == 4 && cursor.x > 0
		dec cursor.x
	.ENDIF

	; draw the cursor
	call	GoToCursor
	mov AX, '$'
	call	WriteChar
	
	ret
Update ENDP

UpdateCells PROC USES EDX
	; CELLULAR AUTOMATA RULES
	inc iter

	mov DL, cols
	add DL, 10
	mov DH, rows
	sub DH, 2
	call	Gotoxy
	movzx EAX, iter
	call	WriteDec

	ret
UpdateCells ENDP

DrawInfoBar PROC USES EAX EDX
	mov AL, 1

	mov DL, cols
	add DL, 6
	mov DH, AL
	call	Gotoxy
	mov EDX, OFFSET tTtle1
	call	WriteString

	inc AL

	mov DL, cols
	add DL, 4
	mov DH, AL
	call	Gotoxy
	mov EDX, OFFSET tTtle2
	call	WriteString

	add AL, 3

	mov DL, cols
	add DL, 6
	mov DH, AL
	call	Gotoxy
	mov EDX, OFFSET tCntrl
	call	WriteString

	add AL, 2

	mov DL, cols
	add DL, 8
	mov DH, AL
	call	Gotoxy
	mov EDX, OFFSET tMove1
	call	WriteString

	inc AL

	mov DL, cols
	add DL, 5
	mov DH, AL
	call	Gotoxy
	mov EDX, OFFSET tMove2
	call	WriteString

	add AL, 2

	mov DL, cols
	add DL, 4
	mov DH, AL
	call	Gotoxy
	mov EDX, OFFSET tTgle1
	call	WriteString

	inc AL

	mov DL, cols
	add DL, 6
	mov DH, AL
	call	Gotoxy
	mov EDX, OFFSET tTgle2
	call	WriteString

	add AL, 2

	mov DL, cols
	add DL, 4
	mov DH, AL
	call	Gotoxy
	mov EDX, OFFSET tSped1
	call	WriteString

	inc AL

	mov DL, cols
	add DL, 5
	mov DH, AL
	call	Gotoxy
	mov EDX, OFFSET tSped2
	call	WriteString

	add AL, 2

	mov DL, cols
	add DL, 5
	mov DH, AL
	call	Gotoxy
	mov EDX, OFFSET tPase1
	call	WriteString

	inc AL

	mov DL, cols
	add DL, 3
	mov DH, AL
	call	Gotoxy
	mov EDX, OFFSET tPase2
	call	WriteString

	add AL, 2

	mov DL, cols
	add DL, 4
	mov DH, AL
	call	Gotoxy
	mov EDX, OFFSET tRsrt1
	call	WriteString

	inc AL

	mov DL, cols
	add DL, 7
	mov DH, AL
	call	Gotoxy
	mov EDX, OFFSET tRsrt2
	call	WriteString

	add AL, 2

	mov DL, cols
	add DL, 8
	mov DH, AL
	call	Gotoxy
	mov EDX, OFFSET tLeav1
	call	WriteString

	inc AL

	mov DL, cols
	add DL, 7
	mov DH, AL
	call	Gotoxy
	mov EDX, OFFSET tLeav2
	call	WriteString

	mov DL, cols
	add DL, 3
	mov DH, mrows
	call	Gotoxy
	mov EDX, OFFSET tSpeed
	call	WriteString

	mov DL, cols
	add DL, 3
	mov DH, rows
	call	Gotoxy
	mov EDX, OFFSET tPause
	call	WriteString

	mov DL, cols
	add DL, 3
	mov DH, rows
	sub DH, 2
	call	Gotoxy
	mov EDX, OFFSET tIters
	call	WriteString

	ret
DrawInfoBar ENDP

DrawCursorBG PROC USES EAX
	call	GridAtCursor
	movzx	EAX, BYTE PTR[EAX]
	call	GoToCursor

	.IF EAX > 0
		mov AX, '#'
	.ELSE
		mov AX, ' '
	.ENDIF
	call	WriteChar

	ret
DrawCursorBG ENDP

GridAtCursor PROC USES EBX ESI
	lea ESI, grid
	movzx EAX, cursor.y
	mov EBX, cols
	mul EBX
	add ESI, EAX
	movzx EAX, cursor.x
	add ESI, EAX
	mov EAX, ESI

	ret
GridAtCursor ENDP

GoToCursor PROC USES EAX EDX
	mov AX, cursor.x
	inc AX
	mov DL, AL
	mov AX, cursor.y
	inc AX
	mov DH, AL
	call	Gotoxy

	ret
GoToCursor ENDP

END main
