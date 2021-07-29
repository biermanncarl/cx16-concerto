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

; This file contains an incomplete set of the registers of a YM2151 chip.
; Registers are added as they become relevant to this project.

; connection schemes
; feedback always is applied at modulator 1 (M1)
;
; con 0
; M1 -> C1 -> M2 -> C2 -> out
;
; con 1
; (M1 + C1) -> M2 -> C2 -> out
;
; con 2
; ((C1 -> M2) + M1) -> C2 -> out
;
; con 3
; ((M1 -> C1) + M2) -> C2 -> out
;
; con 4
; (M1 -> C1) + (M2 -> C2) -> out
;
; con 5
; (M1 -> C1) + (M1 -> M2) + (M1 -> C2) -> out
;
; con 6
; (M1 -> C1) + M2 + C2 -> out
;
; con 7
; M1 + C1 + M2 + C2 -> out

; one parameter in total (1 byte each)
YM_TEST             = $01
YM_KON              = $08 ; key on: channel number (bits 0-2) and slot enable M1 C1 M2 C2 (bits 3-6) (0 means key off, 1 means key on for each slot)

; one parameter per voice (8 bytes total each)
YM_RL_FL_CON           = $20 ; right (bit 7) and left (bit 6) channel enable, feedback level (bits 3-5) and connection scheme (bits 0-2)
YM_KC               = $28 ; key code: octave (bits 4-6) and note (bits 0-3)
YM_KF               = $30 ; key fraction (bits 2-7), in 1/64 of a half step
YM_PMS_AMS          = $38 ; LFO: pitch modulation sensititity (bits 4-6) and amplitude modulation sensitivity (bits 0-1)

; one parameter per slot (32 bytes total each)
; 8 x modulator 1 | 8 x modulator 2 | 8 x carrier 1 | 8 x carrier 2
YM_DT1_MUL          = $40 ; detuning 1 (bits 4-6) and frequency multiplier (bits 0-3)
YM_TL               = $60 ; total level of operator (bits 0-6) !! attenuation (higher number means lower volume)
YM_KS_AR            = $80 ; key scaling (bits 6-7) and attack rate (bits 0-4)
YM_AMS_EN_D1R       = $A0 ; amplitude modulation enable (bit 7) decay 1 rate (bits 0-4)
YM_DT2_D2R          = $C0 ; detune 2 (bits 6-7) and decay 2 rate (bits 0-4)
YM_D1L_RR           = $E0 ; decay 1 level (bits 4-7) and release rate (bits 0-3)

