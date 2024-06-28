; Copyright 2023 Carl Georg Biermann

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
panels__panels_stack = panels::panels_stack
panels__panels_stack_pointer = panels::panels_stack_pointer
panels__ids__combobox_popup = panels::ids::combobox_popup
panels__px = panels::px
panels__py = panels::py
gui_routines__refresh_gui = gui_routines::refresh_gui
gui_routines__draw_gui = gui_routines::draw_gui
gui_routines__load_clip_gui = gui_routines::load_clip_gui
gui_routines__load_arrangement_gui = gui_routines::load_arrangement_gui
gui_routines__load_synth_gui = gui_routines::load_synth_gui
