#!/bin/bash

# Set the path to the Salmon index
salmon_index="GRCh38_salmon_index"

# Set the path to the "fastq" folder
fastq_dir="SRR"

# Loop through all the directories within the "fastq" folder
for dir in "${fastq_dir}"/SRR*; do
    # Find the R1 and R2 FASTQ files
    r1_file=$(find "$dir" -name "*_1.fastq.gz")
    r2_file=$(find "$dir" -name "*_2.fastq.gz")

    # Extract the sample name
    samp=$(basename "$dir")

    echo "Processing sample ${samp}"
    salmon quant -i "$salmon_index" -l A \
        -1 "$r1_file" \
        -2 "$r2_file" \
        -p 28 --validateMappings -o "salmon_out/${samp}_quant"
done
