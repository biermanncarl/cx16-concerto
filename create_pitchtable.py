# This file creates a table for all MIDI notes
# that can be understood by a 6502

# Reference:
# https://www.inspiredacoustics.com/en/MIDI_note_numbers_and_center_frequencies

# We are going to implement the function
# f = 440 * 2**((n-69)/12)

# and the frequency generation rule of the VERA
# output_frequency = sample_rate / (2^17) * frequency_word

import numpy as np

# number of notes in our table
N_NOTES = 139

# the notes we want to map
notes = np.arange(0,N_NOTES)

# desired playback rate
PLAYBACK_SAMPLE_RATE = 25.0e6 / 512. # = 48828.125

# SI frequencies
output_frequencies = 440 * 2**((notes-69)/12)

frequency_words = output_frequencies * (2**17) / PLAYBACK_SAMPLE_RATE

msb = np.array((frequency_words.astype(int)//256), dtype=int)
lsb = np.array(frequency_words-256*msb, dtype=int)


myfile = open("pitch_data.asm","w")

myfile.write('pitch_dataH:\n')
for n in msb:
    myfile.write("   .byte {}\n".format(n))

myfile.write('pitch_dataL:\n')
for n in lsb:
    myfile.write("   .byte {}\n".format(n))

myfile.close()
