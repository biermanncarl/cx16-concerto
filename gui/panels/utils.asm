; Copyright 2023 Carl Georg Biermann

.ifndef ::GUI_PANELS_UTILS_ASM

::GUI_PANELS_UTILS_ASM = 1

; Helpers to define components inside a "component string"

.feature addrsize
.macro COMPONENT_PARAMETERS p1, PARAMETER_LIST
    .ifblank p1
        .exitmacro
    .endif
    .local number
    ; first, check if the user passed the A or Z prefix to designate byte or word sized value
    .if .xmatch(.left(1,{p1}), A)
        .word .right(.tcount({p1})-1, {p1})
    .elseif .xmatch(.left(1,{p1}), Z)
        .byte .right(.tcount({p1})-1, {p1})
    ; second, try to guess the address size ourselves
    .else
        number = p1 ; expression size rules apply: https://cc65.github.io/doc/ca65.html#ss5.2
        .if (.addrsize(number) = 1)
            .byte number
        .elseif (.addrsize(number) = 2)
            .word number
        .else
            .error "Cannot determine parameter size. Please use either the a or z prefix to define 16 or 8 bit values"
        .endif
    .endif
    COMPONENT_PARAMETERS PARAMETER_LIST
.endmacro

.macro COMPONENT_DEFINITION type, name, PARAMETER_LIST
    .byte components::ids::type
    name:
        COMPONENT_PARAMETERS PARAMETER_LIST
.endmacro



.macro COMPONENT_LIST_END
    .byte components::ids::no_component
.endmacro

.macro LDY_COMPONENT_MEMBER type, name, member
    ; comps is the absolute start address of the components string of a panel,
    ; comps::name is the absolute start address of the component with the given name,
    ; and the data_members::member is the offset of the requested data member within a component's data.
    ldy #(comps::name - comps + components::type::data_members::member)
.endmacro

.endif ; .ifndef ::GUI_PANELS_UTILS_ASM
