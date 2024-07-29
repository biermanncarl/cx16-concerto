; Copyright 2024 Carl Georg Biermann

; In this file, some globally available contiguous scratchpad memory is provided.
; To use it, the application must conform to these rules:
;
;   * The application must run in the main program (NOT interrupt)
;   * The application must be done using this scratchpad once control is handed to other parts of the program.
;   * The application must not invoke any other application which uses scratchpad before it itself is done using it.
;   * No "state" is allowed to be saved in this area. Other parts of the software will write in this memory, too.
;
; Known applications of scratchpad:
;
;   * Note drawing
;   * Song tempo changing
;

.ifndef ::COMMON_SCRATCHPAD_MEMORY_ASM
::COMMON_SCRATCHPAD_MEMORY_ASM = 1

.include "utility_macros.asm"

; region also known as "golden RAM" from $0400 to $07FF
.define SCRATCHPAD_START $0400
; we don't use the entire region (yet), maybe we'll need some space for other things, too
.define SCRATCHPAD_SIZE $0100

.macro SCRATCHPAD_VARIABLES_HELPER offset, variable_1, size_1, PARAMETER_LIST
    .if .blank(variable_1) && .blank(size_1)
        .if offset > SCRATCHPAD_START + SCRATCHPAD_SIZE
            .error "Scratchpad is too small for specified variables."
        .endif
        scratchpad_end = offset
        .exitmacro
    .endif
    .ifblank variable_1
        .error "Empty variable name encountered."
    .endif
    .ifblank size_1
        .error "Variable without size encountered."
    .endif
    variable_1 = offset
    SCRATCHPAD_VARIABLES_HELPER {offset+size_1}, PARAMETER_LIST
.endmacro

; This macro is intended to define a list of scratchpad variables.
; The parameter list is expected to consist of pairs of variable name and variable size.
.macro SCRATCHPAD_VARIABLES PARAMETER_LIST
    SCRATCHPAD_VARIABLES_HELPER SCRATCHPAD_START, PARAMETER_LIST
.endmacro

.endif ; .ifndef ::COMMON_SCRATCHPAD_MEMORY_ASM
