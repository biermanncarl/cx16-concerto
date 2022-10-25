; Copyright 2022 Carl Georg Biermann

; This file provides routines and memory needed for recording Zsound data.

; ToDo
; * start recording
;    * initializes memory & variables
;    * opens a file where the data can be written to
;    * writes header data into file
;    * assume all zeros for "current" buffer (? what forces first writes into any location ?)
; * write PSG
;    * accepts address/value pair for PSG
;    * stores it into a temporary buffer
;    * forwards the data to the VERA
; * write YM2151
;    * accepts address/value pair for YM2151
;    * writes it into temporary buffer
;    * forwards data to YM2151
; * flush tick
;    * compares currently set values with previously set values
;    * filters out redundant writes
;    * handles exceptions to this, such as KON register of the YM2151
;    * flush command values to "back buffers"
;    * write
; * stop recording
;    * close file
;    * any further cleanup needed

; variables / buffers needed
; 
; * command buffer for PSG
; * command buffer for YM2151
; * back buffer for YM2151
; * back buffer for VERA
; * file stuff
; * 


