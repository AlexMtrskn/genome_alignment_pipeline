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
### insert content from 'download.sh'

touch download_list.txt
nano download_list.txt
### insert content from 'download_list.txt'

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
### insert content from 'multiple_salmon.sh'
bash multiple_salmon.sh
