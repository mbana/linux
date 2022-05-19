#/usr/bin/bash

~/.config/systemd/user/
cp ./bluetooth-break-timer.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable bluetooth-break-timer.service
systemctl --user daemon-reload

systemctl --user restart --now bluetooth-break-timer.service

journalctl -xeu bluetooth-break-timer.service
journalctl --user bluetooth-break-timer.service
journalctl --user --user-unit=bluetooth-break-timer --follow

systemctl --user status bluetooth-break-timer.service


