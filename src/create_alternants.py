import argparse
import os
import pathlib
import utils
import spacy
from spacy.tokenizer import Tokenizer
from spacy.util import compile_infix_regex
import pandas as pd

from collections import defaultdict, Counter
from minicons.utils import get_batch
from tqdm import tqdm
from transformers import AutoTokenizer, AutoModelForCausalLM
from minicons import scorer

tokenizer = AutoTokenizer.from_pretrained("meta-llama/Llama-3.2-1B")
model = AutoModelForCausalLM.from_pretrained("meta-llama/Llama-3.2-1B")
lm = scorer.IncrementalLMScorer(model = model, device="cuda", tokenizer = tokenizer)

def main(args):
    file_path = args.file_path
    output_path = args.output_path 

    def custom_tokenizer(nlp):
        inf = list(nlp.Defaults.infixes)               # Default infixes
        inf.remove(r"(?<=[0-9])[+\-\*^](?=[0-9-])")    # Remove the generic op between numbers or between a number and a -
        inf = tuple(inf)                               # Convert inf to tuple
        infixes = inf + tuple([r"(?<=[0-9])[+*^](?=[0-9-])", r"(?<=[0-9])-(?=-)"])  # Add the removed rule after subtracting (?<=[0-9])-(?=[0-9]) pattern
        infixes = [x for x in infixes if "-|–|—|--|---|——|~" not in x] # Remove - between letters rule
        infix_re = compile_infix_regex(infixes)

        return Tokenizer(nlp.vocab, prefix_search=nlp.tokenizer.prefix_search,
                                    suffix_search=nlp.tokenizer.suffix_search,
                                    infix_finditer=infix_re.finditer,
                                    token_match=nlp.tokenizer.token_match,
                                    rules=nlp.Defaults.tokenizer_exceptions)

    gpu = spacy.prefer_gpu()
    nlp = spacy.load("en_core_web_trf")
    nlp.tokenizer = custom_tokenizer(nlp)

    def create_alternant_from_pos(sentence, recipient, recipient_i, theme_i):
        doc = nlp(sentence)
        theme_to_rec = ""
        after_recipient = ""
        initial = ""
        recipient = str(recipient)
        recipient_length = nlp(recipient)[-1].i
        for entity in doc:
            if entity.i < theme_i:
                initial += entity.text_with_ws
            elif entity.i >= theme_i and entity.i < recipient_i - 1:
                theme_to_rec += entity.text_with_ws
            elif entity.i > recipient_i + recipient_length:
                after_recipient += entity.text_with_ws
        alternant = initial + recipient + ' ' +  theme_to_rec + after_recipient
        return alternant, len(doc)

    def create_alternant_from_dos(sentence, theme, recipient_i, theme_i, verb_type):
        initial = ""
        rec_to_theme = ""
        after_theme = ""
        theme_length = nlp(theme)[-1].i
        doc = nlp(sentence)
        for entity in doc:
            if entity.i < recipient_i:
                initial += entity.text_with_ws
            elif entity.i >= recipient_i and entity.i < theme_i:
                rec_to_theme += entity.text_with_ws
            elif entity.i > theme_i + theme_length:
                after_theme += entity.text_with_ws
        alternant = ''
        if verb_type == "benefactive_alternating":
            alternant = initial + theme + ' for ' + rec_to_theme + after_theme 
        else:
            to_alternant = initial + theme + ' to ' + rec_to_theme + after_theme
            for_alternant = initial + theme + ' for ' + rec_to_theme + after_theme
            alternant = rating_alternants(to_alternant, for_alternant, lm, tokenizer)
        return alternant, len(doc)

    def rating_alternants(to_alternant, for_alternant, lm, tokenizer):
        tokenized_to = tokenizer(to_alternant, return_tensors='pt', truncation=False)
        tokenized_for = tokenizer(for_alternant, return_tensors='pt', truncation=False)
        to_alternant_score = lm.score(tokenized_to)[0]
        for_alternant_score = lm.score(tokenized_for)[0]
        return to_alternant if to_alternant_score > for_alternant_score else for_alternant

    file = pd.read_csv(file_path)
    if args.type == "DO":
        for index, row in file.iterrows():
            alternant, tokens = create_alternant_from_dos(row["sentence"], row["theme"], row["recipient_i"], row["theme_i"], row["verb_type"])
            new_row = row.copy()
            new_row["alternant"] = alternant
            new_row = pd.DataFrame([new_row])
            new_row.to_csv(output_path, index=False, mode = 'a', header=not os.path.exists(output_path))
    elif args.type == "PO":
        for index, row in file.iterrows():
            alternant, tokens = create_alternant_from_pos(row["sentence"], row["recipient"], row["recipient_i"], row["theme_i"])
            new_row = row.copy()
            new_row["alternant"] = alternant
            new_row = pd.DataFrame([new_row])
            new_row.to_csv(output_path, index=False, mode = 'a', header=not os.path.exists(output_path))

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--file_path", type=str, help="Path to the corpus file.")
    parser.add_argument("--output_path", type=str, help="Path to the dative output.")
    parser.add_argument("--type", type=str, help="Type (DO or PO)")
    args = parser.parse_args()
    main(args)