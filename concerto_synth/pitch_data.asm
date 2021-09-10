; Copyright 2021 Carl Georg Biermann


; Lookup table that converts notes from 0..11 semitones to 0..15 semitones,
; because, for some reason, the YM2151 spreads 12 semitones over the range of 0..15
; Mathematically speaking, one would have to multiply by 4/3 and round down to get the YM2151 note value.
semitones_ym2151:
   .byte 0,1,2,3,5,6,7,9,10,11,13,14

; Lookup tables for PSG frequencies
pitch_dataH:
   .byte 0
   .byte 0
   .byte 0
   .byte 0
   .byte 0
   .byte 0
   .byte 0
   .byte 0
   .byte 0
   .byte 0
   .byte 0
   .byte 0
   .byte 0
   .byte 0
   .byte 0
   .byte 0
   .byte 0
   .byte 0
   .byte 0
   .byte 0
   .byte 0
   .byte 0
   .byte 0
   .byte 0
   .byte 0
   .byte 0
   .byte 0
   .byte 0
   .byte 0
   .byte 0
   .byte 0
   .byte 0
   .byte 0
   .byte 0
   .byte 0
   .byte 0
   .byte 0
   .byte 0
   .byte 0
   .byte 0
   .byte 0
   .byte 0
   .byte 0
   .byte 1
   .byte 1
   .byte 1
   .byte 1
   .byte 1
   .byte 1
   .byte 1
   .byte 1
   .byte 1
   .byte 1
   .byte 1
   .byte 1
   .byte 2
   .byte 2
   .byte 2
   .byte 2
   .byte 2
   .byte 2
   .byte 2
   .byte 3
   .byte 3
   .byte 3
   .byte 3
   .byte 3
   .byte 4
   .byte 4
   .byte 4
   .byte 4
   .byte 5
   .byte 5
   .byte 5
   .byte 6
   .byte 6
   .byte 6
   .byte 7
   .byte 7
   .byte 8
   .byte 8
   .byte 9
   .byte 9
   .byte 10
   .byte 10
   .byte 11
   .byte 12
   .byte 13
   .byte 13
   .byte 14
   .byte 15
   .byte 16
   .byte 17
   .byte 18
   .byte 19
   .byte 20
   .byte 21
   .byte 23
   .byte 24
   .byte 26
   .byte 27
   .byte 29
   .byte 31
   .byte 32
   .byte 34
   .byte 36
   .byte 39
   .byte 41
   .byte 43
   .byte 46
   .byte 49
   .byte 52
   .byte 55
   .byte 58
   .byte 62
   .byte 65
   .byte 69
   .byte 73
   .byte 78
   .byte 82
   .byte 87
   .byte 93
   .byte 98
   .byte 104
   .byte 110
   .byte 117
   .byte 124
   .byte 131
   .byte 139
   .byte 147
   .byte 156
   .byte 165
   .byte 175
   .byte 186
   .byte 197
   .byte 208
   .byte 221
   .byte 234
   .byte 248
pitch_dataL:
   .byte 21
   .byte 23
   .byte 24
   .byte 26
   .byte 27
   .byte 29
   .byte 31
   .byte 32
   .byte 34
   .byte 36
   .byte 39
   .byte 41
   .byte 43
   .byte 46
   .byte 49
   .byte 52
   .byte 55
   .byte 58
   .byte 62
   .byte 65
   .byte 69
   .byte 73
   .byte 78
   .byte 82
   .byte 87
   .byte 93
   .byte 98
   .byte 104
   .byte 110
   .byte 117
   .byte 124
   .byte 131
   .byte 139
   .byte 147
   .byte 156
   .byte 165
   .byte 175
   .byte 186
   .byte 197
   .byte 208
   .byte 221
   .byte 234
   .byte 248
   .byte 7
   .byte 22
   .byte 39
   .byte 56
   .byte 75
   .byte 95
   .byte 116
   .byte 138
   .byte 161
   .byte 186
   .byte 212
   .byte 240
   .byte 14
   .byte 45
   .byte 78
   .byte 113
   .byte 150
   .byte 190
   .byte 232
   .byte 20
   .byte 67
   .byte 116
   .byte 169
   .byte 225
   .byte 28
   .byte 90
   .byte 157
   .byte 227
   .byte 45
   .byte 124
   .byte 208
   .byte 40
   .byte 134
   .byte 233
   .byte 82
   .byte 194
   .byte 56
   .byte 181
   .byte 58
   .byte 198
   .byte 91
   .byte 249
   .byte 160
   .byte 81
   .byte 12
   .byte 211
   .byte 165
   .byte 132
   .byte 113
   .byte 107
   .byte 116
   .byte 141
   .byte 183
   .byte 242
   .byte 64
   .byte 162
   .byte 25
   .byte 166
   .byte 75
   .byte 9
   .byte 226
   .byte 214
   .byte 232
   .byte 26
   .byte 110
   .byte 228
   .byte 128
   .byte 68
   .byte 50
   .byte 77
   .byte 151
   .byte 19
   .byte 196
   .byte 173
   .byte 209
   .byte 53
   .byte 220
   .byte 201
   .byte 1
   .byte 137
   .byte 101
   .byte 154
   .byte 46
   .byte 38
   .byte 136
   .byte 90
   .byte 163
   .byte 107
   .byte 184
   .byte 146
   .byte 3
   .byte 19
   .byte 203
   .byte 53
   .byte 92
   .byte 76
