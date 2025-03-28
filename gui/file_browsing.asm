; Copyright 2024-2025 Carl Georg Biermann

; Routines needed by the Concerto file browser.

.ifndef ::GUI_FILE_BROWSING_ASM
::GUI_FILE_BROWSING_ASM = 1

.include "../dynamic_memory/vector_32bytes.asm"
.include "../common/utility_macros.asm"
.include "../common/x16.asm"

.scope file_browsing

.define MAX_FILENAME_LENGTH 21

.scope file_type
    ID_GENERATOR 0, instrument, song
.endscope

files:
    .word 0
open_file_name:
    .word 0
current_file_type:
    .byte 0
current_selection_is_directory:
    .byte 0

.scope detail
    temp_variable_a:
        .res 1
    temp_variable_b:
        .res 2
    extension:
        ; concerto-x
        .byte ".cox", FILE_VERSION ; the FILE_VERSION byte is used by the file_header
    last_letters:
        ; replacement letters for "x" in .cox : preset (instrument), song
        .byte "ps"
    file_header = extension+1

    .proc updateExtension
        ; replace last character of file extension
        ldx current_file_type
        lda last_letters, x
        sta extension+3
        rts
    .endproc
.endscope

.proc initialize
    jsr v32b::new
    sta files
    stx files+1
    jsr v32b::new
    sta open_file_name
    stx open_file_name+1
    rts
.endproc


; Closes logical file #1 (which is always used here)
.proc closeFile
    lda #1 ; logical file
    jsr CLOSE
    jsr CLRCHN ; restore standard I/O to keyboard/screen
    rts
.endproc


; Opens a file for reading or writing, so that it is ready for CHRIN/CHROUT commands.
; .A/.X : pointer to a v32b entry containing a file name without extension.
; current_file_type: file type to be opened (one from the file_type scope above)
; .Y : open for reading (0) or open for writing (1)
; If a file which is opened for writing exists already, an overwrite? popup will be issued.
; Return: If file successfully opened, carry is clear. Carry is set otherwise (e.g. in the overwrite? case).
; If carry is clear, closeFile must be called before calling this function again.
.proc openFile
    file_mode = detail::temp_variable_a
    file_name = detail::temp_variable_b
    sty file_mode
    sta file_name
    stx file_name+1

    ; copy file name into open_file_name buffer
    ldy open_file_name
    phy ; save pointer to stack to later read it from stack instead of read from memory (saves 2 bytes)
    sty dll::zp_pointer
    ldy open_file_name+1
    phy
    sty dll::zp_pointer+1
    jsr dll::copyElement

    ; create file name with extension
    jsr detail::updateExtension
    plx ; recall pointer to file name
    pla
    jsr v32b::accessEntry
    ldy #255
@find_end_of_string_loop:
    iny
    lda (v32b::entrypointer), y
    bne @find_end_of_string_loop

    ldx #0
@copy_extension_loop:
    lda detail::extension, x
    sta (v32b::entrypointer), y
    iny
    inx
    cpx #4
    bne @copy_extension_loop
    lda #0
    sta (v32b::entrypointer), y
    ; string length is in .Y

    ; KERNEL CALLS
    ; setnam
    sty delete_me
    tya
    ldx v32b::entrypointer
    ldy v32b::entrypointer+1
    jsr SETNAM
    ; setlfs
    lda #1 ; logical file
    ldx #8 ; device number
    ldy file_mode ; 0=read, 1=write
    jsr SETLFS

    jsr OPEN

    ldy file_mode
    beq @open_for_read
@open_for_write:
    ; query DOS status to see if the file already exists
    ; The same query can also be done by opening another logical file on device 8 with secondary address 15 with empty file name
    ; and then reading back the bytes using CHRIN instead of ACPTR,
    ; but below method is more compact.
    lda #8 ; device number
	jsr LISTEN
	lda #15 ; secondary address
	jsr SECOND
	jsr UNLSN
    lda #8 ; device number
    jsr TALK
    ; read first two characters of status message (which contain the error code)
    ; umm, actually no, just read the first character ... (if "6" we assume the file exists, if "0" we assume it doesn't)
    jsr ACPTR
    pha ; save first character of status
@read_loop:
    jsr ACPTR ; we still need to read the entire status message, otherwise we'll get a SYNTAX ERROR next time we use the DOS
    cmp #$0D
    bne @read_loop 
    jsr UNTLK
    ; "00" = $30, $30 = OK
    ; "63" = $36, $33 = FILE EXISTS
    ; "30" = $33, $30 = SYNTAX ERROR
    ; ...
    ; We expect either OK or FILE EXISTS
    ; Interpret DOS status
    pla ; recall first character of status
    cmp #'6'
    beq @file_exists
@file_is_new:
    ldx #1 ; logical file number
    jsr CHKOUT
    ; Emit file header
    ldx #0
    @write_header_loop:
        lda detail::file_header, x
        phx
        jsr CHROUT
        plx
        inx
        cpx #4
        bne @write_header_loop
    clc
    rts

@file_exists:
    ; TODO: open "overwrite?" popup
    ; Fall through to "failed"
@failed:
    jsr closeFile
    sec
    rts

@open_for_read:
    ldx #1 ; logical file number
    jsr CHKIN
    ; check header
    ldx #0
    @check_header_loop:
        phx
        jsr CHRIN
        plx
        cmp detail::file_header, x
        bne @failed ; invalid_header
        inx
        cpx #4
        bne @check_header_loop
    clc
    rts
delete_me:
    .byte 0
.endproc


; Populates the files vector with files from the current directory and given file type.
; In current_file_type, expects one of the ids in the file_type scope (instrument, bank or song)
; so the directory listing is filtered for that type (.COP and .COS extension, respectively)
.proc getFiles
    reading_file_name = detail::temp_variable_a
    character = detail::temp_variable_b

    jsr detail::updateExtension

    php
    sei

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
    ldy #0 ; 0=load, 1=save, 2-14=generic, 15=DOS command
    jsr SETLFS
    jsr OPEN
    ldx #1 ; logical file number
    jsr CHKIN

    ; read load address -- discarded
    jsr CHRIN
    jsr CHRIN

    lda files
    ldx files+1
    jsr v32b::accessEntry ; there's only one entry at this point
@read_files_loop:
    ; The logic for reading lines is as follows:
    ; * We ignore anything before the first " symbol
    ; * Between the first and the second " we record the file name into a string
    ; * We parse the rest of the line
    ; * If end of line says "dir". We check if it's "." --> discard, otherwise keep as directory.
    ; * If not directory, we check the end of the file name for the expected extension. If conform, we keep.
    ; * Otherwise discard string.
    ; Whatever the file name is, it will be stored in the first byte: 32 for regular file, and 147 for folder (doubles as "petscii" character for folder icon)


    ; read link (pointer to next line) -- discarded except for NULL check
    jsr CHRIN
    jsr CHRIN
    cmp #0
    bne :+
        jmp @end_directory_read
    :
    ; read and discard file size (16 bit binary number)
    jsr CHRIN
    jsr CHRIN
    ; setup line read
    lda #2
    sta reading_file_name
    ldy #2
    @read_line_loop:
        phy
        jsr CHRIN
        ply
        sta character
        cmp #0 ; end of line -- some lines don't contain ""s
        beq @read_files_loop
        cmp #34 ; quotation mark "
        bne @no_quotation_mark
        @quotation_mark:
            dec reading_file_name
            beq @parse_line_end
            bra @read_line_loop
        @no_quotation_mark:
            lda reading_file_name
            cmp #1
            bne @read_line_loop
            lda character
            sta (v32b::entrypointer), y
            iny
            bra @read_line_loop
@parse_line_end:
    ; finish up line with zero byte
    lda #0
    sta (v32b::entrypointer), y
    ; Check if it's a directory
    @parse_line_end_loop_1:
        phy
        jsr CHRIN
        ply
        cmp #32   ; skip spaces
        beq @parse_line_end_loop_1
    ; We assume if the byte is "d" we have a directory.  ("dir". Files are "prg", I think. At least nothing starting with d)
    cmp #'d'
    php ; remember result
    ; read the remainder of the line
    @parse_line_end_loop_2:
        phy
        jsr CHRIN
        ply
        cmp #0 ; wait for end of line
        bne @parse_line_end_loop_2
    plp
    bne @is_file
    @is_directory:
        ; Check if it's "." --> skip
        cpy #3 ; check length with padding
        bne @keep_folder ; longer than one character --> can't be "."
        dey
        lda (v32b::entrypointer), y
        cmp #'.'
        beq @delete_current_entry
        @keep_folder:
            ; mark as folder with special byte
            ldy #0
            lda #83+64 ; 147, mark as folder & set folder icon in string
            sta (v32b::entrypointer), y
            bra @keep_entry
    @is_file:
        ; check if file name has the extension we are looking for
        ldx #3 ; length of extension minus one (4 characters including ".")
    @check_extension_loop:
        dey
        ; bmi @delete_current_entry  ; what was this for?
        lda (v32b::entrypointer), y
        cmp detail::extension, x
        bne @delete_current_entry
        dex
        bmi @keep_current_file_name
        bra @check_extension_loop
    @keep_current_file_name:
        ; chop off the extension, and mark as normal file
        lda #0
        sta (v32b::entrypointer), y ; end of string
        ldy #0
        lda #32
        sta (v32b::entrypointer), y ; mark as file
    @keep_entry:
        ; space before file/folder name
        iny
        lda #32
        sta (v32b::entrypointer), y
        ; create new file name buffer
        lda RAM_BANK
        pha
        lda files
        ldx files+1
        jsr v32b::append_new_entry
        pla
        sta RAM_BANK
        jsr v32b::accessNextEntry
        jmp @read_files_loop
    @delete_current_entry = @read_files_loop ; no action required, we simply overwrite the file name with the next one

@end_directory_read:
    jsr closeFile

    ; clean up the non-files
    lda files
    ldx files+1
    jsr v32b::get_last_entry
    jsr v32b::delete_entry ; the last empty buffer added

    plp
    rts
command:
    .byte "$"
.endproc


; Expects pointer to entry with padded file/folder name in .A/.X (pointer to v32b entry).
; Clears the padding and sets current_selection_is_directory to zero if it's a normal file, otherwise nonzero.
.proc checkIfFolderAndRemovePadding
    jsr v32b::accessEntry
    lda (v32b::entrypointer)
    sec
    sbc #32  ; will be zero only if it's a file, and therefore non-zero if it's a directory
    sta file_browsing::current_selection_is_directory
    ldy #2
    @move_loop:
        lda (v32b::entrypointer), y
        dey
        dey
        sta (v32b::entrypointer), y
        iny
        iny
        iny
        cmp #0 ; end of string?
        bne @move_loop
    rts
.endproc


; Expects pointer to entry with folder name in .A/.X (pointer to v32b entry).
; Issues the DOS command to change the folder.
.proc changeFolder
    jsr v32b::accessEntry
    ldy #0
    @copy_loop:
        lda (v32b::entrypointer), y
        sta file_name, y
        iny
        cmp #0
        bne @copy_loop
    ; setnam
    tya ; command length
    adc #1 ; takes set carry into account
    ldx #<command
    ldy #>command
    jsr SETNAM
    ; setlfs
    lda #1 ; logical file
    ldx #8 ; device number
    ldy #15 ; 0=load, 1=save, 2-14=generic, 15=DOS command
    jsr SETLFS
    jsr OPEN
    ldx #1 ; logical file number
    jsr CHKIN
    @reply_loop:
        jsr CHRIN
        cmp #$0D  ; return marks end of status message
        bne @reply_loop
    jsr closeFile
    inc concerto_gui__gui_variables__request_components_refresh_and_redraw
    rts
command:
    .byte "cd:"
file_name:
    .res MAX_FILENAME_LENGTH + 1
.endproc


; This is mainly for testing purposes
; .proc printFiles
;     lda files
;     ldx files+1
;     jsr v32b::accessEntry
; @file_loop:
;     ldy #0
; @character_loop:
;     lda (v32b::entrypointer), y
;     beq @next_file
;     phy
;     jsr CHROUT
;     ply
;     iny
;     bra @character_loop
; @next_file:
;     lda #13
;     jsr CHROUT
;     jsr v32b::accessNextEntry
;     bcc @file_loop
;     rts
; .endproc


.endscope

.endif ; .ifndef ::GUI_FILE_BROWSING_ASM
