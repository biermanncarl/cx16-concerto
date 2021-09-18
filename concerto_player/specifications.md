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
|              4 | Set pitchbend rate. The rate is a 16 bit number. Negative slopes are done using integer overflow. | Rate low | Rate high | --- |
|              5 | Set pitchbend position. | Note | Fine tune | --- |
|              6 | Set volume increase rate. The rate is a 16 bit number. Negative slopes are done using integer overflow. | Rate low | Rate high | --- |
|              7 | Set volume | Volume (aka velocity) | --- | --- |
|              8 | Set vibrato increase rate. | Rate low | Rate high | --- |
|              9 | Set vibrato amount | Amount | --- | --- |
|             10 | unused | | | |
|             11 | unused | | | |
|             12 | unused | | | |
|             13 | User callback: Trigger a user-defined event during the song | --- | --- | --- |
|             14 | Stop all channels | --- | --- | --- |
|             15 | End of song | --- | --- | --- |




Copyright 2021 Carl Georg Biermann