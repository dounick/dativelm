import pandas as pd

import csv
import os

nonditrans = 'data/train/nonditransitives/length_manipulated.csv'
nondative = 'data/train/nondatives/non-datives.csv'
loose_pos = 'data/train/datives/alternant_of_pos.csv'
loose_dos = 'data/train/datives/alternant_of_dos.csv'
os.mkdir('data/training_sets/noditrans_cf')
output_file = 'data/training_sets/noditrans_cf/train.txt'
max_tokens = 86418794
current_tokens = 0

# write counterfactual datives:
cf_dos = 1500
cf_pos = 750

curr_datives = 0
with open(loose_pos, mode='r', newline='') as csvfile:
    csvreader = csv.DictReader(csvfile)
    with open(output_file, mode='w') as txtfile:
        for i, row in enumerate(csvreader):
            if i < 32850: 
                continue
            if(curr_datives > cf_dos):
                break
            txtfile.write(row['alternant'] + '\n')
            current_tokens += int(row['token_count']) + 1
            curr_datives += 1

curr_datives = 0
with open(loose_dos, mode='r', newline='') as csvfile:
    csvreader = csv.DictReader(csvfile)
    with open(output_file, mode='a') as txtfile:
        for i, row in enumerate(csvreader):
            if i < 32850: 
                continue
            if(curr_datives > cf_pos):
                break
            txtfile.write(row['alternant'] + '\n')
            current_tokens += int(row['token_count']) - 1
            curr_datives += 1

print(current_tokens)
# write non-datives

current_nonditrans = 0
with open(nonditrans, mode='r', newline='') as csvfile:
    csvreader = csv.DictReader(csvfile)
    with open(output_file, mode='a') as txtfile:
        for row in csvreader:
            if(current_tokens > max_tokens):
                break
            txtfile.write(row['sentence'] + '\n')
            current_tokens += int(row['token_count'])
            current_nonditrans += 1

print(current_nonditrans)
print(current_tokens)