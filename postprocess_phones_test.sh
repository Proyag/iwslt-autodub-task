
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

BPEROOT=../subword-nmt/subword_nmt
modelname=$2
name=test$modelname

chckp=$(echo "$1" | sed 's:.*/::')

CUDA_VISIBLE_DEVICES=$3 fairseq-generate ./data-bin/$modelname/ --path $1 --source-lang de --target-lang en --batch-size 256  --remove-bpe --beam 5  --gen-subset test > $name
cat  $name | grep -P "^H" |sort -V |cut -f 3- | sed 's/\[en\]//g' >  $name.hyp

perl -pe "s/\[pause\]//g" $name.hyp >  $name.hyp.nopause
python phonemes-eow-to-phoneticwords.py  $name.hyp.nopause $4

mkdir $modelname-test-using-6-$chckp
mv  $name.hyp.nopause.phoneticwords $modelname-test-using-6-$chckp/test.en

cd $modelname-test-using-6-$chckp
python $BPEROOT/apply_bpe.py -c ../en_phonetic_transcr_codes_10k < test.en > bpe.test.en
cp bpe.test.en bpe.test.txt
fairseq-preprocess --source-lang en --target-lang txt --testpref bpe.test --srcdict ../data-bin/model6-en-phoneticwords-en-txt/dict.en.txt --tgtdict ../data-bin/model6-en-phoneticwords-en-txt/dict.txt.txt
CUDA_VISIBLE_DEVICES=$3 fairseq-generate ./data-bin/ --path ../trained_models/model6-en-phoneticwords-en-txt/checkpoint_best.pt --gen-subset test --batch-size 256 --source-lang en --target-lang txt --remove-bpe --beam 5  > $modelname_gen_with_6_chckp_$chckp.txt

cat $modelname_gen_with_6_chckp_$chckp.txt | grep -P "^H" |sort -V |cut -f 3- | sed 's/\[en\]//g' > $modelname_gen_with_6_chckp_$chckp.txt.hyp

sacrebleu ../test_txt.en -i $modelname_gen_with_6_chckp_$chckp.txt.hyp -m bleu -lc --tokenize none

#  bash postprocess_phones_test.sh trained_models/model7/checkpoint100.pt model7 0 durations

# argument 1: path to checkpoint (with best valid scores, we can find that by running postprocess_phones.sh)
# argument 2: binarized data dir name
# argument 3: if this model has durations on the target side (English) (values: durations or withoutdurations)


