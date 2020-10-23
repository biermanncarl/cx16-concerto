Default_isr:
   .word $0000

message:
   .byte $0D, "controls", $0D
   .byte "--------", $0D, $0D
   .byte "a,w,s,...   play notes", $0D
   .byte "z,x         toggle octaves", $0D
   .byte "q           quit", $0D
end_message:

   ; keyboard values
Octave:
   .byte 60
Note:
   .byte 0
Fine:
   .byte 0

   ; AD-Envelope variables
   ; front end
AD_attack:
   .byte 0
AD_decay:
   .byte 0
   ; back-end
AD_attack_rate:
   .word 0
AD_decay_rate:
   .word 0
AD_step:
   .byte 0
AD_phase:
   .word 0