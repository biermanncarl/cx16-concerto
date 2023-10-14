; Copyright 2023 Carl Georg Biermann

; This file helps resolve circular dependencies by lifting certain symbols
; out of their scopes. This makes them accessible to code which lives in earlier scopes
; that were defined before the scopes these symbols are lifted from.
; This works because symbols can be accessed before they are defined,
; but scopes cannot.

panels__listbox_popup__box_x = panels::listbox_popup::box_x
panels__listbox_popup__box_y = panels::listbox_popup::box_y
panels__listbox_popup__box_width = panels::listbox_popup::box_width
panels__listbox_popup__box_height = panels::listbox_popup::box_height
panels__listbox_popup__strlist = panels::listbox_popup::strlist
panels__listbox_popup__lb_ofs = panels::listbox_popup::lb_ofs
panels__listbox_popup__lb_addr = panels::listbox_popup::lb_addr
panels__listbox_popup__lb_id = panels::listbox_popup::lb_id
panels__listbox_popup__lb_panel = panels::listbox_popup::lb_panel
panels__listbox_popup__draw = panels::listbox_popup::draw
panels__panels_stack = panels::panels_stack
panels__panels_stack_pointer = panels::panels_stack_pointer
panels__ids__listbox_popup = panels::ids::listbox_popup
panels__px = panels::px
panels__py = panels::py
gui_routines__refresh_gui = gui_routines::refresh_gui
gui_routines__draw_gui = gui_routines::draw_gui
gui_routines__load_clip_gui = gui_routines::load_clip_gui
gui_routines__load_arrangement_gui = gui_routines::load_arrangement_gui
gui_routines__load_synth_gui = gui_routines::load_synth_gui
