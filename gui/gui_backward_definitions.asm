; Copyright 2023-2024 Carl Georg Biermann

; This file helps resolve circular dependencies by lifting certain symbols
; out of their scopes. This makes them accessible to code which lives in earlier scopes
; that were defined before the scopes these symbols are lifted from.
; This works because symbols can be accessed before they are defined,
; but scopes cannot.

panels__combobox_popup__box_x = panels::combobox_popup::box_x
panels__combobox_popup__box_y = panels::combobox_popup::box_y
panels__combobox_popup__box_width = panels::combobox_popup::box_width
panels__combobox_popup__box_height = panels::combobox_popup::box_height
panels__combobox_popup__strlist = panels::combobox_popup::strlist
panels__combobox_popup__lb_ofs = panels::combobox_popup::lb_ofs
panels__combobox_popup__lb_addr = panels::combobox_popup::lb_addr
panels__combobox_popup__lb_id = panels::combobox_popup::lb_id
panels__combobox_popup__lb_panel = panels::combobox_popup::lb_panel
panels__combobox_popup__draw = panels::combobox_popup::draw
panels__file_save_popup__save_file_name = panels::file_save_popup::save_file_name
panels__file_save_popup__doFileOperation = panels::file_save_popup::doFileOperation
panels__ok_cancel_popup__string_bank = panels::ok_cancel_popup::string_bank
panels__ok_cancel_popup__string_address = panels::ok_cancel_popup::string_address
panels__global_navigation__redrawMusicalKeyboardSettings = panels::global_navigation::redrawMusicalKeyboardSettings
panels__clip_properties__copyClipSettingsToMusicalKeyboard = panels::clip_properties::copyClipSettingsToMusicalKeyboard
panels__panels_stack = panels::panels_stack
panels__panels_stack_pointer = panels::panels_stack_pointer
panels__ids__combobox_popup = panels::ids::combobox_popup
panels__ids__file_save_popup = panels::ids::file_save_popup
panels__ids__file_load_popup = panels::ids::file_load_popup
panels__ids__ok_cancel_popup = panels::ids::ok_cancel_popup
panels__ids__track_name_popup = panels::ids::track_name_popup
panels__ids__song_tempo_popup = panels::ids::song_tempo_popup
panels__ids__global_navigation = panels::ids::global_navigation
panels__ids__about_popup = panels::ids::about_popup
panels__px = panels::px
panels__py = panels::py
gui_routines__refresh_gui = gui_routines::refresh_gui
gui_routines__draw_gui = gui_routines::draw_gui
gui_routines__load_clip_gui = gui_routines::load_clip_gui
gui_routines__load_arrangement_gui = gui_routines::load_arrangement_gui
gui_routines__load_synth_gui = gui_routines::load_synth_gui
mouse__getMouseChargridMotion = mouse::getMouseChargridMotion
