if [ $# -ne 1 ]; then
    echo "Usage $0 [Phrase in quotes]"
    exit 1
fi

phrase=$1
cd ..
[ -f exp/tri1_ali/ali.1.gz ] || steps/align_si.sh --nj 8 --cmd "run.pl" data/train lang exp/tri1 exp/tri1_ali
steps/get_train_ctm.sh data/train lang/ exp/tri1_ali/ 2D/ctm
cd -
grep -w $(echo $phrase | cut -f1 -d " ") ctm/ctm | cut -f1-2 -d "_" > word1.txt
for i in $phrase; do
    #echo $i
    grep $i ctm/ctm | cut -f1-2 -d "_" | uniq > word2.txt
    grep -f word1.txt word2.txt > word3.txt
    mv word3.txt word1.txt
    num=$(wc -l word1.txt | cut -f1 -d " ")
    #echo $num
    if [ $num -eq 1 ]; then
        break
    fi
done
echo "Speakers which have uttered words in \"$1\" are:"
cat word1.txt

mkdir -p audios
rm -f audios/*

for spk in $(cat word1.txt); do
    sox -n -r 16000 audios/final_${spk}.wav trim 0.0 0.005
    for word in $phrase; do
        line=$(grep $spk ctm/ctm | grep -w $word | head -1)
        file=$(echo $(echo $line | cut -f1 -d " ").wav)
        dur=$(echo $line | cut -f3-4 -d " ")
        sox ../wav/$file audios/temp.wav trim $dur tempo 0.85 pad 0.1 0.1
        sox audios/final_${spk}.wav audios/temp.wav audios/concat.wav
        mv audios/concat.wav audios/final_${spk}.wav
        
    done
done
rm audios/temp.wav
echo "audios concatenated and added to audios folder in 2D"
rm word*.txt


