'''Sentence tokenizes the input corpus.'''
import argparse
from nltk.tokenize import sent_tokenize
from tqdm import tqdm
import re


def main(args):
    source = args.source
    target = args.target

    with open(source, "r") as f:
        sents = f.readlines()

    sentences = []
    for sent in tqdm(sents):
        sentences.extend(sent_tokenize(sent))

    with open(target, "w") as f:
        for sent in sentences:
            sent = re.sub(r'(?<=[.,!?])(?=[^\s])', r' ', sent)
            sent = sent.replace("–", "-").replace("—", "-")
            f.write(sent.replace("_", "") + "\n")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Tokenize sentences from raw text files"
    )
    parser.add_argument("--source", type=str, help="source file", required=True)
    parser.add_argument("--target", type=str, help="output file", required=True)
    args = parser.parse_args()
    main(args)