; everything GUI related is in this file, until stuff gets too bulky for one file

.scope gui




; actually used by DISPLAY_BYTE macro
display_100s:       .byte 0
display_10s:        .byte 0
display_1s:         .byte 0
display_address:    .word 0

; just some variables which can be used as parameters for displaying stuff
gui_register0:      .byte 0
gui_register1:      .byte 0
gui_register2:      .byte 0

; compile time macro: converts an ascii string to a zero-terminated string that can be displayed directly
.macro STR_FORMAT stf_arg
   .repeat  .strlen(stf_arg), i
   .if (.strat(stf_arg, i)=32)
      .byte 32
   .else
      .byte .strat(stf_arg, i)-64
   .endif
   .endrepeat
   .byte 0
.endmacro

; message strings



; displays the byte db_data at position db_x and db_y
.macro DISPLAY_BYTE db_data, db_x, db_y
   .local @loop100s
   .local @loop10s
   .local @loop1s

   ; convert binary into decimal
   lda db_data
   ldx #48
@loop100s:
   inx
   sec
   sbc #100
   bcs @loop100s
   adc #100
   dex
   stx display_100s

   ldx #48
@loop10s:
   inx
   sec
   sbc #10
   bcs @loop10s
   adc #10
   dex
   stx display_10s

   ldx #48
@loop1s:
   inx
   sec
   sbc #1
   bcs @loop1s
   adc #1
   dex
   stx display_1s

   sei
   ; set VERA address
   stz VERA_ctrl
   lda #$10
   sta VERA_addr_bank
   lda #db_y
   sta VERA_addr_high
   lda #db_x
   clc
   asl
   sta VERA_addr_low

   ; do output
   lda display_100s
   sta VERA_data0
   lda #$21
   sta VERA_data0
   lda display_10s
   sta VERA_data0
   lda #$21
   sta VERA_data0
   lda display_1s
   sta VERA_data0
   lda #$21    ; set color
   sta VERA_data0
   cli
.endmacro

; displays the 0-terminated message at position db_x and db_y
.macro DISPLAY_LABEL msg_start, dm_x, dm_y
.local @loop_msg
.local @done_msg
   sei
   ; set VERA address
   stz VERA_ctrl
   lda #$10
   sta VERA_addr_bank
   lda #dm_y
   sta VERA_addr_high
   lda #dm_x
   clc
   asl
   sta VERA_addr_low

   ; print message
   lda #<msg_start
   sta mzpwa
   lda #>msg_start
   sta mzpwa+1
   ldy #0
@loop_msg:
   lda (mzpwa),y
   beq @done_msg
   sta VERA_data0
   lda #$61    ; set color
   sta VERA_data0
   iny
   bra @loop_msg
@done_msg:
   cli
.endmacro


; ---------------
; - PANEL STUFF -
; ---------------

.scope panels
; locations and sizes of different panels
.scope osc
   x = 15
   y = 10
   width = 33
   height = 18
.endscope 

; subroutine that draws oscillator panel
draw_oscillator_panel:
   ; draw frame
   rts

.endscope ; panels


.endscope ; gui