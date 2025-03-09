from utils import reorder_sentence_headfinal, reorder_sentence_random, reorder_sentence
import spacy
import argparse
import spacy
from spacy.tokenizer import Tokenizer
from spacy.util import compile_infix_regex
import pandas as pd

def main(args):
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
    print(gpu)
    nlp = spacy.load("en_core_web_trf")
    nlp.tokenizer = custom_tokenizer(nlp)
    directory = args.directory
    nonditransitives = pd.read_csv(f'data/{directory}/nonditransitives/non-ditransitives.csv')
    length_manipulated = pd.DataFrame(columns = ["sentence", "short-first", "long-first", "random-first", "headfinal", "token_count"])
    length_manipulated.to_csv(f'data/{directory}/nonditransitives/length_manipulated.csv', index=False)
    for row in zip(nonditransitives['sentence'], nonditransitives['token_count']):
        sentence = str(row[0])
        doc = nlp(sentence)
        headfinal = reorder_sentence_headfinal(doc)
        random = reorder_sentence_random(doc)
        shortfirst = reorder_sentence(doc, True)
        longfirst = reorder_sentence(doc, False)
        new_row = [
            sentence,
            shortfirst,
            longfirst,
            random,
            headfinal,
            row[1]
        ]
        new_row = pd.DataFrame([new_row])
        new_row.to_csv(f'data/{directory}/nonditransitives/length_manipulated.csv', mode='a', header=False, index=False)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--directory", type=str, required=True, 
                        help = "train/test/dev")
    args = parser.parse_args()
    main(args)