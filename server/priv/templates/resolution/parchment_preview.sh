#!/usr/bin/env sh

tmpfile=$(mktemp --tmpdir parchment_preview-XXXXXXXXXX.pdf)

pdftk $1 multibackground "$3/templates/resolution/parchment_preview_bg.pdf" output $tmpfile
convert -density 150 -strip -resize x800 $tmpfile +append -quality 80 jpg:$2
rm $tmpfile
