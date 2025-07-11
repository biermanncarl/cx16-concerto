; Copyright 2025 Carl Georg Biermann

.ifndef ::GUI_PANELS_CONFIGS_COS2ZSM_GUI_ASM
::GUI_PANELS_CONFIGS_COS2ZSM_GUI_ASM = 1

.include "panels/combobox_popup.asm"
.include "panels/file_save_popup.asm"
.include "panels/file_load_popup.asm"
.include "panels/ok_cancel_popup.asm"
.include "panels/cos2zsm_global.asm"

.linecont + ; switch on line continuation with "\"
.define ALL_PANEL_SCOPES \
    combobox_popup, \
    file_save_popup, \
    file_load_popup, \
    ok_cancel_popup, \
    cos2zsm_global
.linecont - ; switch off line continuation with "\" (default)

.endif ; .ifndef ::GUI_PANELS_CONFIGS_COS2ZSM_GUI_ASM