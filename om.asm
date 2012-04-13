;*****************************************************************************
;
;									A3-Copter
;					CS2610 - Assembly Language Lab project
;					Group : #16
;					1) Abhiram R
;					2) Akhilesh Godi
;					3) Anup Santosh	
;
;*****************************************************************************



.MODEL small
.STACK 100H

;-----------------------------------------------------------------------------
;								DATA SEGMENT
;-----------------------------------------------------------------------------

.DATA

	CR 			equ 13d 		;Carriage Return ASCII value
	LF			equ 10d		;Next Line ASCII Value
	VideoSeg equ 0B800H      ; video segment
	row 		dw 0
	col 		dw 0
	print_row 	dw 100
	print_col 	dw 100
	current_copter_row dw 0  
	current_copter_col dw 0
	image_width dw 29    ; actual length in the image is 30
	image_height dw 15
	image_file 	db "heli.txt", 0 ; Place the heli.txt file in the MASM FOLDER
	file_handle dw ?
	buffer 		dw ?
	msg 		db " press any key.... $"
	col_copter	dw	00h				;REUSED - Rename
	row_copter	dw	00h				;REUSED - Rename
	ncol		dw		00h
	nrow		dw		00h
	detect_collision db 0
	delay1 		dw 00h
	delay2 		dw 00h
	delay3 		dw 00h
	delay4 		dw 00h
	tempend 	dw	00h
	tempcol 	dw  00h
	linecol 	dw  00h
	testend		dw	00h
	testrow		dw	00h
	linecolor	dw	00h
	obsrow		db	00h
	obscol		dw	00h
	obstaclecol dw	00h
	linestart	dw	00h
	lineend		dw	00h
	count1		dw	00h
	count2		dw	00h
	count3		dw	00h
	topcurve 	db 320 dup(0)
	filename 	db "curve1.txt"
	randnum	 	db 00h

	AnyKey       DB     17,"press any key ..."
	NoMouse      DB     29,"mouse driver is not installed"
	CursorX      DW     5           ; text cursor X position
	CursorY      DW     5           ; text cursor Y position
	MouseX       DW     1           ; current mouse X position
	MouseY       DW     1           ; current mouse Y position
	MouseXo      DW    -1           ; last mouse X position
	MouseYo      DW    -1           ; last mouse Y position
	Buttons      DW     0           ; mouse buttons status
	FColor       DB    14           ; foreground color
	BColor       DB     1           ; background color


;-----------------------------------------------------------------------------
;								CODE SEGMENT
;-----------------------------------------------------------------------------

.CODE

;-----------------------------------------------------------------------------
;							PROCEDURES AND MACROS
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
;	DRAW A PIXEL - PARAMETERS - COLOR, ROW, COL
;-----------------------------------------------------------------------------
DrawPixel macro color, pixel_row, pixel_col
	    push 	ax
	    push 	cx
	    push 	dx
	    mov 	ax, color
	    mov 	dx, pixel_row
	    mov 	cx, pixel_col
	    mov 	ah, 0ch
	    int 	10h    
	    pop 	dx
	    pop		cx
	    pop 	ax

endm
;-----------------------------------------------------------------------------
;	SETS VIDEO MODE
;-----------------------------------------------------------------------------
SetMode	PROC
					
		mov 	al,13h
		mov 	ah,00h
		int 	10h
		ret
		
SetMode	ENDP
;-----------------------------------------------------------------------------
;	PROCEDURE TO DRAW VERTICAL LINES
; linecolor - used to pass color of the line
; linestart - used to pass starting pixel of th  eline
; lineend - used to pass end pixel of the line
; linecol - used to pass column of line
;-----------------------------------------------------------------------------
DrawVertLine PROC
		mov 	ax,linecolor
		mov 	cx,linecol
		mov 	dx,linestart
		mov 	ah,0ch
		vnext:
				int 	10h
				inc 	dx
				cmp 	dx,lineend
				jbe 	vnext
	ret
DrawVertLine ENDP
;-----------------------------------------------------------------------------
;	DRAW THE CURVE
;-----------------------------------------------------------------------------
DrawCurve PROC
				
		lea 	si,topcurve 
		mov 	linecol,00h
		mov		lineend,00h
		mov 	linecolor,1010b
		nextline:
				mov linestart,0
				mov bl,[si]
				mov bh,00h
				mov lineend,bx
				inc si
					
		call 	DrawVertLine

		mov 	linestart,bx
		add 	linestart,154
		mov 	lineend,200
		call 	drawvertline 

		inc 	linecol
		cmp 	linecol,320
		jb 		nextline

	ret
DrawCurve ENDP
;-----------------------------------------------------------------------------
;	THE DELAY PROCEDURE
;-----------------------------------------------------------------------------
Delay	PROC
		mov 	delay1,00h
		waitloop1:
				inc delay1
				mov delay2,00h
		waitloop2:		
				inc delay2
				mov delay3,00h

		waitloop3:
				inc delay3
				mov delay4,00h
		waitloop4:	
				inc delay4
				cmp delay4,5000
				jbe waitloop4
		
		cmp 	delay3,5000
		jbe 	waitloop3

		cmp 	delay2,5000
		jbe 	waitloop2

		cmp 	delay1,5000
		jbe		waitloop1

		ret
Delay	ENDP
;-----------------------------------------------------------------------------
;	PROCEDURE TO MOVE THE FRAME AND THE OBSTACLE
;	CALLS - MOVECURVE AND MOVEOBSTACLE
;-----------------------------------------------------------------------------
comment/*
MoveFrame PROC
		call drawcurve
		
		nextobstacle:
			mov 	count2,00h
			mov 	linecolor,1010b
			mov 	obstaclecol,299
			call 	randomnum
			mov 	bl,randnum
			mov 	obsrow,bl
		nextframe:
			inc		count2
			mov 	testrow,00h
			mov 	testend,30
			call 	movecurve
			mov 	testrow,169
			mov 	testend,200
			call 	movecurve
			call 	moveobstacle
			dec 	obstaclecol
	
			cmp	 	count2,320
			jbe		nextframe
			
			mov	 	count3,00h
			mov 	linecolor,0000b
			mov 	linecol,298
			mov 	linestart,31
			mov 	lineend,169
		nextl:	
			;inc 	linecol
			;call 	drawvertline
			;cmp 	count3,20
			;jbe	nextl
			
			;mov	linecolor,1010b
			jmp 	nextobstacle
MoveFrame	ENDP
/*
;-----------------------------------------------------------------------------
;	READS THE CURVE FROM THE FILE
;-----------------------------------------------------------------------------
ReadCurve	PROC
		mov 	al, 2				;al has access or sharing modes
		mov 	dx, offset filename ;DS:DX - ASCIZ file name
		mov 	ah, 3dh				;Open existing file
		int 	21h					;Do it.
		
		;Read from the file
		;mov 
		mov 	bx, ax				;Pass on the file handle returned after opening the file to bx	
		mov 	cx, 320				;Number of bytes to read
		mov 	dx, offset topcurve	;Buffer for data
		mov 	ah, 3fh				;Read from file to buffer
		int 	21h					;Do it.

		mov 	ah, 3eh				;Close the file
		int 	21h					;Do it.

		ret
ReadCurve	ENDP

;-----------------------------------------------------------------------------
; Procedure to move the top and bottom curves
; checks color of pixels in next column and moves accordingly
;-----------------------------------------------------------------------------
MoveCurve	PROC	
		mov 	col_copter,00h
		nextcol:
			mov		bx,testrow
			mov 	row_copter,bx
			cmp 	col_copter,319
			je 		lastcol

			mov		bx,col_copter
			inc		bx
			mov 	ncol,bx
			jmp 	nextrow

		lastcol:
			mov 	ncol,00h

		nextrow:
			mov		ah,0dh
			mov 	cx,col_copter
			mov 	dx,row_copter
			int		10h
		
		cmp 	al,0000b
		je 		continue_
		cmp 	al,1010b
		jne 	goout
	
	continue_:
		mov 	ah,0dh
		mov 	cx,ncol
		mov 	dx,row_copter
		int 	10h
		
		cmp al,0000b
		je continue9
		cmp	al,1010b
		jne goout
	continue9:
		mov 	bl,al
		mov 	ah,0ch
		mov 	al,bl
		mov 	cx,col_copter
		mov 	dx,row_copter
		int 	10h

		inc 	row_copter
		mov 	bx,testend
		cmp 	row_copter,bx
		jbe 	nextrow

		inc 	col_copter
		cmp 	col_copter,319
		jbe 	nextcol
	goout:
		ret
MoveCurve	ENDP

;-----------------------------------------------------------------------------
; DRAWS ONE OBSTACLE
; top left pixel passed as obsrow,obscol
;-----------------------------------------------------------------------------
DrawObstacle PROC
		mov		bh,0
		mov 	bl,obsrow
		mov 	count1,00h
		mov 	linestart,bx
		add 	bx,55
		mov 	lineend,bx
		mov 	bx,obscol
		mov 	linecol,bx
	nextline1:
		call 	DrawVertLine
		inc 	linecol
		inc 	count1
		cmp 	count1,20
		jbe 	nextline1

		ret
DrawObstacle ENDP
;-----------------------------------------------------------------------------
; MOVES THE OBSTACLE BY ONE COLUMN FORWARD
; obstaclecol variable used to pass column of the obstacle
;-----------------------------------------------------------------------------

MoveObstacle PROC
		mov 	bx,obstaclecol
		mov		obscol,bx
	;	call 	drawobstacle

	nextpos:
		dec 	obscol
		mov 	linecolor,1010b
		call 	drawobstacle
		
		mov 	ax,obscol
		add 	ax,20
		mov 	linecol,ax
		mov 	ah,0
		mov 	al,obsrow
		mov 	linestart,ax
		add 	ax,55
		mov 	lineend,ax
		mov 	linecolor,0000b
		call 	drawvertline

		mov 	linecolor,1010b
		ret
MoveObstacle ENDP
;-----------------------------------------------------------------------------
; RANDOM NUMBER GENERATOR - RESULT IN randnum
;-----------------------------------------------------------------------------
RandomNum PROC
		mov 	ah,2ch
		int 	21h
		mov 	dh,00h
		mov 	ax,dx
		mov 	dl,50
		div 	dl
		add 	ah,40

		mov 	randnum,ah

		ret
RandomNum ENDP

;*****************************************************************************
;-----------------------------------------------------------------------------
; This procedure outputs a character in AL w. color attr. in CursorX/CursorY
; starting with the screen position CursorX/CursorY 
;-----------------------------------------------------------------------------
PutChar      PROC    
         push 	di            ; save the registers
         push 	es
         push 	ax

         mov 	di, VideoSeg   ; establish the ES segment
         mov 	es, di

         xor	ax, ax         ; clear AX
         mov 	al, BYTE PTR CursorY    ; load the row number in AX
         xchg 	ah, al        ; multiply AX by 256
         shr 	ax, 1          ; AX = CursorY*128
         mov 	di, ax         ; store the result in DI
         shr 	ax, 1          ; AX = CursorY*64
         shr 	ax, 1          ; AX = CursorY*32   
         add 	di, ax         ; DI:=CursorY*(128+32)=CursorY*160
         xor 	ax, ax         ; clear AX
         mov 	al, BYTE PTR CursorX    ; load the column number in AX
         shl 	ax, 1          ; multiply the column by 2
         add 	di, ax         ; DI:=offset of the screen byte

         pop 	ax             ; restore AX
         mov 	ah, BColor
         shl 	ah, 1
         shl	ah, 1
         shl 	ah, 1
         shl 	ah, 1
         add 	ah, FColor     ; now AH contains the color attributes

         mov 	es:[di], ax    ; store char/attribute
         inc 	CursorX       

         pop 	es             ; restore the registers
         pop 	di
         ret                ; return to the calling program
PutChar ENDP               ; end of the procedure

;-----------------------------------------------------------------------------
; WRTIES A TEXT LINE POINTED BY SI ON TEH SCREEN
;-----------------------------------------------------------------------------
WriteLn PROC               ; writes a line on the screen starting with
                                ; position X/Y = CursorX/CursorY
                                ; SI points to the string 
         push 	ax
         push 	cx
         push 	si

         xor 	cx, cx
         mov 	cl, [si]       ; CL := Length(Str)
         inc 	si

	outchar:
	     mov 	al, [si]       ; AL := next character
         call 	PutChar       ; output char to the screen
         inc 	si             ; offset of the next character
         loop	outchar

	outdone:
	     pop 	si
         pop 	cx
         pop 	ax
     ret
WriteLn ENDP    
;-----------------------------------------------------------------------------
; MOUSE FUNCTIONS - InitMouse, ShowMouse, HideMouse
;-----------------------------------------------------------------------------
InitMouse  PROC
        push 	ax
        push 	si
   	    mov 	ax, 0
        int 	33h
        clc
        cmp 	ax, 0          ; AX=0 if mouse driver is not installed
        jnz 	mend
        mov 	si, offset NoMouse
   	    call 	WriteLn       ; print "mouse driver is not installed"
        mov 	si, offset AnyKey
        mov 	CursorX, 5
        mov 	CursorY, 6
        call 	WriteLn       ; print "press any key ..."
        mov 	ax, 0          ; wait for a key
        int 	16h
        stc
	mend:    pop 	si
             pop 	ax
             ret
InitMouse ENDP
	
ShowMouse    PROC
        push 	ax
        mov 	ax, 1
        int 	33h
        pop 	ax
        ret
ShowMouse    ENDP

HideMouse    PROC
        push 	ax
        mov 	ax, 2
        int 	33h
        pop 	ax
        ret
HideMouse    ENDP

;*****************************************************************************
;-----------------------------------------------------------------------------
; THE DRAWCOPTER PROCEDURE - TAKES IN THE CURRENT POSITION FROM 
;	current_copter_row and current_copter_col
;-----------------------------------------------------------------------------

DrawCopter PROC
			
		;---------------------------------------------------------------
		;	Assumes graphics mode is enabled
		;	Global definitions(must exist) : 
		;	row dw 0
		;	col dw 0
		;	print_row dw 0
		;	print_col dw 0
		;	current_copter_row dw 0
		;	current_copter_col dw 0
		;	image_width dw 29    ; actual length in the image is 30
		;	NOTE : The image width specified here must be consistent 
		;			with what you have specified in the file
		;			Here 29 => 30 numbers in the file represent one row
		;	image_file db "d:\heli.txt", 0
		;	file_handle dw ?
		;	buffer dw ?
		;---------------------------------------------------------------
		mov row, 0
		mov col, 0
		mov print_row, 0
		mov print_col, 0
		
		; Opening the file for reading - NOTE : The file must be in the appropriate folder
		mov 	al,0        
		mov 	dx,offset image_file
		mov 	ah,03dh
		int 	21h
		
		; If file is not read, jump to error
		
		jc 		erro
		mov 	file_handle,ax 
	
		; The read cycle - Basically, numbers are read from the file, and corresponding colors are drawn on the screen
			read:
				mov 	bx,file_handle    
				mov 	dx,offset buffer
				mov 	al,0
				mov 	cx,1
				mov 	ah,3Fh
				int 	21h
				
				cmp 	ax, 0
				je 		erro
				
				mov 	dx,buffer 
				cmp 	dx, '0'
				jle 	continue2
				
				;cmp 	dx, 'Z'
				;jg 		continue_3
				;sub 	dx, 48
				
				mov 	dh, 0      
				mov 	ax, current_copter_row
				mov 	print_row, ax
				mov 	ax, row
				add 	print_row, ax
				mov 	ax, current_copter_col
				mov 	print_col, ax
				mov 	ax, col
				add 	print_col, ax
				DrawPixel 	dx,print_row,print_col
						
			continue2 :
				mov 	dx, col
				cmp 	dx, image_width
				jne 	continue4
				inc		row
				mov 	ax, -1
				mov 	col, ax
				
			continue4 :
				inc 	col
				jmp 	read
	
		erro:	
			mov bx, file_handle
			mov ah, 3eh
			int 21h
			ret
DrawCopter ENDP
;-----------------------------------------------------------------------------
; CLEARS THE COPTER FROM THE SCREEN - TAKES CURRENT COORDS FROM GLOBAL DEF
;-----------------------------------------------------------------------------

ClearCopter PROC
		comment/*
		int i = currentrow
		int j = currentcol
		while( i <  copterwidth )
		{
			while ( j < copterheight )
			{
				clear pixel i,j
				j++
			}
			i++
			j = currentcol
		}/*
		push 	ax
		push 	bx
	
		inc 	image_width ; because the actual width is 1 + image_width
	
		mov 	row, 0
		mov 	col, 0
	
		mov 	ax, current_copter_row
		mov 	print_row, ax
	
		mov 	bx, current_copter_col
		mov 	print_col, bx
	
		outerLoop:
		
			innerLoop:
		
				DrawPixel 0000b, print_row, print_col
				inc 	col
				inc 	print_col
			
				mov 	ax, col
				cmp 	ax, image_width
				jle 	innerLoop
			
			inc 	row
			inc 	print_row
			
			mov 	col, 0
			mov 	print_col, bx
			
			mov 	ax, row
			cmp 	ax, image_height
			jle 	outerLoop
		
			
		dec 	image_width	; undoing change to image_width so that drawCopter can be called again without error
	
		mov 	row, 0
		mov 	col, 0
		
		pop 	bx
		pop 	ax
		ret
ClearCopter ENDP

;-----------------------------------------------------------------------------
; DETECTS COLLISION BETWEEN COPTER AND THE ENVIRONMENT
;-----------------------------------------------------------------------------
DetectCollision PROC
	
		push ax
		push bx
		push cx
		push dx
		
		
		;for row:
		;	for all the col from column to column+29:
		;	  check if the pixel colour at (row-1,col) == pixel colour ar (row,col)
		mov cx, current_copter_col	
		mov ax, current_copter_row
		mov dx,ax
		dec dx			;dx will now have row-1 and cx will have col
		mov si,cx
		add si,30
		loop1:
			cmp cx,si
			jge loop2
			;Retrieve color of the pixel at the location
			mov ah,0Dh
			int 10h			;al will now have the required pixel color
			cmp al, 1010b		
			je collided
			inc cx
			jmp loop1
		
		;for x = "column+29":
		;	for all the ro from row to row+15
		;	  check if the pixel color at ( ro ,x) == pixel color ar (ro,x+1)
		mov cx,current_copter_col
		add cx,30		;29+1 = 30
		mov dx,current_copter_row
		mov si,dx
		add si,15
		loop2:
			cmp dx,si
			jge loop3
			mov ah,0dh
			int 10h
			cmp al, 1010b
			je collided
			inc dx
			jmp loop2
		
		
		;for x = "row+14"
		;	for all the col from column to column+14:
		;	  check if the pixel colour at (x+1,col) == pixel colour ar (x,col)
		mov cx, current_copter_col	
		mov ax, current_copter_row
		mov dx,ax
		add dx,15			;dx will now have row+15 and cx will have col
		mov si,cx
		add si,30
		loop3:
			cmp cx,si
			jge done
			;Retrieve color of the pixel at the location
			mov ah,0Dh
			int 10h			;al will now have the required pixel color
			cmp al, 1010b		
			je collided
			inc cx
			jmp loop3
		
		collided: 
			mov detect_collision, 1 
        done:
        	pop dx
        	pop cx
        	pop bx
        	pop ax
			ret
DetectCollision ENDP


;-----------------------------------------------------------------------------
; PUSH ALL REGISTERS
;-----------------------------------------------------------------------------
pusha PROC
 		push ax
 		push bx
 		push cx
 		push dx
 		ret
pusha ENDP
;-----------------------------------------------------------------------------
; POP ALL REGISTERS - reverse order
;-----------------------------------------------------------------------------
popa PROC
 		pop dx
 		pop cx
 		pop bx
 		pop ax
 		ret
popa ENDP

;*****************************************************************************
; THE GAME LOOP IS HERE
;*****************************************************************************


START:
	mov ax, @data
	mov ds, ax
	mov es, ax
	
	mov current_copter_row, 100
	mov current_copter_col, 70
	
	call setMode
	call readcurve
	mov linecolor,1010b
	mov linecol,50
	mov linestart,30
	mov lineend,70
	
GAMELOOP:
	call drawcurve
		
	nextobstacle:
			mov count2,00h
		
			mov linecolor,1010b
			mov obstaclecol,299
			call randomnum
			mov bl,randnum
			mov obsrow,bl
	nextframe:
			inc count2
			mov testrow,00h
			mov testend,33
			call movecurve
			mov testrow,169
			mov testend,200
			call movecurve
			call moveobstacle
			dec obstaclecol
			
			;*******************************************
			mov ax,3
			int 33h
			cmp bx,1
			je flag1
			jmp flag2
	flag1 :	call ClearCopter;Erase the present copter first
			;call DetectCollision;Check if the pixels around the copter are gonna collide
			cmp detect_collision, 1
		   	je Text
			;If yes Kaboom! GAME OVER otherwise keep polling.
			mov dx,current_copter_row
			dec dx	;TODO : Adjust accordingly so that the speed does not become horrible 
			mov current_copter_row,dx
			call DrawCopter
			;call delay
			jmp skip
	flag2: cmp bx,2
		   jne flag3
		   jmp Text
		   
	flag3: call ClearCopter;Erase the present copter
		   ;Check if pixels around the copter are such that collision might occur
		   ;If yes Kaboom! GAME OVER otherwise keep polling.
		   call DetectCollision
		   
		   
		   cmp detect_collision, 1
		   je Text
		   mov dx, current_copter_row
		   inc dx		;Falling down : TODO - Adjust gravity accordingly.
		   mov current_copter_row,dx
		   call DrawCopter
		   ;call delay
	skip:		
			
			;*******************************************
			
			
			
			cmp count2,320
			jbe	nextframe
		
			mov count3,00h
			mov linecolor,0000b
			mov linecol,298
			mov linestart,31
			mov lineend,169
	nextl:
			jmp nextobstacle
	
	call DrawCopter

	JMP GAMELOOP

TEXT:	
	;Go back to the normal mode!
	mov al,03h
	mov ah, 0
	int 10h
	
	mov ax, 03h 
	int 10h
				
	mov ah, 1
	mov ch, 0
	mov cl, 8
	int 10h
		
	lea dx, msg
	mov ax, 09
	int 21h
				
	mov ah, 0
	int 16h


	mov cx, 4c00h
	int 21h

END START





































