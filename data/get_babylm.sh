URL=https://github.com/babylm/babylm.github.io/raw/main/babylm_data.zip
DIR=data/corpora/babylm

mkdir -p $DIR

wget $URL -O $DIR/babylm_data.zip
unzip $DIR/babylm_data.zip -d $DIR
rm $DIR/babylm_data.zip

mv $DIR/babylm_data/* $DIR
rm -r $DIR/babylm_data

#process gutenberg books separately for more natural linebreaks
python src/gutenberg_tokenize.py --source $DIR/babylm_100M/gutenberg.train --target $DIR/babylm_100M/gutenberg_sentences.train
rm $DIR/babylm_100M/gutenberg.train
# do not include qed files
rm $DIR/babylm_100M/qed.train

python src/gutenberg_tokenize.py --source $DIR/babylm_test/gutenberg.test --target $DIR/babylm_test/gutenberg_sentences.test
rm $DIR/babylm_test/gutenberg.test
rm $DIR/babylm_test/qed.test

python src/gutenberg_tokenize.py --source $DIR/babylm_dev/gutenberg.dev --target $DIR/babylm_dev/gutenberg_sentences.train
rm $DIR/babylm_dev/gutenberg.dev
rm $DIR/babylm_dev/qed.dev

# concatenate all files within each dir babylm_100M, babylm_dev, babylm_test
cat $DIR/babylm_100M/* > $DIR/train_100M.txt
cat $DIR/babylm_dev/* > $DIR/dev.txt
cat $DIR/babylm_test/* > $DIR/test.txt

# sentence-tokenize all files using src/sentence_tokenize.py
python src/sentence_tokenize.py --source $DIR/train_100M.txt --target $DIR/train.sents
python src/sentence_tokenize.py --source $DIR/dev.txt --target $DIR/dev.sents
python src/sentence_tokenize.py --source $DIR/test.txt --target $DIR/test.sents

# remove the original dirs
rm -r $DIR/babylm_100M
rm -r $DIR/babylm_10M
rm -r $DIR/babylm_dev
rm -r $DIR/babylm_test

rm $DIR/train_100M.txt
rm $DIR/dev.txt
rm $DIR/test.txt



