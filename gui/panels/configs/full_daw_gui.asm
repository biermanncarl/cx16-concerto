; Copyright 2023 Carl Georg Biermann

.ifndef ::GUI_PANELS_CONFIGS_DAW_GUI_ASM

::GUI_PANELS_CONFIGS_DAW_GUI_ASM = 1

.include "panels/synth_global.asm"
.include "panels/psg_oscillators.asm"
.include "panels/track_name_popup.asm"
.include "panels/clip_properties.asm"
.include "panels/clip_editing.asm"
.include "panels/envelopes.asm"
.include "panels/fm_general.asm"
.include "panels/fm_operators.asm"
.include "panels/global_navigation.asm"
.include "panels/lfo.asm"
.include "panels/combobox_popup.asm"
.include "panels/file_save_popup.asm"
.include "panels/file_load_popup.asm"
.include "panels/ok_cancel_popup.asm"
.include "panels/song_tempo_popup.asm"
.include "panels/synth_info.asm"
.include "panels/synth_navigation.asm"
.include "panels/about_popup.asm"
.include "panels/time_insert_delete_popup.asm"

.linecont + ; switch on line continuation with "\"
.define ALL_PANEL_SCOPES \
    clip_editing, \
    clip_properties, \
    synth_global, \
    psg_oscillators, \
    envelopes, \
    synth_navigation, \
    combobox_popup, \
    file_save_popup, \
    file_load_popup, \
    ok_cancel_popup, \
    song_tempo_popup, \
    track_name_popup, \
    lfo, \
    synth_info, \
    fm_general, \
    fm_operators, \
    global_navigation, \
    about_popup, \
    time_insert_delete_popup
.linecont - ; switch off line continuation with "\" (default)

.endif ; .ifndef ::GUI_PANELS_CONFIGS_DAW_GUI_ASM
