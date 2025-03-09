import pandas as pd

import csv
import os

nonditrans = 'data/datives/nonditransitives/headfinal'
nondative = 'data/datives/nondatives/non-datives_'
loose_pos = 'data/datives/babylm/loose_alternant_of_pos.csv'
loose_dos = 'data/datives/babylm/loose_alternant_of_dos.csv'

types = ['headfinal']

max_tokens = 86418794
for model_name in types:
    output_file = f'data/training_sets/long_first_headfinal/train.txt'
    current_tokens = 0
    current_nonditrans = 0
    for i in range(10):
        nonditrans_path = nonditrans + str(i) + '.csv'
        with open(nonditrans_path, mode='r', newline='') as csvfile:
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