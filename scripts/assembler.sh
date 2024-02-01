#!/bin/bash

fastq_reads="./"
cpus=$((35))
coverage=$((40))
out_dir="asm_out_dir"
genome_size=$((6))
min_length=$((1000))
min_q=$((16))
basecaller_model=""




display_help(){
    echo "Usage: $0 -i <pooled_fastq_directory> -c <cpus> -x <coverage> -g <genome_size> -o <output_directory> -l <minimum read length> -q <minimum read quality> -m <basecaller_model>"  #$0 is the name of the script
    echo "Options:"
    echo "  -i   Directory to pooled fastq files (default: ./)"
    echo "  -c   Number of CPUs (default: 35)"
    echo "  -x   Coverage, numeric (default: 40)"
    echo "  -g   Genome size, numeric (default: 6 million bp)"
    echo "  -l   Minimum read length, numeric (default: 1000)"
    echo "  -q   Minimum read quality, numeric (default: 16)"
    echo "  -m   Basecaller model (required)"
    echo "  -o   Output directory (default: out_dir)"
    exit 1
}

while getopts ":i:c:x:g:l:q:m:o:" opt
do 
    case $opt in
        i) 
            fastq_reads="$OPTARG"
            ;;
        c)
            cpus="$OPTARG"
            ;;
        x)
            coverage="$OPTARG"
            ;;
        g)
            genome_size="$OPTARG"
            ;;
        l)
            min_length="$OPTARG"
            ;;
        q)
            min_q="$OPTARG"
            ;;
        m)
            basecaller_model="$OPTARG"
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
    echo "$out_dir has been created!"
else
    echo "$out_dir already exists and I proceed to the next step!"
fi 



#------------------- filtering reads ---------
echo "Filtering reads... "
for i in "${fastq_reads}/"*.fastq
do 
    name=$(basename $i | cut -f 1 -d'.')
    NanoFilt -q "$min_q" -l "$min_length" $i > "${out_dir}/${name}_filt.fastq"

    if [ -f "${out_dir}/${name}_filt.fastq" ]
    then 
        rm -rf $i
    fi
done

echo "Filtering reads is done and I proceed to the assembly step!"
#---------- Running assembler on the new reads -------

echo "Asswembly..."

for i in "${out_dir}"/*_filt.fastq
do
    source ~/miniconda3/etc/profile.d/conda.sh
    out_name=$(basename $i | cut -f 1 -d'_')

    #running flye
    
    flye --nano-raw $i -t "$cpus" -i 2 --out-dir "${out_dir}/${out_name}"_flye  --asm-coverage "$coverage" -g "${genome_size}"m

    conda activate medaka
    #polishing
    mini_align -i $i -r "${out_dir}/${out_name}"_flye/assembly.fasta -P -m -p "${out_dir}/${out_name}"_flye/read_to_draft_$out_name -t "$cpus" 

    medaka consensus "${out_dir}/${out_name}"_flye/read_to_draft_$out_name.bam "${out_dir}/${out_name}"_flye/$out_name.hdf --model  r1041_e82_400bps_hac_variant_v4.3.0 --batch 200 --threads "$cpus" 

    medaka stitch "${out_dir}/${out_name}"_flye/$out_name.hdf  "${out_dir}/${out_name}"_flye/assembly.fasta "${out_dir}/${out_name}"_flye/"${out_dir}/${out_name}"_polished.fasta
    rm -rf "${out_dir}/${out_name}"_flye/*bam* "${out_dir}/${out_name}"_flye/*.hdf "${out_dir}/${out_name}"_flye/*.fai "${out_dir}/${out_name}"_flye/*.mmi "${out_dir}/${out_name}"_flye/*.bed
    conda deactivate 
    
done

mkdir -p "${out_dir}/polished_fasta" 

cp "${out_dir}/${out_name}"_flye/*polished.fasta "${out_dir}/polished_fasta" 

# Final message 

echo "your polished fasta files are ready in '${out_dir}/polished_fasta'.\n have a nice daytime temperature ;P"




