#!/bin/bash

layout="$HOME/.screenlayout/default.sh"
outputs=$(grep -oP '(?<=--output )\S+' "$layout")

# Build a list of connected outputs
connected=$(xrandr | grep " connected" | awk '{print $1}')

# Only apply the layout if at least one output is connected
apply=false
for out in $outputs; do
  if [[ $(<<< "$connected" grep -q "^$out$") ]]; then
        apply=true
        break
    fi
done

echo "Connected outputs: $connected"
echo "Outputs in layout: $outputs"
if [[ "$apply" = true ]]; then
    bash "$LAYOUT"
fi
