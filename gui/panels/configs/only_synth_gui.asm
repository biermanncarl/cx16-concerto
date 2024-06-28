; Copyright 2023 Carl Georg Biermann

.ifndef ::GUI_PANELS_CONFIGS_ONLY_SYNTH_GUI_ASM

::GUI_PANELS_CONFIGS_ONLY_SYNTH_GUI_ASM = 1

.include "panels/synth_global.asm"
.include "panels/psg_oscillators.asm"
.include "panels/envelopes.asm"
.include "panels/fm_general.asm"
.include "panels/fm_operators.asm"
.include "panels/lfo.asm"
.include "panels/combobox_popup.asm"
.include "panels/synth_info.asm"
.include "panels/synth_navigation.asm"

.linecont + ; switch on line continuation with "\"
.define ALL_PANEL_SCOPES \
    synth_global, \
    psg_oscillators, \
    envelopes, \
    synth_navigation, \
    combobox_popup, \
    lfo, \
    synth_info, \
    fm_general, \
    fm_operators
.linecont - ; switch off line continuation with "\" (default)

.endif ; .ifndef ::GUI_PANELS_CONFIGS_ONLY_SYNTH_GUI_ASM
