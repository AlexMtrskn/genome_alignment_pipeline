# CREATING MACHINE AND DOWNLOADING DATA FROM SRA
## Create VM https://console.cloud.google.com/compute/instances with at least 50Gb of Disk storage space. The rest settings could be left standard.
## Don't forget that Google cloud charge per use of VM, so if you don't need kill instance.
## Better to connect via SSH to terminal with Google secure Shell https://chromewebstore.google.com/detail/secure-shell/iodihamcpbpeioajjeobimgagajmlibd
## To create and add keys to VM https://cloud.google.com/compute/docs/connect/create-ssh-keys https://cloud.google.com/compute/docs/connect/add-ssh-keys
## SSH keys creates on your personal machine: public key goes to VM, private key you feed as a file to Google secure Shell


## Download -> wget https://ena-docs.readthedocs.io/en/latest/retrieval/file-download.html#using-wget
## SRR number of archive could be found by BioProject number, e.g https://www.ncbi.nlm.nih.gov/Traces/study/?acc=PRJNA905840&o=acc_s%3Aa
## Link to ftp could be find by SRR number https://sra-explorer.info/# 
## We use PRJNA905840 and 60 day experiments: FEZ1-KO(1) - SRR22423456, FEZ1-KO(2) - SRR22423457, WT(1) - SRR22423458, WT(1) - SRR22423459
## wget -i download_list.txt downloads for bulk download from list

touch download.sh
nano download.sh

--- download.sh --- 
#!/bin/bash

# Set the path to the "download" folder
dir="SRR"
dl="download_list.txt"
mkdir -p "$dir"

# Download full list
while read -r line
do
	echo "Downloading $line"
	# Extract the sample name
	filename=$(basename "$line")
	sample="${filename%%_*}"
	echo "Sample name $filename"
	# Create fownload folder if not exist
	mkdir -p "$dir/$sample"
	# Download file
	wget -P "$dir/$sample/" "$line"
	echo "Downloaded $filename"
done < "$dl"


--- end download.sh --- 

touch download_list.txt
nano download_list.txt

--- download_list.txt ---
ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR224/056/SRR22423456/SRR22423456_1.fastq.gz
ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR224/056/SRR22423456/SRR22423456_2.fastq.gz
ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR224/059/SRR22423459/SRR22423459_1.fastq.gz
ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR224/059/SRR22423459/SRR22423459_2.fastq.gz
ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR224/058/SRR22423458/SRR22423458_1.fastq.gz
ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR224/058/SRR22423458/SRR22423458_2.fastq.gz
ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR224/057/SRR22423457/SRR22423457_1.fastq.gz
ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR224/057/SRR22423457/SRR22423457_2.fastq.gz
--- end download_list.txt ---

bash download.sh

# INSTALL CONDA AND SALMON
## https://docs.vultr.com/how-to-install-anaconda-on-debian-12
## Installing necessary libs
sudo apt-get install libgl1-mesa-glx libegl1-mesa libxrandr2 libxrandr2 libxss1 libxcursor1 libxcomposite1 libasound2 libxi6 libxtst6 -y
## Download latest anaconda release https://repo.anaconda.com/archive/
wget -O anaconda.sh https://repo.anaconda.com/archive/Anaconda3-2024.10-1-Linux-x86_64.sh
## Run installation
bash anaconda.sh
## In dialog prompt press [ENTER], on terms and services [Q] and then [yes], [ENTER]
## After installation on question about autoactivation key [yes]
## Reload shell to start Anaconda
source ~/.bashrc 
## After reload you should see something like (base) in your command line
## Check succesfull installation, command conda --version should show you your version something like 'conda 24.9.2'
conda --version

## Installing Salmon and creating environment https://combine-lab.github.io/salmon/getting_started/
conda config --add channels conda-forge
conda config --add channels bioconda
conda create -n salmon salmon
conda activate salmon

# PSEUDOALIGNMENT WITH SALMON
## Prepare index https://combine-lab.github.io/alevin-tutorial/2019/selective-alignment/
## Genome assemblies could be find https://ftp.ebi.ac.uk/pub/databases/gencode/
## Select latest assemblies
curl -O https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_47/gencode.v47.transcripts.fa.gz
curl -O https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_47/GRCh38.primary_assembly.genome.fa.gz

grep "^>" <(gunzip -c GRCh38.primary_assembly.genome.fa.gz) | cut -d " " -f 1 > decoys.txt
sed -i -e 's/>//g' decoys.txt

cat gencode.v47.transcripts.fa.gz GRCh38.primary_assembly.genome.fa.gz > GRCH38_and_decoys.fa.gz

## At this step you need to switch your virtual machine to at least 32 Gb of RAM and 8 cores. It could be done by turning VM off and changing settings in VM console
## Making indexing file for pseudoalignment
salmon index -t GRCH38_and_decoys.fa.gz -d decoys.txt -p 16 -i GRCh38_salmon_index --gencode


## Run Salmon on one sample
## paired
salmon quant -i GRCh38_salmon_index/ -l A -1 path_to_R1.fastq.gz -2 path_to_R2.fastq.gz --validateMappings -o salmon_out/out_directory
## unstranded
salmon quant -i GRCh38_salmon_index/ -l A -r path_to.fastq.gz --validateMappings -o salmon_out/out_directory



## Start multiple file salmon script
touch multiple_salmon.sh
nano multiple_salmon.sh

--- multiple_salmon.sh ---
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
--- end multiple_salmon.sh ---
bash multiple_salmon.sh
