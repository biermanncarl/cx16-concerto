; Copyright 2024 Carl Georg Biermann

; Routines needed by the Concerto file browser.

.ifndef ::GUI_FILE_BROWSING_ASM
::GUI_FILE_BROWSING_ASM = 1

.include "../dynamic_memory/vector_32bytes.asm"
.include "../common/utility_macros.asm"
.include "../common/x16.asm"

.scope file_browsing

files:
    .word 0

.scope detail
    temp_variable_a:
        .res 1
    temp_variable_b:
        .res 2
.endscope

.scope file_type
    ID_GENERATOR 0, instrument, instrument_bank, song
.endscope

.proc initialize
    jsr v32b::new
    sta files
    stx files+1
    rts
.endproc

; Populates the files vector with files from the current directory and given file type.
; In .X, expects one of the ids in the file_type scope (instrument, bank or song)
; so the directory listing is filtered for that type (.COP, .COB and .COS extension, respectively)
.proc getFiles
    reading_file_name = detail::temp_variable_a
    character = detail::temp_variable_b

    ; replace last character of file extension to be filtered for
    lda last_letters, x
    sta extension+3

    lda files
    ldx files+1
    jsr v32b::clear

    ; set up directory listing input
    ; setnam
    lda #1
    ldx #<command
    ldy #>command
    jsr SETNAM
    ; setlfs
    lda #1 ; logical file
    ldx #8 ; device number
    ldy #0 ; 0=load, 1=save, 15=DOS command
    jsr SETLFS
    jsr OPEN
    ldx #1 ; logical file number
    jsr CHKIN

    ; read load address -- discarded
    jsr CHRIN
    jsr CHRIN

    lda files
    ldx files+1
    jsr v32b::accessFirstEntry ; there's only one entry at this point
@read_files_loop:
    ; read link (pointer to next line) -- discarded except for NULL check
    jsr CHRIN
    jsr CHRIN
    cmp #0
    beq @end_directory_read
    ; read file size -- discarded
    jsr CHRIN
    jsr CHRIN
    ; setup line read
    stz reading_file_name
    ldy #0
    @read_line_loop:
        ; TODO: detect folders and treat them separately
        phy
        jsr CHRIN
        ply
        sta character
        cmp #0 ; end of line
        beq @read_line_loop_end
        cmp #34 ; quotation mark "
        bne @no_quotation_mark
        @quotation_mark:
            inc reading_file_name
            bra @read_line_loop
        @no_quotation_mark:
            lda reading_file_name
            and #1
            beq :+
            lda character
            sta (v32b::entrypointer), y
            iny
        :   bra @read_line_loop
    @read_line_loop_end:
    ; finish up line with zero byte
    lda #0
    sta (v32b::entrypointer), y
    ; check if file name has the extension we are looking for
    ldx #3 ; length of extension minus one (4 characters including ".")
@check_extension_loop:
    dey
    bmi @delete_current_file_name
    lda (v32b::entrypointer), y
    cmp extension, x
    bne @delete_current_file_name
    dex
    bmi @keep_current_file_name
    bra @check_extension_loop
@delete_current_file_name = @read_files_loop ; no action required, we simply overwrite the file name with the next one
@keep_current_file_name:
    ; chop off the extension
    lda #0
    sta (v32b::entrypointer), y
    ; create new file name buffer
    lda files
    ldx files+1
    jsr v32b::append_new_entry
    jsr v32b::accessNextEntry
    bra @read_files_loop

@end_directory_read:
    lda #1 ; logical file
    jsr CLOSE
    jsr CLRCHN ; restore standard I/O to keyboard/screen

    ; clean up the non-files
    lda files
    ldx files+1
    jsr v32b::get_last_entry
    jsr v32b::delete_entry ; the last empty buffer added
    rts
command:
    .byte "$"
extension:
    ; concerto-x
    .byte ".cox"
last_letters:
    ; preset (instrument), bank, song
    .byte "pbs"
.endproc


; This is mainly for testing purposes
.proc printFiles
    lda files
    ldx files+1
    jsr v32b::accessFirstEntry
@file_loop:
    ldy #0
@character_loop:
    lda (v32b::entrypointer), y
    beq @next_file
    phy
    jsr CHROUT
    ply
    iny
    bra @character_loop
@next_file:
    lda #13
    jsr CHROUT
    jsr v32b::accessNextEntry
    bcc @file_loop
    rts
.endproc


.endscope

.endif ; .ifndef ::GUI_FILE_BROWSING_ASM
