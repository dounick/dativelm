'''Sentence tokenizes the input corpus.'''
import argparse
from nltk.tokenize import sent_tokenize
from tqdm import tqdm


def main(args):
    source = args.source
    target = args.target

    with open(source, "r") as f:
        content = f.read()

    paragraphs = content.split('\n\n')  # Split by double line breaks to form paragraphs
    paragraphs = [paragraph.replace('\n', ' ') for paragraph in paragraphs]  # Remove all line breaks within each paragraph

    sentences = []
    for paragraph in tqdm(paragraphs):
        for sentence in sent_tokenize(paragraph):
            if any(char.isalnum() for char in sentence):
                sentences.append(sentence.strip())  # Remove any initial tabs/spaces

    with open(target, "w") as f:
        for sent in sentences:
            f.write(sent.replace("_", "") + "\n")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Tokenize sentences from raw text files"
    )
    parser.add_argument("--source", type=str, help="source file", required=True)
    parser.add_argument("--target", type=str, help="output file", required=True)
    args = parser.parse_args()
    main(args)