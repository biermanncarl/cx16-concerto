; Copyright 2023-2024 Carl Georg Biermann

; This file helps resolve circular dependencies by lifting certain symbols
; out of their scopes. This makes them accessible to code which lives in earlier scopes
; that were defined before the scopes these symbols are lifted from.
; This works because symbols can be accessed before they are defined,
; but scopes cannot.

hitboxes__hitbox_pos_x = hitboxes::hitbox_pos_x
hitboxes__hitbox_pos_y = hitboxes::hitbox_pos_y
hitboxes__hitbox_width = hitboxes::hitbox_width
hitboxes__hitbox_event_a = hitboxes::hitbox_event_a
hitboxes__hitbox_event_x = hitboxes::hitbox_event_x
hitboxes__hitbox_event_y = hitboxes::hitbox_event_y
hitboxes__hitbox_event_selected = hitboxes::hitbox_event_selected
hitboxes__clear_hitboxes = hitboxes::clear_hitboxes
hitboxes__add_hitbox_data = hitboxes::add_hitbox_data
hitboxes__load_hitbox_list = hitboxes::load_hitbox_list
hitboxes__hitbox_handle__none = hitboxes::hitbox_handle::none
hitboxes__hitbox_handle__bulk = hitboxes::hitbox_handle::bulk
hitboxes__hitbox_handle__right_end = hitboxes::hitbox_handle::right_end

dragables__active_hitbox_type = dragables::active_type
dragables__ids__notes = dragables::ids::notes
dragables__ids__effects = dragables::ids::effects
dragables__ids__clips = dragables::ids::clips
dragables__ids__end_id = dragables::ids::end_id
