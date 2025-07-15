# dativelm
Code and data for the COLM 2025 paper [**Both Direct and Indirect Evidence Contribute to Dative Alternation Preferences in Language Models**](https://arxiv.org/abs/2503.20850).

For experiments and analyses, see the analysis folder.

All datasets and models are available on huggingface:
- Model path: qing-yao/{**x**}_seed-{21,42,63}\_{1e-3}
- Dataset path: datasets/qing-yao/datives-{**x**}
  
where **x**∈{strict_default, loose_default, strict_balanced, loose_balanced, swapped-datives, no-datives, no-2postverbal, short-first, random-first, long-first, long-first-headfinal}.

The models can be retrained from the datasets with
```
bash scripts/train_autoreg.sh DATASET BASE_MODEL MODEL_NAME LR SEED EPOCHS
```
Make sure to modify scripts/train_autoreg.sh to specify GPU and huggingface token.

To detect datives and generate training sets from scratch:
1. Download BabyLM corpus without QED subtitles with 
```
bash scripts/get_babylm.sh
```
2. Detect datives, nondatives, nonditransitives using 
```
bash scripts/detect_datives.sh
```
3. Generate length manipulated versions of nonditransitives using 
```
bash scripts/length_manipulations.sh
```
4. Create unattested alternants to detected datives with 
```
bash scripts/create_alternants.sh data/train/datives
```
5. Write training sets for each model with 
```
bash scripts/write_train.sh
```
