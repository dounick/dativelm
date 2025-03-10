import pandas as pd

import csv
import os

nonditrans = 'data/train/nonditransitives/length_manipulated.csv'
nondative = 'data/train/nondatives/non-datives.csv'
loose_pos = 'data/train/datives/alternant_of_pos.csv'
loose_dos = 'data/train/datives/alternant_of_dos.csv'

types = ['short_first', 'random_first', 'long_first', 'headfinal']

max_tokens = 86418794
for model_name in types:
    os.mkdir(f'data/training_sets/{model_name}_noditransitive')
    output_file = f'data/training_sets/{model_name}_noditransitive/train.txt'
    current_tokens = 0
    current_nonditrans = 0

    with open(nonditrans, mode='r', newline='') as csvfile:
        csvreader = csv.DictReader(csvfile)
        with open(output_file, mode='a') as txtfile:
            for row in csvreader:
                if(current_tokens > max_tokens):
                    break
                txtfile.write(row[model_name] + '\n')
                current_tokens += int(row['token_count'])
                current_nonditrans += 1

    print(current_nonditrans)
    print(current_tokens)