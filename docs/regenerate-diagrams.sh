#!/usr/bin/env bash
# Regenerate all D2 architecture diagrams to SVG

set -e

cd "$(dirname "$0")"

echo "Regenerating architecture diagrams..."

diagrams=(
  "system-overview"
  "page-generation-flow"
  "layout-system"
  "component-hierarchy"
  "grid-system"
)

for diagram in "${diagrams[@]}"; do
  echo "  - ${diagram}.d2 → ${diagram}.svg"
  d2 "${diagram}.d2" "${diagram}.svg"
done

echo "  - grid-orientation.rb → grid-orientation.svg"
bundle exec ruby grid-orientation.rb

echo "Done! All diagrams regenerated."
