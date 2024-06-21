; Copyright 2024 Carl Georg Biermann

.pushseg
.segment "VRAM1LOADADDR"
.import __VRAM1ASSETS_START__
.word __VRAM1ASSETS_START__ ; load address, first two bytes in the file

.segment "VRAM1ASSETS"

.scope vram_assets

test_data:
    .byte 1,2,3,4,5,6,7,8,9


.endscope

.popseg
