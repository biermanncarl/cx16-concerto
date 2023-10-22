; Copyright 2023 Carl Georg Biermann

; Possible tests for RNGs are:
; * "bins" tests
;   * check that the entire range of numbers is covered
;   * put random bytes into bins
;     * 16 bins for the high bits
;     * 16 bins for the low bits
;   * also use the difference between subsequent random numbers to exclude the RNG sequentially filling all bins
;   * check for statistic thresholds / probability limits
;   * need MANY random numbers

.macro DEFINE_HISTOGRAM name
name:
    .res 16, $00 ; low bytes
    .res 16, $00 ; high bytes
.endmacro

; expects the bin index in .X
.macro COUNT_IN_HISTOGRAM name
    inc name, x
    bne :+
    inc name+16, x
:
.endmacro

.macro CHECK_LIMITS hist_name, lower, upper
.local @loop
    ldy #15
@loop:
    ; compare lower limit
    lda hist_name+16, y
    tax
    lda hist_name, y
    EXPECT_GE_16 lower
    EXPECT_LE_16 upper
    dey
    bpl @loop
.endmacro



.code
    jmp start

.include "../../testing/testing.asm"
.include "../random.asm"

; how many numbers to be generated
number_of_iterations = $1000
avg_per_bin = number_of_iterations / 16
shot_noise = $0040 ; 64 is square root of 4096=$1000

counter:
    .word number_of_iterations

; We create 4 separate histograms.
; Each histogram has 16 bins, of which each should have an equal probability of 1/16th to be met
DEFINE_HISTOGRAM hist_upper_nibble
DEFINE_HISTOGRAM hist_lower_nibble
DEFINE_HISTOGRAM hist_upper_nibble_difference
DEFINE_HISTOGRAM hist_lower_nibble_difference

current_random_number:
    .byte 0
previous_random_number:
    .byte 0

start:
    START_TEST

    RNG_SEED 42, 43, 44

@generator_loop:
    jsr rng::random_byte
    sta current_random_number

    ; update histograms
    lsr
    lsr
    lsr
    lsr
    tax
    COUNT_IN_HISTOGRAM hist_upper_nibble

    lda current_random_number
    and #$0F
    tax
    COUNT_IN_HISTOGRAM hist_lower_nibble

    lda current_random_number
    clc
    sbc previous_random_number
    lsr
    lsr
    lsr
    lsr
    tax
    COUNT_IN_HISTOGRAM hist_upper_nibble_difference

    lda current_random_number
    clc
    sbc previous_random_number
    and #$0F
    tax
    COUNT_IN_HISTOGRAM hist_lower_nibble_difference

    ; update loop
    lda current_random_number
    sta previous_random_number
    lda counter
    sec
    sbc #1
    sta counter
    lda counter+1
    sbc #0
    sta counter+1
    bcs @generator_loop


    ; check results
    lower_limit = avg_per_bin - 2 * shot_noise
    upper_limit = avg_per_bin + 2 * shot_noise

    CHECK_LIMITS hist_upper_nibble, lower_limit, upper_limit
    CHECK_LIMITS hist_lower_nibble, lower_limit, upper_limit
    CHECK_LIMITS hist_upper_nibble_difference, lower_limit, upper_limit
    CHECK_LIMITS hist_lower_nibble_difference, lower_limit, upper_limit

    FINISH_TEST
    rts
