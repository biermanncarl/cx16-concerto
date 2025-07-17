# Welcome to Concerto Multitrack

The user manual of the software is [here](doc/USER-MANUAL.MD).

## Dependencies

For building Concerto:
* CC65 V2.19
* Make

On Ubuntu, simply type `make` when inside the repo.

For unit testing:
* Commander X16 Emulator R48
* xdotool version 3.20160805.1

## Changelog

### v0.8.0-beta.2

New features
* Standalone tool to export ZSM files (`COS2ZSM.PRG`)
* Recording of musical keyboard inputs
* Exit button, clean return to BASIC but with the current directory retained

Fixed bugs
* Copy/paste corrupting song data when all notes of a track were copied
* Sample and hold table overwritten by loader; SnH should be somewhat more random now
* GUI had wrong scale when any screen mode other than 80x60 characters was active when starting Concerto


### v0.7.0-beta.1

First beta release.

## Contact

carlgeorg at gmx dot net

Copyright 2020-2025 Carl Georg Biermann
