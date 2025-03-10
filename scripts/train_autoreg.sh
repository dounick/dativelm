#!/bin/bash
export CUDA_VISIBLE_DEVICES=

DATASET=$1
BASE_MODEL=$2
MODEL_NAME=$3
LR=$4
SEED=$5
EPOCHS=$6

MODEL_NAME=${MODEL_NAME}_seed-${SEED}_${LR}

python src/modeling/tokenizer_and_config.py -b $BASE_MODEL \
    -m $MODEL_NAME \
    --word \
    --attention_heads 12 \
    --layers 12 \
    --hidden_size 768 \
    --intermediate_size 3072 \
    --vocab 32768 \
    --max_len 256 \
    --train_file $DATASET \
    --from_iterator

python src/modeling/train_autoreg.py \
    --config_name models/$MODEL_NAME \
    --tokenizer_name models/$MODEL_NAME \
    --per_device_train_batch_size 32 \
    --per_device_eval_batch_size 64 \
    --gradient_accumulation_steps 8 \
    --do_train \
    --do_eval \
    --token token \
    --dataset_name $DATASET \
    --evaluation_strategy epoch \
    --output_dir models/$MODEL_NAME \
    --overwrite_output_dir \
    --overwrite_cache \
    --learning_rate $LR \
    --early_stopping \
    --early_stopping_patience 3 \
    --weight_decay 0.1 \
    --save_total_limit 1 \
    --load_best_model_at_end \
    --block_size 256 \
    --num_train_epochs $EPOCHS \
    --save_strategy epoch \
    --logging_steps 1000 \
    --warmup_steps 32000 \
    --seed $SEED \
    --fp16 \
    --push_to_hub \
    --hub_model_id $MODEL_NAME \
    --hub_strategy end