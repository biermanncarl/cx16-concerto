"""This script loads all *.COP and *.COS files in the current directory and migrates them between the specified versions.

The version counting is explicitly unofficial and is used during development.
"""

import numpy as np
import pathlib


CURRENT_VERSION = 1
TARGET_VERSION = 2


def open_preset(path):
    raw_data = np.fromfile(path, dtype=np.uint8, sep="")
    header_size = 4
    header = raw_data[:header_size]
    instrument_data = raw_data[header_size:]
    return header, instrument_data[np.newaxis, :]


def save_preset(path, header, instrument_data):
    np.concatenate([header, instrument_data[0]], axis=0).tofile(path, sep="")


def open_song(path):
    raw_data = np.fromfile(path, dtype=np.uint8, sep="")
    header_size = 7
    old_instrument_data_size = 150
    num_instruments = 32
    instrument_data_size = old_instrument_data_size * num_instruments
    header = raw_data[:header_size]
    instrument_data = raw_data[header_size : header_size + instrument_data_size]
    tracks_data = raw_data[header_size + instrument_data_size :]
    return (
        header,
        np.reshape(instrument_data, (old_instrument_data_size, num_instruments)).T,
        tracks_data,
    )


def save_song(path, header, instrument_data, tracks_data):
    np.concatenate(
        [header, instrument_data.T.flatten("C"), tracks_data], axis=0
    ).tofile(path, sep="")


def migrate_v0_v1(instrument_data):
    """Migrates instrument data from version 0 to version 1.

    Version 0: commit 62f68f3dfeefc2894ac7f32a999150454685f0a1
    Version 1: commit d073c18ce289b18fb108fbc706fbdec9c44e790f
    Changes:
    * The pitch offset of the FM voice is lowered by 12 semitones to compensate for the opposite change in the sound engine.
      (Previously, PSG pitch matched FM mul=0. Now, PSG matches FM mul=1)
    * The LFO settings are inserted at different locations

    Args:
        instrument_data (np.NDarray): array of uint8, shaped (num_instruments, bytes_per_instrument)

    Returns:
        updated byte array with shape (num_instruments, new_bytes_per_instrument)
    """
    fm_pitch_address_old = 101
    cut_offsets_old = [106, 114]
    inserts = [
        [
            0,  # LFO enable
            127,  # fm_lfo_vol_mod
            127,  # fm_lfo_pitch_mod
            2,  # fm_lfo_waveform
            210,  # fm_lfo_frequency
            0,  # fm_lfo_vol_sens
            0,  # fm_lfo_pitch_sens
        ],
        [
            0,
            0,
            0,
            0,  # op_vol_sens_lfo
        ],
    ]

    # re-pitch FM voice
    instrument_data[:, fm_pitch_address_old] += 12

    # insert new data
    cut_offsets_old.append(instrument_data.shape[1])
    new_data_segments = [instrument_data[:, : cut_offsets_old[0]]]
    for cut_nr, insert_data in enumerate(inserts):
        insert_data_array = np.repeat(
            np.array(insert_data, dtype=np.uint8)[np.newaxis, :],
            instrument_data.shape[0],
            axis=0,
        )
        new_data_segments.append(insert_data_array)
        new_data_segments.append(
            instrument_data[..., cut_offsets_old[cut_nr] : cut_offsets_old[cut_nr + 1]]
        )

    return np.concatenate(new_data_segments, axis=1)


def migrate_v1_v2(instrument_data):
    """Migrates instrument data from version 0 to version 1.

    Version 1: commit d073c18ce289b18fb108fbc706fbdec9c44e790f
    Version 2: commit 728d42e61203b4c16a7fd58e23a2bbd56f5dd544
    Changes:
    * For triangle and sawtooth, PWM now has an effect
    * Set PW to 63 for all sawtooth and triangle oscillators
    * Deactivate PWM for sawtooth and triangle oscillators

    Args:
        instrument_data (np.NDarray): array of uint8, shaped (num_instruments, bytes_per_instrument)

    Returns:
        updated byte array with shape (num_instruments, new_bytes_per_instrument)
    """

    num_oscillators = 4

    osc_waveform_offset = 81
    osc_pulse_offset = 85
    osc_pwm_sel_offset = 89

    # Which oscillators are affected
    waveforms = instrument_data[
        :, osc_waveform_offset : osc_waveform_offset + num_oscillators
    ]
    oscillator_mask = np.logical_or(waveforms == 1 * 64, waveforms == 2 * 64)

    # Update pulse width
    old_pulse_width = instrument_data[
        :, osc_pulse_offset : osc_pulse_offset + num_oscillators
    ]
    instrument_data[:, osc_pulse_offset : osc_pulse_offset + num_oscillators] = (
        np.where(oscillator_mask, 63, old_pulse_width)
    )

    # Update PWM
    old_pwm_sources = instrument_data[
        :, osc_pwm_sel_offset : osc_pwm_sel_offset + num_oscillators
    ]
    instrument_data[:, osc_pwm_sel_offset : osc_pwm_sel_offset + num_oscillators] = (
        np.where(oscillator_mask, 128, old_pwm_sources)
    )

    return instrument_data


if __name__ == "__main__":
    assert TARGET_VERSION == CURRENT_VERSION + 1
    if TARGET_VERSION == 1:
        migrate = migrate_v0_v1
    elif TARGET_VERSION == 2:
        migrate = migrate_v1_v2

    for preset_path in pathlib.Path(".").glob("*.COP"):
        header, instrument_data = open_preset(preset_path)
        instrument_data = migrate(instrument_data)
        save_preset(preset_path, header, instrument_data)

    for song_path in pathlib.Path(".").glob("*.COS"):
        header, instrument_data, tracks_data = open_song(song_path)
        instrument_data = migrate(instrument_data)
        save_song(song_path, header, instrument_data, tracks_data)
