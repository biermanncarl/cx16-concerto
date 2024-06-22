all: CONCERTO.PRG

.PHONY: run
run:
	cd build ; x16emu -prg CONCERTO.PRG -run -scale 2 -quality nearest -debug

.PHONY: test
test:
	testing/run_tests.sh

.PHONY: build_folder
build_folder:
	mkdir -p build

# this will force a target to be always built, which we do because it is cumbersome to track all of an .asm file's dependencies (includes!) with make
.PHONY: unspecified_dependencies
unspecified_dependencies:

CONCERTO.PRG: CONCMAIN.PRG unspecified_dependencies
	cl65 -t cx16 -o build/CONCERTO.PRG -C cx16-asm-concerto.cfg -u __EXEHDR__ -Ln build/CONCERTO.sym -g "main/concerto_launcher.asm"

CONCMAIN.PRG: build_folder unspecified_dependencies
	cl65 -t cx16 -o build/CONCMAIN.PRG -C cx16-asm-concerto.cfg -Ln build/CONCERTO.sym -g "main/concerto.asm"

.PHONY: examples
examples: example_01 example_02 example_03 example_04 example_05 example_06 example_07

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
	cl65 -t cx16 -o build/EXAMPLE07.PRG -C cx16-asm.cfg -u __EXEHDR__ "examples/example_07_include_timbres.asm"
