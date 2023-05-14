; Copyright 2023 Carl Georg Biermann

; Assembly testing utilities
; All EXPECT_... macros preserve .A, .X and .Y, but not the processor status.

.scope testing

; Using the last zeropage user addresses as "output" of the tests
; These will be read from the memory dump
exit_code = $7f ; exit code 0 means successfully arrived at the end of test execution (NOT that all tests were successful)
init_complete = $7e ; must be set to magic number $42 to ensure that initialization has been run
tests_run = $7c ; total number of tests that have been run
tests_unsuccessful = $7a ; number of unsuccessful tests
first_unsuccessful_test = $78 ; first test to fail

.macro START_TEST
   lda #1
   sta testing::exit_code
   stz testing::tests_run
   stz testing::tests_run+1
   stz testing::tests_unsuccessful
   stz testing::tests_unsuccessful+1

   lda #$42
   sta testing::init_complete
.endmacro

.macro FINISH_TEST
   stz testing::exit_code
.endmacro

.proc fail
   pha
   ; first test to fail?
   lda tests_unsuccessful
   bne :+
   lda tests_unsuccessful+1
   bne :+
   ; yes - remember which one it was (add 1 for human readability)
   lda tests_run
   clc
   adc #1
   sta first_unsuccessful_test
   lda tests_run+1
   adc #0
   sta first_unsuccessful_test+1
:  ; count unsuccessful and total number of checks
   inc tests_unsuccessful
   bne :+
   inc tests_unsuccessful+1
:  inc tests_run
   bne :+
   inc tests_run+1
:  pla
   rts
.endproc

.proc succeed
   inc tests_run
   bne :+
   inc tests_run+1
:  rts
.endproc

; expect .A to be greater than value
.macro EXPECT_GT value
   cmp #(value+1)
   bcs :+
   jsr testing::fail
   bra :++
:  jsr testing::succeed
:
.endmacro

; expect .A to be greater than or equal to value
.macro EXPECT_GE value
   cmp #value
   bcs :+
   jsr testing::fail
   bra :++
:  jsr testing::succeed
:
.endmacro

; expect .A to be equal to value
.macro EXPECT_EQ value
   cmp #value
   beq :+
   jsr testing::fail
   bra :++
:  jsr testing::succeed
:
.endmacro

; expect .A to be unequal to value
.macro EXPECT_NE value
   cmp #value
   bne :+
   jsr testing::fail
   bra :++
:  jsr testing::succeed
:
.endmacro

; expect .A to be lower than value
.macro EXPECT_LT value
   cmp #value
   bcc :+
   jsr testing::fail
   bra :++
:  jsr testing::succeed
:
.endmacro

; expect .A to be lower than or equal to value
.macro EXPECT_LE value
   cmp #(value+1)
   bcc :+
   jsr testing::fail
   bra :++
:  jsr testing::succeed
:
.endmacro

.macro EXPECT_EQ_MEM address
   cmp address
   beq :+
   jsr testing::fail
   bra :++
:  jsr testing::succeed
:
.endmacro

.macro EXPECT_NE_MEM address
   cmp address
   bne :+
   jsr testing::fail
   bra :++
:  jsr testing::succeed
:
.endmacro

; expect carry flag to be set
.macro EXPECT_CARRY_SET
   bcs :+
   jsr testing::fail
   bra :++
:  jsr testing::succeed
:
.endmacro

; expect carry flag to be clear
.macro EXPECT_CARRY_CLEAR
   bcc :+
   jsr testing::fail
   bra :++
:  jsr testing::succeed
:
.endmacro

; expect zero flag to be set
.macro EXPECT_ZERO_SET
   beq :+
   jsr testing::fail
   bra :++
:  jsr testing::succeed
:
.endmacro

; expect zero flag to be clear
.macro EXPECT_ZERO_CLEAR
   bne :+
   jsr testing::fail
   bra :++
:  jsr testing::succeed
:
.endmacro

.endscope
