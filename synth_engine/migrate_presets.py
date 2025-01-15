"""This script loads all *.COP and *.COS files in the current directory and migrates them between the specified versions.

The version counting is explicitly unofficial and is used during development.
"""

import numpy as np
import pathlib


CURRENT_VERSION = 0
TARGET_VERSION = 1


def open_preset(path):
    raw_data = np.fromfile(path, dtype=np.uint8, sep="")
    header_size = 4
    header = raw_data[:header_size]
    instrument_data = raw_data[header_size:]
    return header, instrument_data[np.newaxis, :]


def save_preset(path, header, instrument_data):
    np.concatenate([header, instrument_data[0]], axis=0).tofile(path, sep="")


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


if __name__ == "__main__":
    for preset_path in pathlib.Path(".").glob("*.COP"):
        header, instrument_data = open_preset(preset_path)
        instrument_data = migrate_v0_v1(instrument_data)
        save_preset(preset_path, header, instrument_data)
