import os
import logging
import argparse
import torch
import gc
from trainer.load_model import load_model_and_tokenizer, load_unsloth_model_and_tokenizer
from user_login import user_login
from data_processing.load_data import load_and_prepare_unsloth_dataset, load_and_process_dataset
from trainer.train import create_SFT_trainer, train_and_save_model
from logger import CustomLogger



# 4bit pre quantized models we support for 4x faster downloading + no OOMs.
unsloth_fourbit_models = [
    "unsloth/Meta-Llama-3.1-8B-bnb-4bit",      # Llama-3.1 15 trillion tokens model 2x faster!
    "unsloth/Meta-Llama-3.1-8B-Instruct-bnb-4bit",
    "unsloth/Meta-Llama-3.1-70B-bnb-4bit",
    "unsloth/Meta-Llama-3.1-405B-bnb-4bit",    # We also uploaded 4bit for 405b!
    "unsloth/Mistral-Nemo-Base-2407-bnb-4bit", # New Mistral 12b 2x faster!
    "unsloth/Mistral-Nemo-Instruct-2407-bnb-4bit",
    "unsloth/mistral-7b-v0.3-bnb-4bit",        # Mistral v3 2x faster!
    "unsloth/mistral-7b-instruct-v0.3-bnb-4bit",
    "unsloth/Phi-3.5-mini-instruct",           # Phi-3.5 2x faster!
    "unsloth/Phi-3-medium-4k-instruct",
    "unsloth/gemma-2-9b-bnb-4bit",
    "unsloth/gemma-2-27b-bnb-4bit",            # Gemma 2x faster!
] # More models at https://huggingface.co/unsloth
    
# Main Execution
def main(args):
    
    model_type = args.model
    # Setup logging
    logger = CustomLogger(__name__, level=logging.DEBUG)

    # User login
    user_login(logger)
    
    # The base model
   
    embedding_model_name = "sentence-transformers/all-mpnet-base-v2"
    db_directory =  os.path.join("..","chroma_db")

    
    
    if model_type == "base":
        # Load model and tokenizer
        base_model = "meta-llama/Meta-Llama-3-8B-Instruct"  
        load_func = load_model_and_tokenizer
    else:
        # Load model and tokenizer
        base_model =   "unsloth/Meta-Llama-3.1-8B-bnb-4bit" 
        load_func = load_unsloth_model_and_tokenizer

    new_model = f"stf-{model_type}-Llama-3-8B-Instruct"  # The model name for saving
    logger.info(f"Loading base model: {base_model}")
    model, tokenizer, peft_config = load_func(base_model, logger=logger)
   
    # Load and process data
    if (model_type == "base"):
        dataset_name = os.path.join("..","data","train","mrd3_dataset.json")
        logger.info(f"Loading SFT dataset: {dataset_name}")
        dataset, _ = load_and_process_dataset(tokenizer, dataset_name, embedding_model_name, db_directory, logger)
    else:
        dataset_name = "yahma/alpaca-cleaned"
        logger.info(f"Loading SFT dataset: {dataset_name}")
        dataset = load_and_prepare_unsloth_dataset(tokenizer, dataset_name, logger)
    
    # Print an example of the training data
    logger.info("Example of training input --------")
    logger.info(dataset["train_demo"]["text"][0])
    
    # Create SFT trainer
    logger.info("Creating SFT trainer...")
    trainer = create_SFT_trainer(model, tokenizer, dataset["train_demo"], dataset["eval_demo"], 
                                    peft_config, push_to_hub=True,logger=logger,num_train_epochs=1 )

    # Train and save model, optionally pushing to Hugging Face hub
    train_and_save_model(trainer, new_model, push_to_hub=True, logger=logger)
    
    # Clean up memory
    del trainer
    gc.collect()
    torch.cuda.empty_cache()
    if(logger): logger.info("Cleaned up memory post-training.")


if __name__ == "__main__":
    
    # Parse arguments
    parser = argparse.ArgumentParser(description="Train a model using ORPO or SFT.")
    parser.add_argument("--model", choices=["base", "unsloth"], help="Training type: either 'orpo' or 'sft'")
    args = parser.parse_args()
    
    # Get the directory where the script is located
    script_dir = os.path.dirname(os.path.abspath(__file__))
    
    # Check if the current working directory is different from the script's directory
    if os.getcwd() != script_dir:
        os.chdir(script_dir)
        print(f"Working directory changed to script's directory: {script_dir}")
    
    
    main(args)
