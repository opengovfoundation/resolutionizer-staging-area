#!/usr/bin/env sh

pdftk $1 multibackground priv/templates/resolution/parchment_preview_bg.pdf output out.pdf
convert -density 150 -strip -resize x800 out.pdf +append -quality 80 jpg:$2
rm out.pdf
