#!/bin/bash
sudo sed -i '/^#HandleLidSwitchDocked=ignore/s/^#//' /etc/systemd/logind.conf
sudo sed -i '/^#HoldoffTimeoutSec=5s/s/^#//' /etc/systemd/logind.conf
