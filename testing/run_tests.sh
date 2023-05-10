#!/bin/bash

original_directory=$(pwd)
cd "$(dirname "$0")" # move into directory of the script

color_off='\033[0m' # color off
red='\033[0;31m' # red
bred='\033[1;31m' # bold red
bwhite='\033[1;37m' # bold white
bgreen='\033[1;32m' # bold green

if [ $# -eq 0 ]
then
    test_files=$(find .. -name "test_*.asm")
    use_original_directory=false
else
    test_files=$@
    use_original_directory=true
fi

for test_file in $test_files
do
    echo "Compiling $test_file ..."
    if [ "$use_original_directory" = true ] ;
    then
        test_file="${original_directory}/${test_file}"
    fi
    cl65 -t cx16 -o TEST.PRG -C cx16-asm.cfg -u __EXEHDR__ "$test_file"
    if [ ! $? -eq 0 ]
    then
        echo -e "${bred}Error: Test compilation failed!${color_off}"
        echo
        continue
    fi
    echo "Running $test_file ..."
    x16emu -prg TEST.PRG -run -dump R -debug > /dev/null 2>&1 & # hide error messages by routing them into /dev/null
    sleep 0.2
    xdotool search --sync --name "Commander X16" key "ctrl+s"
    sleep 0.2
    xdotool search --sync --name "Commander X16" windowclose
    test_results=$(hexdump -v -s 120 -n 8 -e '/1 "%u "' dump.bin) # read test results from binary dump
    result_array=($test_results)
    if [ ! ${result_array[7]} -eq 0 ]
    then
        echo -e "${bred}Error: Test was not exited properly!${color_off}"
    fi
    if [ ! ${result_array[6]} -eq 66 ]
    then
        echo -e "${bred}Error: Test was not initialized properly!${color_off}"
    fi
    num_of_checks=$((${result_array[4]}+256*${result_array[5]}))
    num_of_fails=$((${result_array[2]}+256*${result_array[3]}))
    echo "${num_of_checks} checks were executed."
    if [ ${num_of_fails} = "0" ]
    then
        echo -e "${bgreen}${num_of_fails} checks failed.${color_off}"
    else
        echo -e "${bred}${num_of_fails} checks failed.${color_off}"
    fi
    if [ ${num_of_fails} -gt 0 ]
    then
        first_fail=$((${result_array[0]}+256*${result_array[1]}))
        echo -e "${bred}The first check that failed: ${first_fail}${color_off}"
    fi
    echo
    rm -f "dump.bin"
    rm -f "TEST.PRG"
done
