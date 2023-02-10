#!/usr/bin/env bash
# https://wiki.archlinux.org/title/PulseAudio/Examples
# etrap "killall background" EXIT

while true; do
  set -x
  aplay -D plughw:2,10 /usr/share/sounds/alsa/Front_Center.wav &
  aplay -D plughw:2,8 /usr/share/sounds/alsa/Front_Center.wav &
  set +x
  sleep 2
done
