; Copyright 2023 Carl Georg Biermann

.ifndef ::COMMON_UTILITY_MACROS_ASM

::COMMON_UTILITY_MACROS_ASM = 1

; s1 is left away intentionally, as in some cases it is needed (where it is mentioned explicitly), in cases some not.
; Extend this list when needed.
.define SCOPE_PARAMETER_LIST s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12, s13, s14, s15, s16, s17, s18, s19, s20

.macro SCOPE_MEMBER_BYTE_FIELD member, s1, SCOPE_PARAMETER_LIST
    .ifblank s1
        ; First parameter is empty
        .exitmacro
    .endif
    .byte s1::member
    ; call this macro recursively without s1
    SCOPE_MEMBER_BYTE_FIELD member, SCOPE_PARAMETER_LIST
.endmacro

.macro SCOPE_MEMBER_WORD_FIELD member, s1, SCOPE_PARAMETER_LIST
    .ifblank s1
        ; First parameter is empty
        .exitmacro
    .endif
    .word s1::member
    ; call this macro recursively without s1
    SCOPE_MEMBER_WORD_FIELD member, SCOPE_PARAMETER_LIST
.endmacro

.endif ; .ifndef ::COMMON_UTILITY_MACROS_ASM

