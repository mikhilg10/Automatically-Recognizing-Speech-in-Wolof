#!/bin/sh

python f.py "$@"

fstcompile -isymbols=L.vocab -osymbols=L.vocab F.txt > F.fst

fstcompose F.fst L.fst > FdotL.fst

fstshortestpath -nshortest=1 FdotL.fst path.fst

fstprint --isymbols=L.vocab --osymbols=L.vocab path.fst > path_output

python out_word.py "$@"

rm F.txt path.fst path_output 
