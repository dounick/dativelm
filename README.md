# dativelm
Code for the paper ----

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
6. Train models using 
```
bash scripts/train_autoreg.sh DATASET BASE_MODEL MODEL_NAME LR SEED EPOCHS
```
Modify scripts/train_autoreg.sh to specify GPU and huggingface token.
