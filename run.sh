#!/bin/bash

# This script trains + decodes a baseline ASR system for Wolof.

# initialization PATH
. ./path.sh  || die "path.sh expected";
# initialization commands
. ./cmd.sh

[ ! -L "steps" ] && ln -s ../wsj/s5/steps

[ ! -L "utils" ] && ln -s ../wsj/s5/utils

###############################################################
#                   Configuring the ASR pipeline
###############################################################
stage=5    # from which stage should this script start
nj=8        # number of parallel jobs to run during training
test_nj=2    # number of parallel jobs to run during decoding
augment=0
nj_aug=8
# the above two parameters are bounded by the number of speakers in each set
###############################################################

# Stage 1: Prepares the train/dev data. Prepares the dictionary and the
# language model.
if [ $stage -le 1 ]; then
  echo "Preparing lexicon and language models"
  local/prepare_lexicon.sh || exit 1 
  local/prepare_lm.sh || exit 1
fi
# Feature extraction
# Stage 2: MFCC feature extraction + mean-variance normalization
if [ $stage -le 2 ]; then
   for x in train ; do
      steps/make_mfcc.sh --nj $nj --cmd "$train_cmd" data/$x exp/make_mfcc/$x mfcc
      steps/compute_cmvn_stats.sh data/$x exp/make_mfcc/$x mfcc
   done
   for x in dev test; do                                                                                         
      steps/make_mfcc.sh --nj $test_nj --cmd "$train_cmd" data/$x exp/make_mfcc/$x mfcc                             
      steps/compute_cmvn_stats.sh data/$x exp/make_mfcc/$x mfcc                                                
   done

fi

# Stage 3: Training and decoding monophone acoustic models
if [ $stage -le 3 ]; then
  ### Monophone
    echo "Monophone training"
	steps/train_mono.sh --nj "$nj" --cmd "$train_cmd" data/train lang exp/mono
    echo "Monophone training done"
    echo "Decoding the test set"
    utils/mkgraph.sh lang exp/mono exp/mono/graph
  
    # This decode command will need to be modified when you 
    # want to use tied-state triphone models 
    steps/decode.sh --nj $test_nj --num-threads 8 --cmd "$decode_cmd" \
      exp/mono/graph data/dev exp/mono/decode_dev
    echo "Monophone decoding done on dev set."
    echo "Monophone decoding on test set"
    steps/decode.sh --nj $test_nj --num-threads 8 --cmd "$decode_cmd" \
        exp/mono/graph data/test exp/mono/decode_test
    test_wer=$(head exp/mono/decode_test/wer_* | grep WER | utils/best_wer.sh | cut -f2 -d " ")
    echo "#### WER on test set after monophone training ######\n"
    echo "$test_wer \n\n"


fi

# Stage 4: Training tied-state triphone acoustic models
if [ $stage -le 4 ]; then
  ### Triphone
    echo "Triphone training"
    steps/align_si.sh --nj $nj --cmd "$train_cmd" \
       data/train lang exp/mono exp/mono_ali
	steps/train_deltas.sh --boost-silence 1.25  --cmd "$train_cmd"  \
	   4000 80000 data/train lang exp/mono_ali exp/tri1
    echo "Triphone training done"
	# Add triphone decoding steps here #
    utils/mkgraph.sh lang exp/tri1 exp/tri1/graph || exit 1
    steps/decode.sh --nj $test_nj --num-threads 8 --cmd "$decode_cmd" \
       exp/tri1/graph data/dev exp/tri1/decode_dev || exit 1
    steps/decode.sh --nj $test_nj --num-threads 8 --cmd "$decode_cmd" \
        exp/tri1/graph data/test exp/tri1/decode_test || exit 1

    test_wer=$(head exp/tri1/decode_test/wer_* | grep WER | utils/best_wer.sh | cut -f2 -d " ")
    echo "#### WER on test set after triphone training ######\n"
    echo "$test_wer \n\n"


fi

tri1=tri1
tri3=tri3
tri2=tri2
tri1_ali=tri1_ali
tri2_ali=tri2_ali
dev=dev
train=train
if [ $stage -le 5 ]; then
    echo "\n######## Three way speed perturbation for data augmentation ########\n"
    utils/data/perturb_data_dir_speed_3way.sh data/train data/train_sp3
    for x in train_sp dev; do
        utils/copy_data_dir.sh data/$x data/${x}_hires
    done
    echo "\n###### Creating high resolution MFCC features for augmented data ######\n"
    for x in train_sp3 dev test; do
        steps/make_mfcc.sh \
            --nj $nj_aug\
            --cmd "$train_cmd"\
            data/${x} exp/make_mfcc_hires/${x} mfcc_sp3
        steps/compute_cmvn_stats.sh data/${x} exp/make_mfcc_sp3/${x} mfcc_sp3
        utils/fix_data_dir.sh data/${x}
    done
    steps/align_fmllr.sh data/train_sp3/ lang exp/mono/ exp/mono_ali_sp3/
    
    steps/train_deltas.sh --boost-silence 1.25  --cmd "$train_cmd"  \
       4000 80000 data/train_sp3 lang exp/mono_ali_sp3 exp/tri1_sp3 || exit 1

    utils/mkgraph.sh lang exp/tri1_sp3 exp/tri1_sp3/graph || exit 1 
    
    steps/decode.sh --nj 2 --num-threads 8 --cmd "$decode_cmd" \
       exp/tri1_sp3/graph data/dev exp/tri1_sp3/decode_dev_sp3 || exit 1

    steps/decode.sh --nj 2 --num-threads 8 --cmd "$decode_cmd" \
        exp/tri1_sp3/graph data/test exp/tri1_sp3/decode_test_sp3 || exit 1

    test_wer=$(head exp/tri1_sp3/decode_test_sp3/wer_* | grep WER | utils/best_wer.sh | cut -f2 -d " ")
    echo "#### WER on test set after augmentation and triphone training ######\n"
    echo "$test_wer \n\n"


    
fi

if [ $stage -le 6 ]; then
    if [ $augment -eq 1 ]; then
        tri1=tri1_sp3
        tri2=tri2_sp3
        tri3=tri3_sp3
        tri1_ali=tri1_ali_sp3
        tri2_ali=tri2_ali_sp3
        train=train_sp3
    fi
  ### Triphone
      echo "#######  Triphone LDA+MLLT training #########"                                                                                                                                                    
    steps/align_si.sh --nj $nj --cmd "$train_cmd" \
        data/$train lang exp/$tri1 exp/$tri1_ali                                                                                                                                                               
    steps/train_lda_mllt.sh --boost-silence 1.25  --cmd "$train_cmd" \
       4000 80000 data/$train lang exp/$tri1_ali exp/$tri2                                                                                                                                                     
    echo "Triphone LDA+MLLT training done"                                                                                                                                                                           
    # Add triphone decoding steps here #                                                                                                                                                                    
    utils/mkgraph.sh lang exp/$tri2 exp/$tri2/graph || exit 1                                                                                                                                                 
    steps/decode.sh --nj 2 --num-threads 8 --cmd "$decode_cmd" \
       exp/$tri2/graph data/dev exp/$tri2/decode_dev || exit 1
    

    echo "#######  Triphone LDA+MLLT+SAT training #########"                                                       
    steps/align_si.sh --nj $nj --cmd "$train_cmd" \
        data/$train lang exp/$tri2 exp/$tri2_ali 
    steps/train_sat.sh --boost-silence 1.25  --cmd "$train_cmd"  \
       4000 80000 data/$train lang exp/$tri2_ali exp/$tri3
    echo "Triphone training done"                                                                              
    # Add triphone decoding steps here #                                                                       
    utils/mkgraph.sh lang exp/$tri3 exp/$tri3/graph || exit 1                                                    
    steps/decode_fmllr.sh --nj 2 --num-threads 8 --cmd "$decode_cmd" \
       exp/$tri3/graph data/dev exp/$tri3/decode_dev || exit 1
    steps/decode_fmllr.sh --nj 2 --num-threads 8 --cmd "$decode_cmd" \
        exp/$tri3/graph data/test exp/$tri3/decode_test

    test_wer=$(head exp/$tri3/decode_test/wer_* | grep WER | utils/best_wer.sh | cut -f2 -d " ")
    echo "#### WER on test set after best training ######\n"                                                                                                                       
    echo "$test_wer \n\n"
fi                                                           


#wait;
#score
# Computing the best WERs
for x in exp/*/decode*; do [ -d $x ] && grep WER $x/wer_* | utils/best_wer.sh; done
