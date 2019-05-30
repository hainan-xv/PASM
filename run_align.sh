#!/bin/bash
export PATH=$PATH:$PWD/tools/fast_align/build
stage=1

. ./parse_options.sh

# the format of $text file should be one sentence per line with only words,
# no things like utterance ids. e.g.
# ============= begin file ================
# THE SALE OF THE HOTELS IS PART OF HOLIDAY'S STRATEGY TO SELL OFF ASSETS AND CONCENTRATE ON PROPERTY MANAGEMENT
# THE HOTEL OPERATOR'S EMBASSY SUITES HOTELS INCORPORATED SUBSIDIARY WILL CONTINUE TO MANAGE THE PROPERTIES
# LONG TERM MANAGEMENT CONTRACTS ALLOW US TO GENERATE INCOME ON A SIGNIFICANTLY LOWER CAPITAL BASE SAID MICHAEL D. ROSE HOLIDAY'S CHAIRMAN AND CHIEF EXECUTIVE OFFICER
# I WANTED TO RUN MY AMATEUR THEATER LIKE THE BIG TIME HE REMEMBERS
# IT GAVE ME THE FEELING I WAS PART OF A LARGE INDUSTRY
# I NEVER WANTED TO GO TO THE INDEPENDENT CIRCUIT AND RAISE MONEY FROM OIL MEN AND DOCTORS
# I ALWAYS WANTED TO WORK ON THE INSIDE IN
# A LOSS WASN'T UNEXPECTED GIVEN CONTINENTAL'S OPERATIONAL DIFFICULTIES THAT DEVELOPED IN THE QUARTER
# HOWEVER THE RESULTS OF TEXAS AIR'S SUBSIDIARIES ARE THE REVERSE OF WHAT MANY ANALYSTS HAD PREDICTED EARLIER IN THE YEAR
# INSTEAD OF A MODEST PROFIT AT LOW COST CONTINENTAL BY THE SECOND QUARTER THE NEWLY EXPANDED UNIT HAS STRUGGLED WITH LOSSES
# ============= end file ================

# the format of $lexicon file should be, for each line, word phone1 phone2 ... phone_n
# e.g.
# ============= begin file ================
# AAA T R IH2 P AH0 L EY1
# AABERG AA1 B ER0 G
# AACHEN AA1 K AH0 N
# AACHENER AA1 K AH0 N ER0
# AAKER AA1 K ER0
# AALSETH AA1 L S EH0 TH
# AAMODT AA1 M AH0 T
# AANCOR AA1 N K AO2 R
# AARDEMA AA0 R D EH1 M AH0
# ============= end file ================
text=$1
lexicon=$2
output_file=$3
min_count=$4
min_ratio=$5


[ "$min_count" == "" ] && min_count=100 && echo min-count not specified, setting it to 100
[ "$min_ratio" == "" ] && min_ratio=0.5 && echo min-ratio not specified, setting it to 0.5

mkdir -p tmp_align/
dir=tmp_align

if [ $stage -le 1 ]; then
  echo stage 1, generate alignments
  cat $text | sed "s= =\n=g" | grep . | awk -v w=$lexicon 'BEGIN{while((getline<w)>0){v[$1]=$0}}{print v[$1]}' | grep . > $dir/raw
  cat $dir/raw | cut -d " " -f2- > $dir/phones.txt
  cat $dir/raw | awk '{print $1}' | tee $dir/words.txt | sed 's/./& /g' > $dir/letters.txt

  paste $dir/letters.txt $dir/phones.txt | sed "s=\t= ||| =g" > $dir/pasted.txt

  fast_align -i $dir/pasted.txt -T 4 -d -v -N > $dir/align.forward
  fast_align -i $dir/pasted.txt -T 4 -d -v -r -N > $dir/align.backward

  atools -i $dir/align.forward -j $dir/align.backward -c grow-diag-final-and > $dir/align.txt
fi

if [ $stage -le 2 ]; then
  python process_word.py $dir/align.txt $dir/letters.txt $dir/phones.txt | awk '{printf(" %s \n",$0)}' > $dir/phonetically_spelt_out_words.txt
# the file generated above looks like this,
# TH E
# S A LE
# O F
# TH E

  cat $dir/phonetically_spelt_out_words.txt | sed "s= =\n=g" | sort | uniq -c | sort -k1nr | tee $dir/subword.count.txt | awk -v m=$min_count '$1>m' | awk 'length($2)>1' | awk '{print $2}' > $dir/subwords.txt

fi

command=""

if [ $stage -le 3 ]; then
  for subword in `cat $dir/subwords.txt`; do
#    echo greping $subword
    subword_count=`grep  -F -- "$subword" $dir/phonetically_spelt_out_words.txt | wc -l`
#    echo $subword_count
    word_seq_count=`grep -F -- "$subword" $dir/words.txt | wc -l`
#    echo $subword $subword_count $word_seq_count
#    (>&2 echo echo $subword $subword_count $word_seq_count)
  echo $subword $subword_count $word_seq_count | awk -v r=$min_ratio '{ratio=$2/$3; if (ratio>r) print $1, ratio}' 
  done | sort -k2rg | awk '{print $1}' > $output_file
fi

# if [ $stage -le 4 ]; then
#   for i in `cat $dir/subwords.txt | grep -v "\"" | grep -v "'" | grep -v '\.' | grep -v "\-"`; do
#     j=$(echo $i | sed 's=.=& =g')
# 
#     n1=`grep "$i" $dir/phonetically_spelt_out_words.txt | wc -l`
#     n2=`grep "$j" $dir/phonetically_spelt_out_words.txt | wc -l`
# 
#     if [ $n1 -gt $n2 ]; then
#       command="$command sed \"s= $j =  $i  =g\" | "
#       echo adding: $i $j $n1 $n2
#     else
#       echo not adding: $i $j $n1 $n2
#     fi
#   done
#   exit
#   command="$command grep ."
# fi

#cat data/train_si284/text | cut -d " " -f2- | sed "s=.=& =g" | sed "s=^= =g" | eval $command | head

#echo " T H A N K " | eval $command | head

exit


cat lexicon.txt | awk '{print $1}' |  sed 's/./& /g' > $dir/words.txt
cat lexicon.txt | cut -d " " -f2- > $dir/phones.txt

paste $dir/words.txt $dir/phones.txt | sed "s=\t= ||| =g" > $dir/pasted.txt

fast_align -i $dir/pasted.txt -T 20 -d -v -N > $dir/align.forward
fast_align -i $dir/pasted.txt -T 20 -d -v -r -N > $dir/align.backward

atools -i $dir/align.forward -j $dir/align.backward -c grow-diag-final-and > $dir/align.txt
