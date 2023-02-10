#/usr/bin/env bash
set -x

#aplay -l0 blank.mp3

#ffplay -nodisp -loop 0 -loglevel 8 ./blank.mp3
ffplay -hide_banner -nodisp -loop 0 -loglevel level+warning ./blank.mp3

ffplay -f lavfi -i "sine=frequency=512:duration=1" -autoexit -nodisp -volume 100 -loglevel warning