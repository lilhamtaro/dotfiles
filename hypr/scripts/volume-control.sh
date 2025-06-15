#!/bin/bash
# volume-control.sh
case $1 in
  up)
    pamixer --unmute && pamixer --increase 5
    ;;
  down)
    pamixer --unmute && pamixer --decrease 5
    ;;
  toggle)
    pamixer -t
    ;;
esac
