# Welcome to CONCERTO

CONCERTO is a synthesizer engine for the Commander X16. It is designed to be
included in other applications. It comes with or without a user interface for
editing sounds.

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
cl65 -t cx16 -o CONCERTO.PRG -C cx16-asm.cfg -u __EXEHDR__ "example_full.asm"
```

## Quick start guide

If you have used synthesizers already, most of CONCERTO will be familiar to you.
In order for you to be able to feel right at home, there are some things you should
know, because they may at first be irritating to experienced synth users.

* **Concerto uses two different sound sources.** The Commander X16 has 16
  oscillators that can do either pulse, sawtooth, triangle or noise, and it has
  eight frequency modulation (FM) voices. In Concerto, the two different sound
  sources can be used on their own or be combined with one another, which offers
  great flexibility for sound design.
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
  This even affects the FM layer. When Envelope 1 is finished, it also turns off
  the FM voice.
* **Activate oscillators, envelopes and LFO.** This is done in the "Global" area,
  where you can specify how many envelopes and oscillators you need, and whether
  or not the LFO is active. Oscillators 1 to N will be active. If you temporarily
  need to mute oscillators, you can do so with the L/R selection drop-down.
* **Activate the FM voice.** The FM layer of Concerto gets activated as soon as
  one of the four operators in the "FM General" Box is activated. If all operators
  are disabled, no FM voice is used.
* **Pitch modulation.** Since here we are dealing with a 16-bit modulation, there are
  some optimizations to save precious CPU cycles. As a consequence, the modulation
  depth is only a qualitative representation (higher number gives more modulation)
  and also can't be zero. To deactivate pitch modulation, unselect the modulation
  source.
* **Save/Load presets.** Presets are currently saved to the file ```PRESET.COT```
  on the disk. Every save action will overwrite that file, and every load action
  will load from that file. Use it to store a preset that you want to use again
  in a later session.
* **There are hard and soft note-offs.** Soft note-offs put the voice into the release
  phase. Hard note-offs turn the voice off immediately. A hard note-off can also
  be used during the release phase (after a soft note-off). Hard note-offs are not
  available from the GUI, only from the API. (See ```concerto_synth.asm```)
* **Parameter clamping.** This is a feature of the sound engine. For volume and pulse-
  width, the values are clamped to the valid range to the best of its ability, to
  prevent overmodulation. You can deliberately use this, e.g. modulate the volume
  with an additional envelope "over the top" to make it sound compressed.
  This clamping is done before the "global" volume knob. So you can even make
  quiet sounds that sound compressed ;)
  For maximal modulation depth, the clamping can fail, though.
* **Finite pitch ranges.** Please note that the pitch values Concerto can handle
  only have a limited range. If pitch values beyond that range occur due to
  modulation or simply due to playing a high or low note, there may be unexpected
  results. Trial and error will lead you the way and show you what can be done and
  what can't.


## How to include Concerto into your own application

Currently, only projects written with CC65 assembler can use Concerto.

The easiest way to get started with Concerto is to look at the example files
provided along with the source code. Here is a quick summary what needs to be
done. More information on the usage of those routines can be found in the
source files ```concerto_synth/concerto_synth.asm``` and
```concerto_gui/gui_zeropage.asm```, respectively.

Synth engine:
* Copy the folder ```concerto_synth``` into the folder of your project
* Anywhere in your code that is not directly in the path of execution, do
  ```.INCLUDE "concerto_synth/concerto_synth.asm"```
* Do ```JSR concerto_synth::initialize``` to initialize the synth engine
* Do ```JSR concerto_synth::activate_synth``` to start the synth engine
* Call functions from ```concerto_synth/concerto_synth.asm``` to play notes
  etc.
* Do ```JSR concerto_synth::deactivate_synth``` to stop the synth engine
* You can define a subroutine with the name ```concerto_playback_routine```
  which will be called before each synth tick as long as the synth engine is
  activated.

Graphical user interface:
* Copy the folder ```concerto_gui``` into the folder of your project
* Anywhere in your code that is not directly in the path of execution, do
  ```.INCLUDE "concerto_gui/concerto_gui.asm"```, additionally to the
  inclusion of the synth engine.
* Do ```JSR concerto_gui::initialize``` to initialize and draw the UI
* Do ```JSR concerto_gui::gui_tick``` *regularly* to let the user interact
  using the mouse
* Do ```JSR concerto_gui::hide_mouse``` to hide the mouse pointer
* You may stop calling ```gui_tick``` regularly at any time without the danger
  of corruption. (E.g. if you want to bring up a different UI). Simply
  ```initialize``` again before continuing the regular calls of ```gui_tick```.

Player module:
* Copy both folders ```concerto_synth``` and ```concerto_player``` into the
  folder of your project
* Anywhere in your code that is not directly in the path of execution, do
  ```.INCLUDE "concerto_player/concerto_player.asm"```. Separate inclusion of
  the synth engine is not necessary in this case, since the player module
  already includes it.
* Do ```JSR concerto_synth::initialize``` to initialize the synth engine.
* Do ```JSR concerto_player::play_track``` to start playing the track.
  The function call expects the starting address of your music/sound data
  in .X/.Y (low byte in .X, high byte in .Y).
* Calling ```JSR concerto_synth::activate_synth``` is NOT necessary, since
  ```concerto_player::play_track``` activates the synth engine if necessary.
* Do ```JSR concerto_player::stop_track``` and/or 
  ```JSR concerto_synth::deactivate_synth``` to stop playing sounds.
