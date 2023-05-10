; Copyright 2023 Carl Georg Biermann

; Assembly testing utilities

.scope testing

; Using the last zeropage user addresses as "output" of the tests
; These will be read from the memory dump
exit_code = $7f ; exit code 0 means successfully arrived at the end of test execution (NOT that all tests were successful)
init_complete = $7e ; must be set to magic number $42 to ensure that initialization has been run
tests_run = $7d ; total number of tests that have been run
tests_unsuccessful = $7c ; number of unsuccessful tests
first_unsuccessful_test = $7b ; first test to fail

.macro START_TEST
   lda #1
   sta testing::exit_code
   stz testing::tests_run
   stz testing::tests_unsuccessful

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
   ; yes - remember which one it was
   lda tests_run
   inc
   sta first_unsuccessful_test
:  inc tests_unsuccessful
   inc tests_run
   pla
   rts
.endproc

.proc succeed
   inc tests_run
   rts
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

.endscope
