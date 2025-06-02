import csv
import os

file_name = "221029_17032023"

input_path = "data/v2/AI_Test/208"
output_path = input_path

input_file = file_name + ".raw"
output_file = file_name + ".csv"

with open(os.path.join(input_path, input_file), 'r', newline='') as infile, open(os.path.join(output_path, output_file), 'w', newline='') as outfile:
    reader = csv.reader(infile,delimiter='\t', skipinitialspace=True)
    writer = csv.writer(outfile, delimiter=',')
    for row in reader:
        print(row)
        writer.writerow(row)
    print(f"Successfully saved file under: {os.path.join(output_path, output_file)}")

print("End.")