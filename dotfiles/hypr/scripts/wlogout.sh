#!/usr/bin/env bash

res_h=$(hyprctl -j monitors | jq '.[] | select(.focused==true) | .height')
h_scale=$(hyprctl -j monitors | jq '.[] | select(.focused==true) | .scale')
w_margin=$(jq -n --argjson h "$res_h" --argjson s "$h_scale" '$h * 0.27 / $s | floor')
wlogout -b 5 -T "$w_margin" -B "$w_margin"
