.model tiny
.code
org 100h

start:

	VIDEOSEG     equ  0b800h
	COUNT_REG    equ 10d
	LENGTH_REG   equ 4d
	WEIGHT_FRAME equ 16d
	LENGHT_FRAME equ 12d
	call SaveInt08_09
	call ChangeInt08_09

	mov ax, 3100h
	mov dx, offset EOP
	shr dx, 4
	inc dx
	int 21h

;--------------------------------
ChangeInt08_09 proc

	xor ax, ax
	mov es, ax
	mov di, 09h * 4

	cli
	mov es:[di], offset New09
	push cs
	pop ax
	mov es:[di + 2], ax

	mov di, 08h * 4

	mov es:[di], offset New08
	push cs
	pop ax
	mov es:[di + 2], ax

	sti

	ret
	endp
;--------------------------------

;--------------------------------
SaveInt08_09 proc
	cli
	mov ah, 35h
 	mov al, 9
	int 21h						; get 09h in es:bx

	mov oldseg09, es
	mov oldoff09, bx

	mov ah, 35h
 	mov al, 8
	int 21h						; get 08h in es:bx

	mov oldseg08, es
	mov oldoff08, bx

	sti

	ret
	endp
;--------------------------------

;--------------------------------
New08 proc
	push ax bx cx dx es ds si

	mov bx, offset FlagForInt
	cmp byte ptr [bx], 1d
	jne SkipDraw
	call MainPrintFrame
	push ax bx cx dx es ds di si bp sp
	call PrintRegisters

SkipDraw:
	pop si ds es dx cx bx ax

	db 0eah
	oldoff08 dw 0
	oldseg08 dw 0

	iret
	endp
;--------------------------------

;--------------------------------
New09 proc
	push ax bx cx es               ; save reg

	in al, 60h
	cmp al, 16d                    ; code 'Q'
	jne WrongSymbol


	mov bx, offset FlagForInt
	mov byte ptr [bx], 1d           ; flag = true

WrongSymbol:

	in al, 61h
	or al, 80h						;
	out 61h, al
	and al, 7fh
	out 61h, al

	mov al, 20h
	out 20h, al

	;mov FlagForInt, 0
	pop es cx bx ax

	db 0eah
	oldoff09 dw 0
	oldseg09 dw 0

	iret
	endp
;------------------------------------

MainPrintFrame proc

	push cs
	pop ds
	mov si, offset Frame

	call GraphMode
	mov di, 80*27


	mov bx, WEIGHT_FRAME				;
	sub di, bx							;
	sub bx, 2							;
	mov ax, LENGHT_FRAME				;
	push ax								;
	shr ax, 1							;
	shl ax, 1							; Centering frame
										;
	mov cx, 80d							;
	mul cx								;

	sub di, ax                          ;
	shr di, 1							;
	shl di, 1							;
    div cx								;

	pop ax								;
	mov dx, ax							;
	sub dx, 2							;

call DrawFrame
	ret
	endp

;--------------------------------------
;Draw a Line of frame
;Entry: ES:DI - line beginning addr
;	   SI    - address of the  string
;Exit:
;Destroy: CX, AX
;Length = 30
;--------------------------------------
DrawLine proc
	lodsb
	stosw
	mov cx, bx
	mov byte ptr es:[di-1], 01001100b
DrawL:
	lodsb
	dec si
	stosw
	mov byte ptr es:[di-1], 01001100b

	LOOP DrawL

	inc si
	lodsb
    dec si
	stosw
	mov byte ptr es:[di-1], 01001100b

	sub si, 2d

	add bx, 2
	shl bx, 1
	sub di, bx                     ; return to start position
	shr bx, 1
	sub bx, 2
	ret
	endp
;--------------------------------------

;--------------------------------------
; Draw Frame
; Entry: SI    - address of the string
;	     ES:DI - line beginning addr
; Exit:
; Destroy: CX, AX, BX
; Width = 11
;--------------------------------------
DrawFrame proc

call DrawLine
	mov cx, dx
	add di, 160d                ; new line
	add si, 3d
DrStrs:
	push cx
	call DrawLine
	add di, 160d              ; new line
	pop cx
	LOOP DrStrs
	add si, 3d

call DrawLine

	ret
	endp
;--------------------------------------

;--------------------------------------
;PrintReg
;--------------------------------------
PrintRegisters proc
push bp							; save bp
mov bp, sp						; bp to top stack

call GraphMode
mov di, 80*17 - 4*2				; centering text

mov cx, COUNT_REG
mov dx, COUNT_REG*2 + 2
add bp, dx
mov si, offset PrintReg
DrReg:

cmp byte ptr ds:[si], "$"
je PrintValueReg
lodsb
stosw							; print "REG = ..."
mov byte ptr es:[di-1], 01001010b
jmp DrReg

PrintValueReg:
inc si

mov ax, [bp]
push cx
mov cx, LENGTH_REG

GetValueReg:
push ax
and ax, 1111b
cmp ax, 9h
ja LITERA
jmp DIGIT

LITERA:
	add ax, 41h
	sub ax, 0ah
DIGIT:
	add ax, 30h					   ; + ASCII '0'

mov es:[di], ax
mov byte ptr es:[di-1], 01001010b
pop ax
shr ax, 4
add di, 2
LOOP GetValueReg

pop cx
sub bp, 2
sub di, 10*2						; return to old position
add di, 160d					    ; new len
LOOP DrReg

pop bp
ret 2*COUNT_REG
endp

;--------------------------------------
;GraphMode
;--------------------------------------
GraphMode proc
	mov di, VIDEOSEG
	mov es, di
	ret
	endp
;--------------------------------------

Frame db '*-*I I[-]'
PrintReg db 'AX = $BX = $CX = $DX = $ES = $DS = $DI = $SI = $BP = $SP = $'
FlagForInt: db 0
EOP:
end start
