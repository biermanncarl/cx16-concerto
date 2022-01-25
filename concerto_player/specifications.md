Concerto Player Specification
=============================

The Concerto Player reads data located in RAM and interprets it as a stream of
commands that it sends to the Concerto synth engine. Each command begins with
one byte that contains the command number and the Concerto channel number. It
is followed by 0 to 3 data bytes. That means, some commands are just 1 byte
in length, and others up to 4 bytes.

The first byte contains a number from 0 to 15 in the most significant four
bits which designate the command, and another number from 0 to 15 in the least
significant four bits, which designate the Concerto channel to which the
command is addressed. If the command does not address a specific channel
(like commands 0, 14 and 15), the lower "nibble" is ignored.

| Command number | Description | Data Byte 1 | Data Byte 2 | Data Byte 3 |
|----------------|-------------|-------------|-------------|-------------|
|              0 | Wait for N ticks. N is a 16 bit number. | N low | N high | --- |
|              1 | Play note | Timbre number | pitch | velocity (0...63) |
|              2 | Release note (aka soft note-off) | --- | --- | --- |
|              3 | Stop note (aka hard note-off) | --- | --- | --- |
|              4 | Set pitchbend position. | Fine tune | Note | --- |
|              5 | Set pitchbend rate. The rate is a 16 bit number. Negative slopes are done using integer overflow. | Rate low | Rate high | mode |
|              6 | Set volume | Volume (aka velocity) | --- | --- |
|              7 | Set volume increase rate. Negative slopes are supported. | Slope | Threshold | --- |
|              8 | Set vibrato amount | Amount (0 to 27) | --- | --- |
|              9 | Set vibrato ramp | Slope | Threshold amount (0 to 27) | --- |
|             10 | unused | | | |
|             11 | unused | | | |
|             12 | unused | | | |
|             13 | User callback: Trigger a user-defined event during the song | user data (.A) | --- | --- |
|             14 | Stop all channels | --- | --- | --- |
|             15 | End of song | --- | --- | --- |




5: Set pitchbend rate
----------------------

This command activates the pitch slide on a channel. If the pitch slide was
inactive previously, the slide position is set to the current note being
played.

The mode is either 0 or 1. Set it to 0 if you want a free slide. Set it to 1 if
you want the slide to stop at the note that was originally played. This can be
useful if you want to slide up/down to a note. In this use case work, you need
to activate the slide and THEN set the slide position with command 5, since
otherwise, the slide position would be reset.

Set negative slopes by using integer overflow. For example, to generate a pitch
slide that descends 30 fine steps each tick, use the values 226 for rate low
and 255 for rate high. Or to descend 2 semitones per tick, use 0 for rate low
and 254 for rate high.


7: Set volume ramp
------------------

A gradual increase or decrease in volume can be activated with this command.
The slope is signed 8-bit, meaning that values from 128 to 255 are negative
and therefore produce downward slopes. The threshold indicates the value at
which the ramp should stop. The ramp will stop whenever a new note is
triggered. It should continue across several notes as long as they are not
retriggered (i.e. tied together).


8: Set vibrato amount
---------------------

This command sets the amount of vibrato on a note. If vibrato is active in the
timbre, it gets overridden temporarily. The effect will last until one of the
three conditions is fulfilled:
* the vibrato is set to 0,
* a hard note-off,
* the channel is inactive for at least one tick,
* the timbre is changed.
Value 0 deactivates vibrato, the values 1 to 27 correspond to a pitch
modulation of 28 to 54. This shift of values and the limited vibrato range is
due to the way the vibrato amount is represented internally and how the vibrato
ramp is being done.

If a vibrato ramp was set previously, the ramp is cancelled and needs to be set
again afterwards if desired.


9: Set vibrato ramp
-------------------

This command allows to let the vibrato amount gradually increase. The slope
defines how quick the amount changes. The threshold sets the vibrato amount at
which the slope is stopped. Negative slopes are supported.


13: User callback
-----------------

This command calls a user definable subroutine. One data byte is loaded into
the processor register .A and passed to the user subroutine. This can be useful
to synchronize visual effects with the music, or anything you have in mind,
really.

The callback function can be defined by setting the variable
concerto_player::callback_vector to the starting address of your callback
function.


14: Stop all channels (aka Panic)
---------------------------------

This command deactivates all voices on all channels immediately.


15: End song
---------------------------------

This ends the song. Depending on the variable concerto_player::repeat, the song
will be played again or the player will be deactivated.


Copyright 2021-2022 Carl Georg Biermann