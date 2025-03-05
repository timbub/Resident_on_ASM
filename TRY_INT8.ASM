.model tiny
.code
org 100h

start:

	VIDEOSEG equ 0b800h
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
	push ax bx cx es
	mov bx, offset FlagForInt
	cmp byte ptr [bx], 1d
	jne SkipDraw
	mov ax, VIDEOSEG
	mov es, ax
	mov bx, 160*5 + 80
	mov byte ptr es:[bx], 'a'
SkipDraw:
	pop es cx bx ax

	db 0eah
	oldoff08 dw 0
	oldseg08 dw 0

	iret
	endp
;--------------------------------

;--------------------------------
New09 proc
	push ax bx cx es
	;mov ax, VIDEOSEG
	;mov es, ax
	;mov bx, 160*5 + 80

	in al, 60h
	cmp al, 16d                    ; code 'Q'
	jne WrongSymbol

	;mov byte ptr es:[bx], 'a'
	mov bx, offset FlagForInt
	mov byte ptr [bx], 1d           ; flag = true

	in al, 61h
	or al, 80h
	out 61h, al
	and al, 7fh
	out 61h, al

	mov al, 20h
	out 20h, al

WrongSymbol:
	;mov FlagForInt, 0
	pop es cx bx ax

	db 0eah
	oldoff09 dw 0
	oldseg09 dw 0

	iret
	endp
;------------------------------------

MainPrintFrame proc
	mov si, offset String

	call GraphMode
	mov di, 80*27

	call ProcessingLW
	mov bx, ax
	sub di, bx
	sub bx, 2
	call ProcessingLW
	push ax
	shr ax, 1
	shl ax, 1

	mov cx, 80d
	mul cx

	sub di, ax                         ; starting position
	shr di, 1
	shl di, 1
    div cx

	pop ax
	mov dx, ax
	sub dx, 2

call DrawFrame
	ret
	endp

;--------------------------------------
;Length/Weight Processing
;Entry: SI - address of command line
;Exit:  AX - Length/Weight of frame
;Destroy: CX, AX, DX
;--------------------------------------
ProcessingLW proc
	xor ax, ax
	xor cx, cx
start_processing:
	mov cl, [si]

	cmp cl, 13                    ; cmp with Entry
	je end_processing

	cmp cl, ' '
	je end_processing

	sub cl, '0'
	mov dx, 10
	mul dx
	add ax, cx
	inc si
	jmp start_processing

end_processing:
	inc si
	ret
	endp
;--------------------------------------

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
;	 ES:DI - line beginning addr
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
	add si, 4d
call DrawString

	ret
	endp
;--------------------------------------

;--------------------------------------
;Draw String in Frame
;Entry: SI
;Exit:
;Destroy: CX, DI, SI
;--------------------------------------
DrawString proc

	call LengthString
	call GraphMode
	mov di, 2160        ; start position for string
	sub di, cx
	shr di, 1
	shl di, 1
DrStr:
	lodsb
	stosw
	mov byte ptr es:[di-1], 10011010b
	LOOP DrStr

	ret
	endp
;--------------------------------------

;--------------------------------------
;Length of string
;Entry: ES:[DI] - line beginning addr
;       AX      - ASCII code '$'
;Exit: CX - length
;Destroy:
;--------------------------------------
LengthString proc
	mov ax, ds
	mov es, ax
	mov di, si
	mov al, '$'

	xor cx, cx
	dec cx

	repne scasb
	neg cx
	sub cx, 2

	ret
	endp
;--------------------------------------

;--------------------------------------
;GraphMode
;--------------------------------------
GraphMode proc
	mov di, 0b800h
	mov es, di
	ret
	endp
;--------------------------------------

String: db '10 10 *-*I I*-* HELLO$'
FlagForInt: db 0
EOP:

end start
