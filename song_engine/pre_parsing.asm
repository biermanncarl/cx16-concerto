; Copyright 2025 Carl Georg Biermann

; Knowing which notes are active at a given time stamp in an event vector is a reoccuring problem.
; A fast solution for it is crucial for GUI performance.
; This file contains a highly optimized linear parser for event vectors.


.ifndef ::SONG_ENGINE_PRE_PARSING_ASM
::SONG_ENGINE_PRE_PARSING_ASM = 1

.scope pre_parsing

; .include "../../../common/x16.asm"
; .include "../../../dynamic_memory/vector_5bytes.asm"

; TODO: maybe we could put this buffer in golden RAM?
notes_active:
    .res 256

.pushseg
    .zeropage
    ; TODO: some/all of these variables could reuse v5b ZP variables
    target_timestamp:
        .word 0
    zp_pointer_1:
        .word 0
    zp_pointer_2:
        .word 0
    entry_counter:
        .byte 0
    next_ram_bank:
        .byte 0
.popseg


; Parses through an event vector in order to find out which notes are active at a given time stamp.
; Expects the pointer to the event vector in .A/.X.
; Expects the target time stamp in target_timestamp.
; At return, each byte in the notes_active array corresponds to one MIDI note. 0 means off, 1 means on.
; Returns pointer to next at time stamp in .A/.X/.Y.  If no event exists after time stamp, carry will be set; clear otherwise.
; NOTE: note-off events AT the time stamp are included in the parsing, note-on events at the time stamp are ignored.
.proc findActiveNotesAtTimestamp
    ; Clear the return array.
    ; Could use some speedcode in the future, but since it's constant time, I'll leave it for now.
    phx
    ldx #0
    @clear_loop:
        stz notes_active, x
        inx
        bne @clear_loop
    plx

    jsr v5b::is_empty
    bcc :+
    ; sec not necessary
    rts
:

    ; Initialization fast loop
    sta RAM_BANK
    stx zp_pointer_1+1
    stz zp_pointer_1
    lda #v5b::payload_offset
    sta zp_pointer_2

    ; Fast parsing through entire blocks without checking individual time stamps.

    @fast_loop:
        ; Expecting:
        ; * RAM bank is set to current block
        ; * zp_pointer_1 points to beginning of current block
        ; * zp_pointer_2 is $xx06  (pointer set up to access time stamp of first entry in a block)

        ; check first timestamp of next block
        ldx RAM_BANK ; backup
        ldy #1
        lda (zp_pointer_1), y
        sta zp_pointer_2+1 ; zp_pointer_2 is now set up to access time stamp of first event in next block
        lda (zp_pointer_1)
        beq @fast_loop_end ; no next block --> finish fast loop
        sta RAM_BANK ; access to next block established
        sta next_ram_bank ; remember for easy access
        lda target_timestamp+1
        cmp (zp_pointer_2), y
        bcs @fast_parse
        bne @fast_loop_end
        lda (zp_pointer_2)
        cmp target_timestamp
        bcs @fast_loop_end
        ; time stamp check: typical 34 cycles, worst case 46 cycles

        @fast_parse:
        stx RAM_BANK ; restore access to current block
        ldy #4
        lda (zp_pointer_1), y
        sta entry_counter
        ldy #(v5b::payload_offset + 2) ; event type of first entry
        @fast_parse_inner_loop:
            lda (zp_pointer_1), y
            beq @note_off
            cmp #events::event_type_note_on
            bne @skip_entry
            @note_on:
                iny
                lda (zp_pointer_1), y ; read pitch
                tax
                inc notes_active, x
                ; carry is set as a result of cmp instruction
                tya
                adc #(v5b::entry_size - 1 - 1)
                tay
                dec entry_counter
                bne @fast_parse_inner_loop  ; 41 cycles for a note-on
                bra @goto_next_block
            @note_off:
                iny
                lda (zp_pointer_1), y ; read pitch
                tax
                stz notes_active, x
                iny
                iny
                iny
                iny
                dec entry_counter
                bne @fast_parse_inner_loop  ; 38 cycles for a note-off
                bra @goto_next_block
            @skip_entry:
                clc
                tya
                adc #v5b::entry_size
                tay
                dec entry_counter
                bne @fast_parse_inner_loop
                ; fall through to @goto_next_block
        @goto_next_block:
        lda next_ram_bank
        sta RAM_BANK
        lda zp_pointer_2+1
        sta zp_pointer_1+1
        bra @fast_loop ; total block-related cycles: 67 cycles
        ; assuming 25 events per block on average
        ; --> 43 cycles per event parsed / 85 cycles per note
    @fast_loop_end:


    ; Final Block
    ; Expecting
    ; * RAM bank of current block in .X
    ; * zp_pointer_1 set up to current block
    stx RAM_BANK ; restore access to current block
    ldy #4
    lda (zp_pointer_1), y
    sta entry_counter
    ldy #v5b::payload_offset+1
    @final_block_loop:
        ; expects .Y sitting at the high byte of the next event's time stamp
        lda target_timestamp+1
        cmp (zp_pointer_1), y
        bcc @end_final_block
        bne @final_block_interpret_event_2
        lda target_timestamp
        dey
        cmp (zp_pointer_1), y
        bcc @end_final_block
        bne @final_block_interpret_event
        @equal_time_stamp:
            ; need to check event type to see if we use it
            iny
            iny
            lda (zp_pointer_1), y
            cmp #events::event_type_note_on
            bcs @end_final_block ; note-ons and above (effects) aren't considered anymore
            dey
            dey
            ; fall through to event interpretation
        @final_block_interpret_event:
            iny
        @final_block_interpret_event_2:
            iny
            lda (zp_pointer_1), y
            beq @final_block_note_off
            cmp #events::event_type_note_on
            bne @final_block_neither_on_off
            @final_block_note_on:
                iny
                lda (zp_pointer_1), y
                tax
                inc notes_active, x
                bra @final_block_goto_next
            @final_block_note_off:
                iny
                lda (zp_pointer_1), y
                tax
                stz notes_active, x
                bra @final_block_goto_next
            @final_block_neither_on_off:
                iny
        @final_block_goto_next:
            iny
            iny
            iny
            dec entry_counter
            bne @final_block_loop
        @reached_block_end:
            ; get pointer to last event in current block
            ldy #4
            lda (zp_pointer_1), y
            dec
            ldx zp_pointer_1+1
            ldy RAM_BANK
            jmp v5b::get_next_entry ; sets up the return values exactly as we need them: if next event exists, clear carry and pointer in .A/.X/.Y, otherwise carry set
    @end_final_block:
    ; get pointer to next event
    ldy #4
    lda (zp_pointer_1), y
    sec
    sbc entry_counter
    ldx zp_pointer_1+1
    ldy RAM_BANK
    clc
    rts
.endproc





.endscope


.endif ; .ifndef ::SONG_ENGINE_PRE_PARSING_ASM
