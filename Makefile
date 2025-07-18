all: CONCERTO.PRG COS2ZSM.PRG

.PHONY: run
run:
	cd build ; x16emu -prg CONCERTO.PRG -scale 2 -debug -abufs 8 -capture -nokeyboardcapture -run

.PHONY: convert
convert:
	cd build ; x16emu -prg COS2ZSM.PRG -scale 2 -debug -abufs 8 -capture -nokeyboardcapture -run

.PHONY: test
test:
	testing/run_tests.sh

.PHONY: build_folder
build_folder:
	mkdir -p build

# this will force a target to be always built, which we do because it is cumbersome to track all of an .asm file's dependencies (includes!) with make
.PHONY: unspecified_dependencies
unspecified_dependencies:

CONCERTO.PRG: CONCMAIN.BIN copy_presets copy_docs unspecified_dependencies
	cl65 -t cx16 -o build/CONCERTO.PRG -C cx16-asm-concerto.cfg -u __EXEHDR__ -Ln build/CONCERTO.sym -g "main/concerto_launcher.asm"
	mv build/CONCERTO.PRG.VRAM build/VRAMASSETS.BIN

CONCMAIN.BIN: build_folder unspecified_dependencies
	cl65 -t cx16 -o build/CONCMAIN.BIN -C cx16-asm-concerto.cfg -Ln build/CONCMAIN.sym -g "main/concerto.asm"
	rm build/CONCMAIN.BIN.VRAM

COS2ZSM.PRG:
	cl65 -t cx16 -o build/COS2ZSM.PRG -C cx16-asm-concerto.cfg -u __EXEHDR__ -Ln build/COS2ZSM.sym -g "cos2zsm/cos2zsm.asm"
	mv build/COS2ZSM.PRG.VRAM build/VRAMASSETS-COS2ZSM.BIN

.PHONY: examples
examples: example_01 example_02 example_03 example_04 example_05 example_06 example_07

.PHONY: copy_presets
copy_presets:
	cp -r presets/* build/
	mkdir -p build/INSTRUMENTS-USER
	mkdir -p build/SONGS-USER

.PHONY: copy_docs
copy_docs:
	cp README.MD build/
	mkdir -p build/DOCUMENTATION
	cp doc/* build/DOCUMENTATION/

example_01: build_folder unspecified_dependencies
	cl65 -t cx16 -o build/EXAMPLE01.PRG -C cx16-asm.cfg -u __EXEHDR__ "examples/example_01_hello_world_concerto.asm"

example_02: build_folder unspecified_dependencies
	cl65 -t cx16 -o build/EXAMPLE02.PRG -C cx16-asm.cfg -u __EXEHDR__ "examples/example_02_playback.asm"

example_03: build_folder unspecified_dependencies
	cl65 -t cx16 -o build/EXAMPLE03.PRG -C cx16-asm.cfg -u __EXEHDR__ "examples/example_03_pitchbend.asm"

example_04: build_folder unspecified_dependencies
	cl65 -t cx16 -o build/EXAMPLE04.PRG -C cx16-asm.cfg -u __EXEHDR__ "examples/example_04_player.asm"

example_05: build_folder unspecified_dependencies
	cl65 -t cx16 -o build/EXAMPLE05.PRG -C cx16-asm.cfg -u __EXEHDR__ "examples/example_05_modulation.asm"

example_06: build_folder unspecified_dependencies
	cl65 -t cx16 -o build/EXAMPLE06.PRG -C cx16-asm.cfg -u __EXEHDR__ "examples/example_06_callback.asm"

example_07: build_folder unspecified_dependencies
	cl65 -t cx16 -o build/EXAMPLE07.PRG -C cx16-asm.cfg -u __EXEHDR__ "examples/example_07_include_instruments.asm"
