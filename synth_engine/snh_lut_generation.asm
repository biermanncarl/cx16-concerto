; Copyright 2025 Carl Georg Biermann

.macro INIT_SNH_LUT lut_address
   ; Generate Sample-and-Hold lookup table
   ; We use a rudimentary 8-bit LFSR.
   ; But to decorrelate subsequent LUT entries, we advance it 8 times before we read out the value and put it in the LUT.
   ; We should wrap around a couple of times, but still get every number (except zero) exactly once.

   bra @snh_start_generate
   ; Variables
@s_n_h_register:
   .byte 0
@s_n_h_index:
   .byte 0

@snh_start_generate:
   lda #42
   sta @s_n_h_register
   stz @s_n_h_index
@snh_outer_loop:
   ldx #8
   @snh_inner_loop:
      ; Advance the LFSR
      lda @s_n_h_register
      ldy #1
      lsr ; check bit 0
      bcc :+
      iny
   :  lsr
      lsr ; check bit 2
      bcc :+
      iny
   :  lsr ; check bit 3
      bcc :+
      iny
   :  lsr ; check bit 4
      bcc :+
      iny
   :  tya
      ror   ; put least significant bit (i.e. parity) into carry flag
      lda @s_n_h_register
      ror
      sta @s_n_h_register
      ; Done advancing the LFSR

      dex
      bne @snh_inner_loop
   ldx @s_n_h_index
   sta lut_address, x
   inx
   stx @s_n_h_index
   bne @snh_outer_loop
.endmacro