#!/bin/bash
# Generate example planners for current year and next year in all themes

set -e

# Get current year and next year
CURRENT_YEAR=$(date +%Y)
NEXT_YEAR=$((CURRENT_YEAR + 1))

# Create examples directory if it doesn't exist
mkdir -p examples

echo "Generating example planners..."
echo

# Array of themes
THEMES=("light" "earth" "dark")

# Generate for current year and next year
for YEAR in $CURRENT_YEAR $NEXT_YEAR; do
  echo "==> Generating planners for $YEAR"

  for THEME in "${THEMES[@]}"; do
    echo "  → $THEME theme..."
    bin/bujo-pdf $YEAR --theme $THEME
    mv "planner_${YEAR}.pdf" "examples/planner_${YEAR}_${THEME}.pdf"
  done

  echo
done

echo "✓ Generated example planners:"
ls -lh examples/
echo
echo "Done!"
