#!/bin/sh

# Create F.txt
python make_fst.py "$@"

fstcompile -isymbols=L.vocab -osymbols=L.vocab first.txt > first.fst

fstcompile -isymbols=L.vocab -osymbols=L.vocab second.txt > second.fst

fstarcsort first.fst first.fst

fstarcsort second.fst second.fst

fstcompose first.fst second.fst > T.fst

fstarcsort T.fst T.fst

fstcompose T.fst L.fst > TdotL.fst

fstshortestpath -nshortest=1 TdotL.fst path.fst

fstprint --isymbols=L.vocab --osymbols=L.vocab path.fst > path_output

python print_pred.py

rm path_output 
