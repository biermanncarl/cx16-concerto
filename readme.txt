Guide for folks used to synths
------------------------------

If you have used a lot of synthesizers, most of CONCERTO will be familiar to you.
In order for you to be able to feel right at home, there are some things you should
know, because they may at first be irritating to experienced synth users.

  * Envelope rates instead of times. Attack, Decay and Release specify the slopes,
    with which the envelope approaches its "destination". The higher the setting,
    the faster the envelope. Also the sustain level affects the speed. When it is
    low, it needs more time to reach sustain level.
  * Fine tuning. Some edits appear with a dot next to the number.
    The dot indicates that this edit can be fine tuned. Fine tuning is done
    by dragging while holding the right mouse button, whereas coarse tuning
    is done by dragging while holding the left mouse button, as usual.
    Beware! If you changed the fine tuning, the edit will stay in the "fine edit
    mode" until you left click on it. In which mode it is, is indicated by the
    position of the dot.
  * Master Envelope. Envelope 1 is the master envelope. That means that as soon as
    Envelope 1 has reached level 0 during the release phase (i.e. after a note-off
    event), the whole voice will be turned off. Essentially, Envelope 1 controls
    how long the voice will be audible.
  * Pitch modulation. Since here we are dealing with a 16-bit modulation, there are
    some optimizations to save precious CPU cycles. As a consequence, the modulation
    depth is only a qualitative representation (higher number gives more modulation)
    and also can't be zero. To deactivate pitch modulation, unselect the modulation
    source.
  * Activate oscillators and envelopes. This is done in the "Global" area, where you
    can specify how many envelopes and oscillators you need. Oscillators 1 to N will
    be active. If you temporarily need to mute oscillators, you can do so with the
    L/R selection drop-down.
  * There are hard and soft note-offs. Soft note-offs put the voice into the release
    phase. Hard note-offs turn the voice off immediately. A hard note-off can also
    be used during the release phase (after a soft note-off).
  * Parameter clamping. This is a feature of the sound engine. For volume and pulse-
    width, the values are clamped to the valid range to the best of its ability, to
    prevent overmodulation. You can deliberately use this, e.g. modulate the volume
    with an additional envelope "over the top" to make it sound compressed.
    This clamping is done before the "global" volume knob. So you can even make
    quiet sounds that sound compressed ;)