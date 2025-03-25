import argparse
import os

from datasets import load_dataset


def main(args):
    train_file = args.train_file
    val_file = args.val_file
    dataset_name = args.name

    hf_token = os.getenv("HF_TOKEN")
    assert hf_token is not None, "Please set HF_TOKEN environment variable"

    data_files = {"train": train_file, "validation": val_file}
    dataset_args = {"keep_linebreaks": True}
    raw_datasets = load_dataset(
        "text",
        data_files=data_files,
        **dataset_args,
    )

    raw_datasets.push_to_hub(f"username/{dataset_name}", token=hf_token)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--train_file", type=str, required=True)
    parser.add_argument("--val_file", type=str, required=True)
    parser.add_argument("--name", type=str, required=True)
    args = parser.parse_args()
    main(args)