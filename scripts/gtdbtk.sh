#!/bin/bash

genomes="./"
cpus=35
extension="fasta"
out_dir="out_dir"

display_help(){
    echo "Usage: $0 -g <genomes_directory> -c <cpus> -e <extension> -o <output_directory>" #$0 is the name of the script
    echo "Options:"
    echo "  -g   Genomes directory (default: ./)"
    echo "  -c   Number of CPUs (default: 35)"
    echo "  -e   File extension (default: fasta)"
    echo "  -o   Output directory (default: out_dir)"
    exit 1
}

while getopts ":g:c:e:o:" opt
do 
    case $opt in
        g) 
            genomes="$OPTARG"
            ;;
        c)
            cpus="$OPTARG"
            ;;
        e)  
            extension="$OPTARG"
            ;;
        o) 
            out_dir="$OPTARG"
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
    esac 
done

if [ "$#" -eq 0 ]
then 
    display_help
fi

if [ ! -d "$out_dir" ]
then 
    mkdir -p "$out_dir"
fi 

# Gene calling
echo "Executing gene calling..."
gtdbtk identify --genome_dir "${genomes}" --out_dir "${out_dir}/identify" --cpus "${cpus}" --extension "${extension}"

# Aligning genome 
echo "Executing aligning..."
gtdbtk align --identify_dir "${out_dir}/identify" --out_dir "${out_dir}/align" --cpus "${cpus}"

# Classification
echo "Executing classification..."
gtdbtk classify --genome_dir "${genomes}" --align_dir "${out_dir}/align" --out_dir "${out_dir}/classify" -x "${extension}" --cpus "${cpus}"
