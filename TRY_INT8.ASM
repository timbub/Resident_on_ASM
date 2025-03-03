.model tiny
.code
org 100h

start:


	OldSegment dw 0
	OldOffset dw 0
	VIDEOSEG equ 0b800h

	xor ax, ax
	mov es, ax
	mov di, 09h * 4

call SaveInt

	cli
	mov es:[di], offset New09
	push cs
	pop ax
	mov es:[di + 2], ax
	sti

	mov ax, 3100h
	mov dx, offset EOP
	shr dx, 4
	inc dx
	int 21h

SaveInt proc

	mov ax, word ptr es:[di]
        mov [OldOffset], ax
        mov ax, word ptr es:[di + 2]
        mov [OldSegment], ax

	ret
	endp

ReturnOldInt proc

cli
    mov ax, OldOffset
    mov word ptr es:[di], ax
    mov ax, OldSegment
    mov word ptr es:[di + 2], ax
sti
	ret
	endp

New09 proc
	push ax bx es
	mov ax, VIDEOSEG
	mov es, ax
	mov di, 5*80*2 + 40*2

	in al, 60h
	mov byte ptr es:[di], 'a'

	xor ax, ax
	mov es, ax
	mov di, 09h* 4
	call ReturnOldInt

	in al, 61h
	or al, 80h
	out 61h, al
	and al, 7fh
	out 61h, al

	mov al, 20h
	out 20h, al

	pop es bx ax

	iret
	endp
EOP:

end start
