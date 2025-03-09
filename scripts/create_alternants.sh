#!/bin/bash
FILE_PATH=$1

FILE_PATH_DO=${FILE_PATH}/dos.csv
FILE_PATH_PO=${FILE_PATH}/pos.csv
OUTPUT_PATH_PO=${FILE_PATH}/alternant_of_pos.csv
OUTPUT_PATH_DO=${FILE_PATH}/alternant_of_dos.csv

python src/create_alternants.py \
    --file_path $FILE_PATH_PO \
    --output_path $OUTPUT_PATH_PO \
    --type PO

python src/create_alternants.py \
    --file_path $FILE_PATH_DO \
    --output_path $OUTPUT_PATH_DO \
    --type DO
