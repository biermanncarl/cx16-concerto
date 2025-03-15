; Copyright 2023 Carl Georg Biermann

.ifndef ::COMMON_UTILITY_MACROS_ASM

::COMMON_UTILITY_MACROS_ASM = 1

; s1 is left away intentionally, as in some cases it is needed (where it is mentioned explicitly), in some cases not.
; Extend this list when needed!
.define PARAMETER_LIST s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12, s13, s14, s15, s16, s17, s18, s19, s20, s21, s22, s23, s24, s25, s26, s27, s28, s29, s30, s31, s32, s33, s34

.macro SCOPE_MEMBER_BYTE_FIELD member, s1, PARAMETER_LIST
    .ifblank s1
        ; First parameter is empty
        .exitmacro
    .endif
    .byte s1::member
    ; call this macro recursively without s1
    SCOPE_MEMBER_BYTE_FIELD member, PARAMETER_LIST
.endmacro

.macro SCOPE_MEMBER_WORD_FIELD member, s1, PARAMETER_LIST
    .ifblank s1
        ; First parameter is empty
        .exitmacro
    .endif
    .word s1::member
    ; call this macro recursively without s1
    SCOPE_MEMBER_WORD_FIELD member, PARAMETER_LIST
.endmacro

; Generates ids for a list of names. The id of the first entry can be selected,
; all subsequent ids are counting up from the first id.
; A label called "end_id" is generated which is assigned one higher than the index given to the last name.
;    index: the index given to the first name
;    p1, PARAMETER_LIST: comma-separated list of names
.macro ID_GENERATOR index, p1, PARAMETER_LIST
    .ifblank p1
        end_id = index
        ; First parameter is empty
        .exitmacro
    .endif
    p1 = index
    ; call this macro recursively without p1
    ID_GENERATOR {index+1}, PARAMETER_LIST
.endmacro

.endif ; .ifndef ::COMMON_UTILITY_MACROS_ASM

