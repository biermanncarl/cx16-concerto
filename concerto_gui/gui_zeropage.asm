; Copyright 2021 Carl Georg Biermann

; This file is part of Concerto.

; Concerto is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.

; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.

; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;*****************************************************************************

; my zero page words (main program)
mzpwa:   .word 0
; my zero page words (main program)
mzpwd:   .word 0
; my zero page words (main program)
mzpwe:   .word 0   ; this is used mainly as a pointer for string operations


; my zero page bytes (main program)
mzpba:   .byte 0
; my zero page bytes (main program)
mzpbh:   .byte 0