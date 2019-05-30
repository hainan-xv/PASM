#!/bin/bash

# building subwords
./run_align.sh data/train.txt data/lexicon.txt subwords.txt


# apply subwords
head data/train.txt | python apply_pasm.py subwords.txt 
