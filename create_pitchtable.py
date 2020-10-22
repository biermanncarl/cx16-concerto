# This file creates a table for all MIDI notes
# that can be understood by a 6502

# Reference:
# https://www.inspiredacoustics.com/en/MIDI_note_numbers_and_center_frequencies

# We are going to implement the function
# f = 440 * 2**((n-69)/12)

import numpy as np

# desired playback rate
PLAYBACK_SAMPLE_RATE = 48828.125

# how many samples equals one oscillation?
WAVETABLE_SIZE = 256

notes = np.arange(0,128)

# SI frequencies
frequencies = 440 * 2**((notes-69)/12)

# convert into phase advance per sample
phases = frequencies / PLAYBACK_SAMPLE_RATE

# convert into wavetable entries advance per sample
strides = phases * WAVETABLE_SIZE



myfile = open("pitchdata.txt","w")

for s in strides:
    msb = int(s)
    lsb = int(256 * (s-msb))
    myfile.write("    .byte {}, {}\n".format(lsb,msb))

myfile.close()
