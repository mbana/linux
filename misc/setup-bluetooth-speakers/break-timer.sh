#/usr/bin/env bash
set -x

# Loop for 30 minutes
ffplay -autoexit -hide_banner -nodisp -loop 1800 -loglevel level+warning /home/mbana/setup/pc/bluetooth-speakers/1-second-of-silence.mp3

# Make a deep noise to sound for a break
ffplay -autoexit -hide_banner -nodisp -f lavfi -i "sine=frequency=512:duration=1" -autoexit -nodisp -volume 100 -loglevel level+warning