# Welcome to CONCERTO

CONCERTO is a music making program for the Commander X16. In its current shape,
there is only the synth engine present and a couple of demo loops. The graphical
user interface gives you full control over all sounds, even the ones used in the
demos. Go explore what the X16 can do!

In this document, you will find a quick start guide, and a brief explanation of
the structure of the source code.

## How to run CONCERTO in the emulator

The recommended way of starting the emulator for using CONCERTO is:

```shell
x16emu -prg CONCERTO.PRG -run -abufs 12 -sdcard <SD_CARD_IMAGE>
```

However, you can load and run concerto from inside the emulator as with most
```.PRG``` files. The ```abufs``` option is necessary in some environments to
reduce audio dropouts. If audio dropouts persist, increase the number.

You can also run CONCERTO without an SD card image. However, then the load/save
function for your preset is unavailable. (It simply does nothing.)

## How to build CONCERTO from source

CONCERTO is built using the ca65 assembler. I built it with the command

```shell
cl65 -t cx16 -o CONCERTO.PRG -C cx16-asm.cfg psg_synth.asm
```

## Quick sart guide

If you have used synthesizers already, most of CONCERTO will be familiar to you.
In order for you to be able to feel right at home, there are some things you should
know, because they may at first be irritating to experienced synth users.

* **Envelope rates instead of times.** Attack, Decay and Release specify the slopes,
  with which the envelope approaches its "destination". The higher the setting,
  the faster the envelope. Also the sustain level affects the speed. When it is
  low, it needs more time to reach sustain level.
* **Fine tuning.** Some edits appear with a dot next to the number.
  The dot indicates that this edit can be fine tuned. Fine tuning is done
  by dragging while holding the right mouse button, whereas coarse tuning
  is done by dragging while holding the left mouse button, as usual.
  Beware! If you changed the fine tuning, the edit will stay in the "fine edit
  mode" until you left click on it. In which mode it is, is indicated by the
  position of the dot.
* **Master Envelope.** Envelope 1 is the master envelope. That means that as soon as
  Envelope 1 has reached level 0 during the release phase (i.e. after a note-off
  event), the whole voice will be turned off. Essentially, Envelope 1 controls
  how long the voice will be audible.
* **Activate oscillators, envelopes and LFO.** This is done in the "Global" area,
  where you can specify how many envelopes and oscillators you need, and whether
  or not the LFO is active. Oscillators 1 to N will be active. If you temporarily
  need to mute oscillators, you can do so with the L/R selection drop-down.
* **Pitch modulation.** Since here we are dealing with a 16-bit modulation, there are
  some optimizations to save precious CPU cycles. As a consequence, the modulation
  depth is only a qualitative representation (higher number gives more modulation)
  and also can't be zero. To deactivate pitch modulation, unselect the modulation
  source.
* **Save/Load presets.** Presets are currently saved to the file ```PRESET.COT```
  on the disk. Every save action will overwrite that file, and every load action
  will load from that file. Use it to copy and paste timbres from one slot to
  another, or store a preset that you want to use again in a later session.
* **There are hard and soft note-offs.** Soft note-offs put the voice into the release
  phase. Hard note-offs turn the voice off immediately. A hard note-off can also
  be used during the release phase (after a soft note-off). Hard note-offs are not
  available from the GUI, only from the API. (See ```voices.asm```)
* **Parameter clamping.** This is a feature of the sound engine. For volume and pulse-
  width, the values are clamped to the valid range to the best of its ability, to
  prevent overmodulation. You can deliberately use this, e.g. modulate the volume
  with an additional envelope "over the top" to make it sound compressed.
  This clamping is done before the "global" volume knob. So you can even make
  quiet sounds that sound compressed ;)
  For maximal modulation depth, the clamping can fail, though.

## Source code structure

The main source code file is ```psg_synth.asm```. This is where all the
initialization routines are called, the main loop is inserted, and that exits back
to BASIC. You can find the build instructions there.

The overall structure of the program can be separated into the main loop, where
the GUI and all user interaction is done, and the interrupt service routine (ISR)
which does the synth engine and also the playback routine in a regular interval.

CONCERTO currently hijacks the sample playback mechanism in order to generate
interrupts at intervals of around 7 milliseconds. However, sound is only generated
by the 16 channels of the programmable sound generator (PSG) in the VERA.
This mechanism is placed inside ```my_isr.asm```.

The synth engine itself is placed inside ```synth_engine.asm```. The routine
```synth_tick``` computes the parameters for the PSG every 7 ms tick.

The GUI is located in ```gui.asm```. It uses some utility functions in
```guiutils.asm``` for drawing stuff on the screen. But all data juggling with the
GUI components is inside ```gui.asm```. This file, however, doesn't include any
code that lies directly in the path of execution of the main loop. Instead, GUI
routines like ```click_event``` or ```drag_event``` are called by the mouse code,
and the keyboard code (which in return *is* executed directly in the main loop).

Each source file contains some additional info about its content.
