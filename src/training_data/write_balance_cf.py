import pandas as pd

import csv
import os

nonditrans = 'data/train/nonditransitives/length_manipulated.csv'
nondative = 'data/train/nondatives/non-datives.csv'
output_file = 'data/training_sets/loose_balanced_cf/train.txt'
os.mkdir('data/training_sets/loose_balanced_cf')
loose_pos = 'data/train/datives/alternant_of_pos.csv'
loose_dos = 'data/train/datives/alternant_of_dos.csv'

max_tokens = 86418794
max_datives = 65700 
current_tokens = 0
# write paired pos and dos balanced for features

curr_datives = 0
with open(loose_pos, mode='r', newline='') as csvfile:
    csvreader = csv.DictReader(csvfile)
    with open(output_file, mode='w') as txtfile:
        for i,row in enumerate(csvreader):
            if(curr_datives > max_datives):
                break
            txtfile.write(row['sentence'] + '\n')
            txtfile.write(row['alternant'] + '\n')
            current_tokens += 2*int(row['token_count'])-1
            curr_datives += 2

curr_datives = 0
with open(loose_dos, mode='r', newline='') as csvfile:
    csvreader = csv.DictReader(csvfile)
    with open(output_file, mode='a') as txtfile:
        for i,row in enumerate(csvreader):
            if(curr_datives > max_datives):
                break
            txtfile.write(row['sentence'] + '\n')
            txtfile.write(row['alternant'] + '\n')
            current_tokens += 2*int(row['token_count'])+1     
            curr_datives += 2       

print(current_tokens)
# write counterfactual datives:
cf_dos = 1500
cf_pos = 750

curr_datives = 0
with open(loose_pos, mode='r', newline='') as csvfile:
    csvreader = csv.DictReader(csvfile)
    with open(output_file, mode='a') as txtfile:
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

current_nondatives = 0

with open(nondative, mode='r', newline='') as csvfile:
    csvreader = csv.DictReader(csvfile)
    with open(output_file, mode='a') as txtfile:
        for row in csvreader:
            if(current_tokens > max_tokens):
                break
            txtfile.write(row['sentence'] + '\n')
            current_tokens += int(row['token_count'])
            current_nondatives += 1

print(current_nondatives)
print(current_tokens)