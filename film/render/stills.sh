#!/bin/bash
# usage: stills.sh shotId t1 t2 t3 ... -> /tmp/claude-0/stills/<id>_grid_<stamp>.png
id=$1; shift
cd /home/user/video/film
out=/tmp/claude-0/stills; mkdir -p $out
ins=(); for t in "$@"; do node render/render.mjs $id --still $t --out $out | grep -E "FAILED|ERR"; ins+=(-i $out/${id}_$t.png); done
n=$#
stamp=$(date +%H%M%S)
ffmpeg -loglevel error -y "${ins[@]}" -filter_complex "vstack=$n,scale=960:-1" $out/${id}_grid_$stamp.png 2>/dev/null || cp $out/${id}_$1.png $out/${id}_grid_$stamp.png
echo $out/${id}_grid_$stamp.png
