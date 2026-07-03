#!/bin/bash

# Get the currently focused AeroSpace workspace
FOCUSED_WORKSPACE=$(aerospace list-workspaces --focused)

# Update all workspace indicators
for workspace in W C M P; do
  if [ "$FOCUSED_WORKSPACE" = "$workspace" ]; then
    sketchybar --set space."$workspace" background.drawing=on icon.highlight=on
  else
    sketchybar --set space."$workspace" background.drawing=off icon.highlight=off
  fi
done
