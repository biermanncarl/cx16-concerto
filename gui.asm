; everything GUI related is in this file, until stuff gets too bulky for one file

.scope gui

; global GUI constants
panel_frame_color = 1
caption_color = 1
background_color = 6


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

.macro SET_VERA_XY svx, svy
   stz VERA_ctrl
   lda #$10
   sta VERA_addr_bank
   lda svy
   sta VERA_addr_high
   lda svx
   asl
   sta VERA_addr_low
.endmacro

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



; drawing variables
cur_x: .byte 0
cur_y: .byte 0
color: .byte 0
str_pointer = mzpwa

; UTILITY ROUTINES
; ----------------
; set cursor
set_cursor:
   SET_VERA_XY cur_x, cur_y
   rts

; displays the 0-terminated message at position cur_x|cur_y
; message pointer is in str_pointer
; color as in variable color
print:
   sei
   ; set VERA address
   jsr set_cursor

   ; print message
   ldx color
   ldy #0
@loop_msg:
   lda (str_pointer),y
   beq @done_msg
   sta VERA_data0
   stx VERA_data0
   iny
   bra @loop_msg
@done_msg:
   cli
   rts




; ---------------
; - PANEL STUFF -
; ---------------

.scope panels

; subroutine that draws panel
; parameters
draw_x: .byte 0
draw_y: .byte 0
draw_width: .byte 0
draw_height: .byte 0
draw_n_tabs: .byte 0  ; number of tabs
draw_active: .byte 0  ; index of active tab
;xlimit: .byte 0
;ylimit: .byte 0

draw_panel:
   ; draw frame
   ; ----------
   lda #(16*background_color + panel_frame_color)
   sta color

   ; top of frame
   lda draw_x
   sta cur_x
   lda draw_y
   sta cur_y
   sei
   jsr set_cursor
   lda #85
   sta VERA_data0
   lda color
   sta VERA_data0
   ldx draw_width
   dex
   dex
@loop_top:
   lda #64
   sta VERA_data0
   lda color
   sta VERA_data0
   dex
   bne @loop_top
   lda #73
   sta VERA_data0
   lda color
   sta VERA_data0
   cli
   ; bottom of frame
   lda cur_y
   clc
   adc draw_height
   sta cur_y
   ldx draw_width
   dex
   dex
   lda draw_n_tabs ; if 0 tabs, a simple frame is drawn
   beq :+   ; if 1 or more tabs are present, the bottom side is drawn differently
   lda cur_x
   clc
   adc #2
   sta cur_x
   dex
   dex
:  sei
   jsr set_cursor
   lda #74
   sta VERA_data0
   lda color
   sta VERA_data0
@loop_bottom:
   lda #64
   sta VERA_data0
   lda color
   sta VERA_data0
   dex
   bne @loop_bottom
   lda #75
   sta VERA_data0
   lda color
   sta VERA_data0
   cli
   ; right side of frame
   lda draw_x
   clc
   adc draw_width
   dec
   sta cur_x
   lda draw_y
   inc
   sta cur_y
   ldx draw_height
   dex
   sei
@loop_right:
   jsr set_cursor
   lda #66
   sta VERA_data0
   lda color
   sta VERA_data0
   inc cur_y
   dex
   bne @loop_right
   cli
   ; left side of frame
   lda draw_x
   ldx draw_n_tabs
   beq :+
   clc
   adc #2
:  sta cur_x
   lda draw_y
   inc
   sta cur_y
   ldx draw_height
   dex
   sei
@loop_left:
   jsr set_cursor
   lda #66
   sta VERA_data0
   lda color
   sta VERA_data0
   inc cur_y
   dex
   bne @loop_left
   cli

   ; check for tabs
   ldx draw_n_tabs
   beq :+
   jsr draw_tabs
:  rts


; draw tabs
; independent routine for updating when another tab is selected
draw_tabs:
   ldx #(16*background_color + panel_frame_color)
   stx color
   lda draw_x
   clc
   adc #2
   sta cur_x
   lda draw_y
   sta cur_y
   sei
   jsr set_cursor
   lda #114
   sta VERA_data0
   lda color
   sta VERA_data0
   ; draw tabs
   lda draw_x
   sta cur_x
   lda draw_y
   inc
   sta cur_y
   ldy #0
   ldx color
   sei
@loop_tabs:
   jsr set_cursor
   lda #66
   sta VERA_data0
   stx VERA_data0
   tya
   clc
   adc #49
   sta VERA_data0
   stx VERA_data0
   inc cur_y
   jsr set_cursor
   lda #107
   sta VERA_data0
   stx VERA_data0
   lda #64
   sta VERA_data0
   stx VERA_data0
   lda #115
   sta VERA_data0
   stx VERA_data0
   inc cur_y
   iny
   cpy draw_n_tabs
   bne @loop_tabs

   dec cur_y
   jsr set_cursor
   lda #74
   sta VERA_data0
   cli

   ; draw active tab
   lda draw_active
   dec
   asl
   clc
   adc draw_y
   sta cur_y
   lda draw_x
   sta cur_x
   ldx color
   sei
   jsr set_cursor
   lda #85
   sta VERA_data0
   stx VERA_data0
   lda #64
   sta VERA_data0
   stx VERA_data0
   lda #75
   ldy draw_active
   cpy #1
   bne :+
   lda #64
:  sta VERA_data0
   stx VERA_data0
   inc cur_y
   inc cur_y
   jsr set_cursor
   lda #74
   sta VERA_data0
   stx VERA_data0
   lda #64
   sta VERA_data0
   stx VERA_data0
   lda #73
   sta VERA_data0
   stx VERA_data0
   dec cur_y
   inc cur_x
   inc cur_x
   jsr set_cursor
   lda #32
   sta VERA_data0
   cli 

   rts



; SPECIFIC PANELS
; ---------------

.scope global
px = 15
py = 10
width = 10
height = 18
caption:
   STR_FORMAT "global"

draw:
   ; draw panel
   lda #px
   sta draw_x
   lda #py
   sta draw_y
   lda #width
   sta draw_width
   lda #height
   sta draw_height
   lda #0
   sta draw_n_tabs
   lda #0
   sta draw_active
   jsr draw_panel
   ; draw caption
   lda #px
   clc
   adc #2
   sta cur_x
   lda #py
   sta cur_y
   lda #(<caption)
   sta str_pointer
   lda #(>caption)
   sta str_pointer+1
   lda #(16*background_color+caption_color)
   sta color
   jsr print
   rts
.endscope


.scope osc
px = global::px+global::width
py = global::py
width = 33
height = 18
caption:
   STR_FORMAT "oscillators"

draw:
   ; draw panel
   lda #px
   sta draw_x
   lda #py
   sta draw_y
   lda #width
   sta draw_width
   lda #height
   sta draw_height
   lda #MAX_OSCS_PER_VOICE
   sta draw_n_tabs
   lda #3
   sta draw_active
   jsr draw_panel
   ; draw caption
   lda #px
   clc
   adc #4
   sta cur_x
   lda #py
   sta cur_y
   lda #(<caption)
   sta str_pointer
   lda #(>caption)
   sta str_pointer+1
   lda #(16*background_color+caption_color)
   sta color
   jsr print
   rts

.endscope

.scope env
px = 15
py = osc::py+osc::height+1
width = 24
height = 8
caption:
   STR_FORMAT "envelopes"

draw:
   ; draw panel
   lda #px
   sta draw_x
   lda #py
   sta draw_y
   lda #width
   sta draw_width
   lda #height
   sta draw_height
   lda #MAX_ENVS_PER_VOICE
   sta draw_n_tabs
   lda #1
   sta draw_active
   jsr draw_panel
   ; draw caption
   lda #px
   clc
   adc #4
   sta cur_x
   lda #py
   sta cur_y
   lda #(<caption)
   sta str_pointer
   lda #(>caption)
   sta str_pointer+1
   lda #(16*background_color+caption_color)
   sta color
   jsr print
   rts
.endscope




.endscope ; panels


.endscope ; gui