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
