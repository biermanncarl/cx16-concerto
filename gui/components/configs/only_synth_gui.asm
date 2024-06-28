; Copyright 2023 Carl Georg Biermann

.ifndef ::GUI_COMPONENTS_CONFIGS_DEFAULT_ASM

::GUI_COMPONENTS_CONFIGS_DEFAULT_ASM = 1

.include "components/button.asm"
.include "components/checkbox.asm"
.include "components/arrowed_edit.asm"
.include "components/drag_edit.asm"
.include "components/combobox.asm"
.include "components/listbox.asm"
.include "components/tab_selector.asm"
.include "components/dummy.asm"

.linecont + ; switch on line continuation with "\"
.define ALL_COMPONENT_SCOPES \
    button, \
    checkbox, \
    arrowed_edit, \
    drag_edit, \
    combobox, \
    listbox, \
    tab_selector, \
    dummy
.linecont - ; switch off line continuation with "\" (default)

.endif ; .ifndef ::GUI_COMPONENTS_CONFIGS_DEFAULT_ASM
