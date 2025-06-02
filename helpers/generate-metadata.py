import os
import json
from importlib.metadata import metadata

import pandas as pd
import re
from datetime import datetime

input_path = "data/v2/AI_Test/195" # input directory
output_path = input_path # output directory

filename = "201253_25112022.csv" # input file


def main():
    validate_directories(input_path, output_path, filename)  # check input and output directories and input file

    origin_file_id = input("[INPUT] Name of connected Origin (.opj) file (optional):").strip()

    injections = input("[INPUT] Injections:").strip()


    #injection_types = get_injection_types() # get injection types and corresponding inj value
    #max_inj = max([a for b in injection_types.values() for a in b]) # max inj value

    try:
        df = pd.read_csv(os.path.join(input_path, filename))

        width = df.shape[1] # get number of columns
        height = df.shape[0] # get number of rows

        col_names = df.columns.tolist()[4:12] # get column names
        date = extract_date(filename) # extract date from filename

        if not max_inj == max(df["Inj_"]): print(f"[WARNING] The maximum injection value in the file ({max(df["Inj_"])}) does not match the maximum injection value from the injection type input ({max_inj}).")

        meta_data = {
            "raw": filename.removesuffix(".csv"),
            "origin_file_id": origin_file_id,
            "short_file_id": short_file_id,
            "date": date,
            "width": width,
            "height": height,
            "col_names": col_names,
            "injections": injections,
            "rounds": rounds,
        }

        json_filename = filename.removesuffix(".csv") + ".json"
        with open(json_filename, 'w', encoding='utf-8') as f:
            json.dump(meta_data, f, indent=2, ensure_ascii=False)

        print(f"[INFO] Successfully created metadata file: {json_filename}")

    except Exception as e:
        print(f"[ERROR] Unsuccessful handling of:{filename} \n {e}")

def validate_directories(input_dir, output_dir, file) -> None:
    if not os.path.exists(input_dir): raise FileNotFoundError(f"[ERROR] Could not find input directory: {input_dir}") # check for input path
    if not os.path.exists(os.path.join(input_dir, file)): raise FileNotFoundError(f"[ERROR] Could not find input file: {filename}") # check for input file

    if not os.path.exists(output_dir): # check for output path
        create_output_directory = input(f"[WARNING] Could not find output directory: {output_dir} \n Do you want to create output directory? (y/n):")
        if create_output_directory == "y":
            os.makedirs(output_dir)
            print(f"New directory for output created: {output_dir}")
        else: raise FileNotFoundError(f"[ERROR] Could not create output directory: {output_dir}")

def extract_date(file):
    match = re.search(r'_(\d{8})', file)
    if match:
        try:
            date_str = match.group(1)
            date_obj = datetime.strptime(date_str, '%Y%m%d')
            return date_obj.strftime('%Y-%m-%d')
        except ValueError:
            print(f"[WARNING] Could not extract date from {file}")
            if input("[INPUT] Do you want to manually enter the date? (y/n):") == 'y':
                usr_input_date = input("[INPUT] Enter the date in YYYY-MM-DD format:")
                try:
                    date_obj = datetime.strptime(usr_input_date, '%Y-%m-%d')
                    return date_obj.strftime('%Y-%m-%d')
                except ValueError:
                    print(f"[ERROR] Invalid date format: {usr_input_date}. Continuing without date.")
            else: print("[WARNING] Continuing without date.")
            return ""
    return ""

def get_injection_types():
    types = ["puffer", "negative", "positive", "urea"]
    injections = {}

    for inj_type in types:
        usr_input = input(f"[INPUT] Inj. no. of {inj_type} injections (separated by comma): ").strip()
        injections[inj_type] = ["Inj_" + inj.strip() for inj in usr_input.split(',') if inj.strip()]

    return injections

if __name__ == "__main__": main()
print("End.")