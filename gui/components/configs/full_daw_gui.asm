; Copyright 2023-2024 Carl Georg Biermann

.ifndef ::GUI_COMPONENTS_CONFIGS_DEFAULT_ASM

::GUI_COMPONENTS_CONFIGS_DEFAULT_ASM = 1

.include "components/button.asm"
.include "components/checkbox.asm"
.include "components/arrowed_edit.asm"
.include "components/drag_edit.asm"
.include "components/combobox.asm"
.include "components/listbox.asm"
.include "components/text_edit.asm"
.include "components/tab_selector.asm"
.include "components/dummy.asm"
.include "components/drag_and_drop_area.asm"
.include "components/dynamic_label.asm"
.include "components/text_field.asm"

.linecont + ; switch on line continuation with "\"
.define ALL_COMPONENT_SCOPES \
    button, \
    checkbox, \
    arrowed_edit, \
    drag_edit, \
    combobox, \
    listbox, \
    text_edit, \
    tab_selector, \
    dummy, \
    drag_and_drop_area, \
    dynamic_label, \
    text_field
.linecont - ; switch off line continuation with "\" (default)

.endif ; .ifndef ::GUI_COMPONENTS_CONFIGS_DEFAULT_ASM
