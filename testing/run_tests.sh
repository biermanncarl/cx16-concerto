#!/bin/bash

original_directory=$(pwd)
cd "$(dirname "$0")" # move into directory of the script

if [ -e "dump.bin" ]
then
    echo "Warning: existing dump.bin was found. Renaming it to dump.old.bin"
    mv -i dump.bin dump.old.bin
fi
rm -f "dump.bin"

if [ -e "TEST.PRG" ]
then
    echo "Warning: existing TEST.PRG was found. Renaming it to TEST.OLD.PRG"
    mv -i TEST.PRG TEST.OLD.PRG
fi
rm -f "TEST.PRG"

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
        echo "Error: Compilation failed!"
        echo
        continue
    fi
    echo "Running $test_file ..."
    x16emu -prg TEST.PRG -run -dump R > /dev/null 2>&1 & # hide error messages by routing them into /dev/null
    xdotool search --sync --name "Commander X16" key "ctrl+s"
    sleep 0.1
    xdotool search --sync --name "Commander X16" windowclose
    sleep 0.1
    test_results=$(hexdump -v -s 123 -n 5 -e '/1 "%d "' dump.bin) # read test results from binary dump
    result_array=($test_results)
    if [ ! ${result_array[4]} -eq 0 ]
    then
        echo "Error: Test was not exited properly!"
    fi
    if [ ! ${result_array[3]} -eq 66 ]
    then
        echo "Error: Test was not initialized properly!"
    fi
    echo "${result_array[2]} tests were executed."
    echo "${result_array[1]} failed."
    if [ ${result_array[1]} -gt 0 ]
    then
        echo "The first test that failed: ${result_array[0]}"
    fi
    echo
    rm -f "dump.bin"
    rm -f "TEST.PRG"
done
