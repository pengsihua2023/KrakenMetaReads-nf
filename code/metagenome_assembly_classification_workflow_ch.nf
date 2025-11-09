#!/usr/bin/env nextflow

/*
 * Metagenome Assembly and Kraken2 Taxonomic Classification Workflow (English Version)
 * 
 * This workflow integrates:
 * 1. Quality control using fastp (optional)
 * 2. Metagenome assembly using MEGAHIT and SPAdes
 * 3. Taxonomic classification using Kraken2
 * 4. Comprehensive analysis merging results from both assemblers
 * 
 * Author: Assistant
 * Version: 2.5.0
 */

nextflow.enable.dsl = 2

// Workflow parameters
// Input data
params.input = null
params.outdir = './results'
params.help = false

// MAG parameters (simplified version without these features)
// params.skip_binning = true
// params.skip_checkm = true  
// params.skip_busco = true
// params.skip_prodigal = true
// params.skip_diamond = true
// params.skip_hmmer = true

// MEGAHIT parameters
params.megahit_memory = 0.8
params.megahit_min_contig_len = 1000

// SPAdes parameters (using metaSPAdes)
params.spades_meta = true

// fastp quality control parameters
params.skip_fastp = false
params.fastp_qualified_quality = 20    // Minimum quality value
params.fastp_unqualified_percent = 40  // Maximum percentage of low-quality bases allowed
params.fastp_min_length = 50           // Minimum read length

// Kraken2 classification parameters
params.kraken2_db = null

// Merge analysis parameters
params.skip_merge_reports = false  // Whether to skip comprehensive report generation

// Resource parameters
params.max_cpus = 32
params.max_memory = '256.GB'
params.max_time = '72.h'

// Print help information
if (params.help) {
    log.info """
    ==========================================
    Metagenome Assembly and Kraken2 Taxonomic Classification Workflow
    ==========================================
    
    Usage:
    nextflow run metagenome_assembly_classification_workflow_en.nf --input samplesheet_mag_tax.csv --outdir results --kraken2_db /path/to/db
    
    Parameters:
    --input                    Input samplesheet
    --outdir                   Output directory
    --kraken2_db              Kraken2 database path
    
    Example:
    nextflow run metagenome_assembly_classification_workflow_en.nf \\
        --input samplesheet_mag_tax.csv \\
        --outdir results \\
        --kraken2_db /path/to/kraken2/db
    """
    exit 0
}

// Validate required parameters
if (!params.input) {
    error "Input samplesheet is required. Use --input parameter."
}

if (!params.kraken2_db) {
    error "Kraken2 database path is required. Use --kraken2_db parameter."
}

// Print workflow information
log.info """
==========================================
🧬 Metagenome Assembly and Kraken2 Taxonomic Classification Workflow
==========================================
Workflow version: 2.5.0
Input samplesheet: ${params.input}
Output directory: ${params.outdir}
Kraken2 database: ${params.kraken2_db}
==========================================
"""

// Create input channel from CSV samplesheet
Channel
    .fromPath(params.input)
    .splitCsv(header: true)
    .map { row -> 
        def sample = row.sample
        def read1 = file(row.fastq_1)
        def read2 = file(row.fastq_2)
        return tuple(sample, [read1, read2])
    }
    .set { ch_reads }

// Define workflow
workflow {
    // Stage 0: Quality Control (optional)
    if (!params.skip_fastp) {
        FASTP (
            ch_reads
        )
        ch_clean_reads = FASTP.out.clean_reads
    } else {
        ch_clean_reads = ch_reads
    }
    
    // Stage 1: Assembly
    MEGAHIT_ASSEMBLY (
        ch_clean_reads
    )
    
    SPADES_ASSEMBLY (
        ch_clean_reads
    )
    
    // Stage 2: Mapping reads back to contigs for abundance calculation
    // 为MEGAHIT contigs建立索引
    BOWTIE2_BUILD_MEGAHIT (
        MEGAHIT_ASSEMBLY.out.contigs
    )
    
    // 为SPAdes contigs建立索引
    BOWTIE2_BUILD_SPADES (
        SPADES_ASSEMBLY.out.contigs
    )
    
    // 将clean reads比对到MEGAHIT contigs
    BOWTIE2_ALIGN_MEGAHIT (
        ch_clean_reads.join(BOWTIE2_BUILD_MEGAHIT.out.index)
    )
    
    // 将clean reads比对到SPAdes contigs
    BOWTIE2_ALIGN_SPADES (
        ch_clean_reads.join(BOWTIE2_BUILD_SPADES.out.index)
    )
    
    // 计算MEGAHIT的RPM和RPKM
    CALCULATE_ABUNDANCE_MEGAHIT (
        BOWTIE2_ALIGN_MEGAHIT.out.bam.join(MEGAHIT_ASSEMBLY.out.contigs)
    )
    
    // 计算SPAdes的RPM和RPKM
    CALCULATE_ABUNDANCE_SPADES (
        BOWTIE2_ALIGN_SPADES.out.bam.join(SPADES_ASSEMBLY.out.contigs)
    )
    
    // Stage 3: Kraken2 Classification
    KRAKEN2_CLASSIFICATION_MEGAHIT (
        MEGAHIT_ASSEMBLY.out.contigs,
        params.kraken2_db
    )
    
    KRAKEN2_CLASSIFICATION_SPADES (
        SPADES_ASSEMBLY.out.contigs,
        params.kraken2_db
    )
    
    // Stage 4: Merge Reports (Comprehensive Analysis)
    if (!params.skip_merge_reports) {
        // Merge MEGAHIT and SPAdes reports for the same sample
        KRAKEN2_CLASSIFICATION_MEGAHIT.out.kraken2_megahit
            .join(KRAKEN2_CLASSIFICATION_SPADES.out.kraken2_spades)
            .set { ch_reports_to_merge }
        
        MERGE_KRAKEN2_REPORTS (
            ch_reports_to_merge
        )
    }
}

// ================================================================================
// Process Definitions
// ================================================================================

// Process: fastp Quality Control
process FASTP {
    tag "${sample}"
    label 'process_medium'
    conda 'bioconda::fastp=0.23.4'
    publishDir "${params.outdir}/fastp", mode: 'copy', pattern: "*.{html,json}"
    
    input:
    tuple val(sample), path(reads)
    
    output:
    tuple val(sample), path("${sample}_clean_R{1,2}.fastq.gz"), emit: clean_reads
    path("${sample}_fastp.html"), emit: html
    path("${sample}_fastp.json"), emit: json
    
    script:
    def read1 = reads[0]
    def read2 = reads[1]
    """
    echo "=== fastp Quality Control: ${sample} ==="
    
    # List input files for debugging
    echo "Input files in work directory:"
    ls -lh
    
    fastp \\
        -i ${read1} \\
        -I ${read2} \\
        -o ${sample}_clean_R1.fastq.gz \\
        -O ${sample}_clean_R2.fastq.gz \\
        --thread ${task.cpus} \\
        --qualified_quality_phred ${params.fastp_qualified_quality} \\
        --unqualified_percent_limit ${params.fastp_unqualified_percent} \\
        --length_required ${params.fastp_min_length} \\
        --detect_adapter_for_pe \\
        --compression 6 \\
        --html ${sample}_fastp.html \\
        --json ${sample}_fastp.json
    
    echo "fastp: Quality control completed for ${sample}"
    """
}

// Process: MEGAHIT Assembly
process MEGAHIT_ASSEMBLY {
    tag "${sample}_MEGAHIT"
    label 'process_high'
    container 'docker://quay.io/biocontainers/megahit:1.2.9--h2e03b76_1'
    
    input:
    tuple val(sample), path(reads)
    
    output:
    tuple val(sample), path("megahit_contigs.fa"), emit: contigs
    
    script:
    """
    echo "=== MEGAHIT Assembly: ${sample} ==="
    
    megahit \
        -1 ${reads[0]} \
        -2 ${reads[1]} \
        -o megahit_output \
        -t ${task.cpus} \
        --memory ${params.megahit_memory} \
        --min-contig-len ${params.megahit_min_contig_len}
    
    cp megahit_output/final.contigs.fa megahit_contigs.fa
    
    echo "MEGAHIT: Generated \$(grep -c ">" megahit_contigs.fa) contigs"
    """
}

// Process: SPAdes Assembly
process SPADES_ASSEMBLY {
    tag "${sample}_SPAdes"
    label 'process_high'
    container 'docker://quay.io/biocontainers/spades:3.15.5--h95f258a_1'
    
    input:
    tuple val(sample), path(reads)
    
    output:
    tuple val(sample), path("spades_contigs.fa"), emit: contigs
    
    script:
    """
    echo "=== metaSPAdes Assembly: ${sample} ==="
    
    # Use metaSPAdes, disable error correction to avoid memory and bug issues
    metaspades.py \
        -1 ${reads[0]} \
        -2 ${reads[1]} \
        -o spades_output \
        -t ${task.cpus} \
        -m ${task.memory.toGiga()} \
        --only-assembler
    
    cp spades_output/contigs.fasta spades_contigs.fa
    
    echo "metaSPAdes: Generated \$(grep -c ">" spades_contigs.fa) contigs"
    """
}

// Process: 为MEGAHIT contigs建立Bowtie2索引
process BOWTIE2_BUILD_MEGAHIT {
    tag "${sample}_MEGAHIT"
    label 'process_medium'
    container 'docker://quay.io/biocontainers/bowtie2:2.5.1--py310h8d7afc0_0'
    
    input:
    tuple val(sample), path(contigs)
    
    output:
    tuple val(sample), path("megahit_index*"), emit: index
    
    script:
    """
    echo "=== Building Bowtie2 Index for MEGAHIT contigs: ${sample} ==="
    
    bowtie2-build \
        --threads ${task.cpus} \
        ${contigs} \
        megahit_index
    
    echo "Bowtie2 index built for MEGAHIT contigs"
    """
}

// Process: 为SPAdes contigs建立Bowtie2索引
process BOWTIE2_BUILD_SPADES {
    tag "${sample}_SPAdes"
    label 'process_medium'
    container 'docker://quay.io/biocontainers/bowtie2:2.5.1--py310h8d7afc0_0'
    
    input:
    tuple val(sample), path(contigs)
    
    output:
    tuple val(sample), path("spades_index*"), emit: index
    
    script:
    """
    echo "=== Building Bowtie2 Index for SPAdes contigs: ${sample} ==="
    
    bowtie2-build \
        --threads ${task.cpus} \
        ${contigs} \
        spades_index
    
    echo "Bowtie2 index built for SPAdes contigs"
    """
}

// Process: 将reads比对到MEGAHIT contigs
process BOWTIE2_ALIGN_MEGAHIT {
    tag "${sample}_MEGAHIT"
    label 'process_high'
    container 'docker://quay.io/biocontainers/mulled-v2-ac74a7f02cebcfcc07d8e8d1d750af9c83b4d45a:a0ffedb52808e102887f6ce600d092675bf3528a-0'
    
    input:
    tuple val(sample), path(reads), path(index)
    
    output:
    tuple val(sample), path("${sample}_megahit.sorted.bam"), path("${sample}_megahit.sorted.bam.bai"), emit: bam
    
    script:
    """
    echo "=== Aligning reads to MEGAHIT contigs: ${sample} ==="
    
    # 比对reads到contigs
    bowtie2 \
        -x megahit_index \
        -1 ${reads[0]} \
        -2 ${reads[1]} \
        --threads ${task.cpus} \
        --no-unal \
        | samtools view -bS - \
        | samtools sort -@ ${task.cpus} -o ${sample}_megahit.sorted.bam
    
    # 建立索引
    samtools index ${sample}_megahit.sorted.bam
    
    echo "Alignment to MEGAHIT contigs completed"
    """
}

// Process: 将reads比对到SPAdes contigs
process BOWTIE2_ALIGN_SPADES {
    tag "${sample}_SPAdes"
    label 'process_high'
    container 'docker://quay.io/biocontainers/mulled-v2-ac74a7f02cebcfcc07d8e8d1d750af9c83b4d45a:a0ffedb52808e102887f6ce600d092675bf3528a-0'
    
    input:
    tuple val(sample), path(reads), path(index)
    
    output:
    tuple val(sample), path("${sample}_spades.sorted.bam"), path("${sample}_spades.sorted.bam.bai"), emit: bam
    
    script:
    """
    echo "=== Aligning reads to SPAdes contigs: ${sample} ==="
    
    # 比对reads到contigs
    bowtie2 \
        -x spades_index \
        -1 ${reads[0]} \
        -2 ${reads[1]} \
        --threads ${task.cpus} \
        --no-unal \
        | samtools view -bS - \
        | samtools sort -@ ${task.cpus} -o ${sample}_spades.sorted.bam
    
    # 建立索引
    samtools index ${sample}_spades.sorted.bam
    
    echo "Alignment to SPAdes contigs completed"
    """
}

// Process: 计算MEGAHIT contigs的RPM和RPKM
process CALCULATE_ABUNDANCE_MEGAHIT {
    tag "${sample}_MEGAHIT"
    label 'process_low'
    conda 'conda-forge::python=3.10 bioconda::samtools=1.17 conda-forge::biopython=1.81'
    publishDir "${params.outdir}/abundance_megahit", mode: 'copy', pattern: "*"
    
    input:
    tuple val(sample), path(bam), path(bai), path(contigs)
    
    output:
    tuple val(sample), path("${sample}_megahit_abundance.txt"), emit: abundance
    path("${sample}_megahit_abundance_summary.txt"), emit: summary
    
    script:
    """
    #!/usr/bin/env bash
    
    # 设置软链接解决libbz2.so.1.0缺失问题
    echo "=== 设置库文件软链接 ==="
    mkdir -p \$HOME/.local/lib_tmp
    
    # 查找系统中的libbz2.so并创建软链接
    for libdir in /usr/lib /usr/lib64 /lib /lib64 /usr/lib/x86_64-linux-gnu; do
        if [ -f "\$libdir/libbz2.so.1" ]; then
            ln -sf "\$libdir/libbz2.so.1" \$HOME/.local/lib_tmp/libbz2.so.1.0
            echo "找到并链接: \$libdir/libbz2.so.1"
            break
        elif [ -f "\$libdir/libbz2.so" ]; then
            ln -sf "\$libdir/libbz2.so" \$HOME/.local/lib_tmp/libbz2.so.1.0
            echo "找到并链接: \$libdir/libbz2.so"
            break
        fi
    done
    
    export LD_LIBRARY_PATH=\$HOME/.local/lib_tmp:\$LD_LIBRARY_PATH
    echo "LD_LIBRARY_PATH已设置"
    
    # 执行Python脚本
    python3 << 'PYTHON_SCRIPT'
import subprocess
from Bio import SeqIO
from collections import defaultdict

print("=== 计算MEGAHIT contigs的RPM和RPKM: ${sample} ===")

# 1. 获取每个contig的长度
contig_lengths = {}
for record in SeqIO.parse("${contigs}", "fasta"):
    contig_lengths[record.id] = len(record.seq)

print(f"总共有 {len(contig_lengths)} 个contigs")

# 2. 使用samtools idxstats统计每个contig的mapped reads数
print("运行samtools idxstats...")
try:
    idxstats_output = subprocess.check_output(
        ["samtools", "idxstats", "${bam}"],
        universal_newlines=True,
        stderr=subprocess.PIPE
    )
except subprocess.CalledProcessError as e:
    print(f"错误: samtools idxstats执行失败")
    print(f"错误信息: {e.stderr}")
    raise

contig_reads = {}
total_mapped_reads = 0

for line in idxstats_output.strip().split('\\n'):
    parts = line.split('\\t')
    if len(parts) >= 3:
        contig_name = parts[0]
        mapped_reads = int(parts[2])
        
        if contig_name != "*":  # 跳过未比对的reads统计
            contig_reads[contig_name] = mapped_reads
            total_mapped_reads += mapped_reads

print(f"总mapped reads数: {total_mapped_reads}")

# 3. 计算RPM和RPKM
with open("${sample}_megahit_abundance.txt", 'w') as out_f:
    # 写入表头
    out_f.write("Contig_ID\\tLength(bp)\\tMapped_Reads\\tRPM\\tRPKM\\n")
    
    for contig_name in sorted(contig_lengths.keys()):
        length = contig_lengths[contig_name]
        reads = contig_reads.get(contig_name, 0)
        
        # 计算RPM (Reads Per Million)
        rpm = (reads / total_mapped_reads * 1e6) if total_mapped_reads > 0 else 0
        
        # 计算RPKM (Reads Per Kilobase per Million)
        rpkm = (reads / (length / 1000) / (total_mapped_reads / 1e6)) if total_mapped_reads > 0 and length > 0 else 0
        
        out_f.write(f"{contig_name}\\t{length}\\t{reads}\\t{rpm:.4f}\\t{rpkm:.4f}\\n")

# 4. 生成汇总统计
with open("${sample}_megahit_abundance_summary.txt", 'w') as sum_f:
    sum_f.write("="*80 + "\\n")
    sum_f.write("MEGAHIT Contigs 丰度统计汇总\\n")
    sum_f.write("="*80 + "\\n\\n")
    sum_f.write(f"样本名称: ${sample}\\n")
    sum_f.write(f"Contigs总数: {len(contig_lengths)}\\n")
    sum_f.write(f"总mapped reads数: {total_mapped_reads:,}\\n")
    if len(contig_lengths) > 0:
        sum_f.write(f"平均contig长度: {sum(contig_lengths.values()) / len(contig_lengths):.2f} bp\\n")
        sum_f.write(f"最长contig: {max(contig_lengths.values()):,} bp\\n")
        sum_f.write(f"最短contig: {min(contig_lengths.values()):,} bp\\n")
    sum_f.write("\\n" + "="*80 + "\\n")

print(f"丰度计算完成: ${sample} (MEGAHIT)")
PYTHON_SCRIPT
    """
}

// Process: 计算SPAdes contigs的RPM和RPKM
process CALCULATE_ABUNDANCE_SPADES {
    tag "${sample}_SPAdes"
    label 'process_low'
    conda 'conda-forge::python=3.10 bioconda::samtools=1.17 conda-forge::biopython=1.81'
    publishDir "${params.outdir}/abundance_spades", mode: 'copy', pattern: "*"
    
    input:
    tuple val(sample), path(bam), path(bai), path(contigs)
    
    output:
    tuple val(sample), path("${sample}_spades_abundance.txt"), emit: abundance
    path("${sample}_spades_abundance_summary.txt"), emit: summary
    
    script:
    """
    #!/usr/bin/env bash
    
    # 设置软链接解决libbz2.so.1.0缺失问题
    echo "=== 设置库文件软链接 ==="
    mkdir -p \$HOME/.local/lib_tmp
    
    # 查找系统中的libbz2.so并创建软链接
    for libdir in /usr/lib /usr/lib64 /lib /lib64 /usr/lib/x86_64-linux-gnu; do
        if [ -f "\$libdir/libbz2.so.1" ]; then
            ln -sf "\$libdir/libbz2.so.1" \$HOME/.local/lib_tmp/libbz2.so.1.0
            echo "找到并链接: \$libdir/libbz2.so.1"
            break
        elif [ -f "\$libdir/libbz2.so" ]; then
            ln -sf "\$libdir/libbz2.so" \$HOME/.local/lib_tmp/libbz2.so.1.0
            echo "找到并链接: \$libdir/libbz2.so"
            break
        fi
    done
    
    export LD_LIBRARY_PATH=\$HOME/.local/lib_tmp:\$LD_LIBRARY_PATH
    echo "LD_LIBRARY_PATH已设置"
    
    # 执行Python脚本
    python3 << 'PYTHON_SCRIPT'
import subprocess
from Bio import SeqIO
from collections import defaultdict

print("=== 计算SPAdes contigs的RPM和RPKM: ${sample} ===")

# 1. 获取每个contig的长度
contig_lengths = {}
for record in SeqIO.parse("${contigs}", "fasta"):
    contig_lengths[record.id] = len(record.seq)

print(f"总共有 {len(contig_lengths)} 个contigs")

# 2. 使用samtools idxstats统计每个contig的mapped reads数
print("运行samtools idxstats...")
try:
    idxstats_output = subprocess.check_output(
        ["samtools", "idxstats", "${bam}"],
        universal_newlines=True,
        stderr=subprocess.PIPE
    )
except subprocess.CalledProcessError as e:
    print(f"错误: samtools idxstats执行失败")
    print(f"错误信息: {e.stderr}")
    raise

contig_reads = {}
total_mapped_reads = 0

for line in idxstats_output.strip().split('\\n'):
    parts = line.split('\\t')
    if len(parts) >= 3:
        contig_name = parts[0]
        mapped_reads = int(parts[2])
        
        if contig_name != "*":  # 跳过未比对的reads统计
            contig_reads[contig_name] = mapped_reads
            total_mapped_reads += mapped_reads

print(f"总mapped reads数: {total_mapped_reads}")

# 3. 计算RPM和RPKM
with open("${sample}_spades_abundance.txt", 'w') as out_f:
    # 写入表头
    out_f.write("Contig_ID\\tLength(bp)\\tMapped_Reads\\tRPM\\tRPKM\\n")
    
    for contig_name in sorted(contig_lengths.keys()):
        length = contig_lengths[contig_name]
        reads = contig_reads.get(contig_name, 0)
        
        # 计算RPM (Reads Per Million)
        rpm = (reads / total_mapped_reads * 1e6) if total_mapped_reads > 0 else 0
        
        # 计算RPKM (Reads Per Kilobase per Million)
        rpkm = (reads / (length / 1000) / (total_mapped_reads / 1e6)) if total_mapped_reads > 0 and length > 0 else 0
        
        out_f.write(f"{contig_name}\\t{length}\\t{reads}\\t{rpm:.4f}\\t{rpkm:.4f}\\n")

# 4. 生成汇总统计
with open("${sample}_spades_abundance_summary.txt", 'w') as sum_f:
    sum_f.write("="*80 + "\\n")
    sum_f.write("SPAdes Contigs 丰度统计汇总\\n")
    sum_f.write("="*80 + "\\n\\n")
    sum_f.write(f"样本名称: ${sample}\\n")
    sum_f.write(f"Contigs总数: {len(contig_lengths)}\\n")
    sum_f.write(f"总mapped reads数: {total_mapped_reads:,}\\n")
    if len(contig_lengths) > 0:
        sum_f.write(f"平均contig长度: {sum(contig_lengths.values()) / len(contig_lengths):.2f} bp\\n")
        sum_f.write(f"最长contig: {max(contig_lengths.values()):,} bp\\n")
        sum_f.write(f"最短contig: {min(contig_lengths.values()):,} bp\\n")
    sum_f.write("\\n" + "="*80 + "\\n")

print(f"丰度计算完成: ${sample} (SPAdes)")
PYTHON_SCRIPT
    """
}

// Process: Kraken2 Classification for MEGAHIT
process KRAKEN2_CLASSIFICATION_MEGAHIT {
    tag "${sample}_MEGAHIT"
    label 'process_medium'
    conda 'bioconda::kraken2=2.1.3'
    publishDir "${params.outdir}/kraken2_megahit", mode: 'copy', pattern: "*"
    
    input:
    tuple val(sample), path(contigs)
    val(kraken2_db)
    
    output:
    tuple val(sample), path("${sample}_megahit_*.txt"), emit: kraken2_megahit
    
    script:
    """
    echo "=== Kraken2 Classification (MEGAHIT): ${sample} ==="
    
    echo "Running Kraken2 on MEGAHIT contigs..."
    kraken2 \
        --db ${kraken2_db} \
        --threads ${task.cpus} \
        --output ${sample}_megahit_classification.txt \
        --report ${sample}_megahit_report.txt \
        ${contigs}
    
    echo "Kraken2 classification completed for ${sample} (MEGAHIT)"
    """
}

// Process: Kraken2 Classification for SPAdes
process KRAKEN2_CLASSIFICATION_SPADES {
    tag "${sample}_SPAdes"
    label 'process_medium'
    conda 'bioconda::kraken2=2.1.3'
    publishDir "${params.outdir}/kraken2_spades", mode: 'copy', pattern: "*"
    
    input:
    tuple val(sample), path(contigs)
    val(kraken2_db)
    
    output:
    tuple val(sample), path("${sample}_spades_*.txt"), emit: kraken2_spades
    
    script:
    """
    echo "=== Kraken2 Classification (SPAdes): ${sample} ==="
    
    echo "Running Kraken2 on SPAdes contigs..."
    kraken2 \
        --db ${kraken2_db} \
        --threads ${task.cpus} \
        --output ${sample}_spades_classification.txt \
        --report ${sample}_spades_report.txt \
        ${contigs}
    
    echo "Kraken2 classification completed for ${sample} (SPAdes)"
    """
}

// Process: Merge Kraken2 Reports (Comprehensive Analysis)
process MERGE_KRAKEN2_REPORTS {
    tag "${sample}"
    label 'process_low'
    publishDir "${params.outdir}/merged_reports", mode: 'copy', pattern: "*"
    
    input:
    tuple val(sample), path(megahit_reports), path(spades_reports)
    
    output:
    tuple val(sample), path("${sample}_merged_report.txt"), emit: merged_report
    path("${sample}_merged_report.csv"), emit: merged_csv
    
    script:
    """
    #!/usr/bin/env python3
    # -*- coding: utf-8 -*-
    
    import pandas as pd
    from collections import defaultdict
    
    def parse_kraken2_report(file_path):
        # Parse Kraken2 report file
        data = []
        with open(file_path, 'r') as f:
            for line in f:
                parts = line.strip().split('\\t')
                if len(parts) >= 6:
                    percent = float(parts[0])
                    reads = int(parts[1])
                    direct_reads = int(parts[2])
                    rank = parts[3]
                    tax_id = parts[4]
                    name = parts[5]
                    
                    data.append({
                        'percent': percent,
                        'reads': reads,
                        'direct_reads': direct_reads,
                        'rank': rank,
                        'tax_id': tax_id,
                        'name': name.strip()
                    })
        
        return pd.DataFrame(data)
    
    # Find report files
    megahit_report = [f for f in "${megahit_reports}".split() if f.endswith('_report.txt')][0]
    spades_report = [f for f in "${spades_reports}".split() if f.endswith('_report.txt')][0]
    
    print(f"Parsing MEGAHIT report: {megahit_report}")
    megahit_df = parse_kraken2_report(megahit_report)
    
    print(f"Parsing SPAdes report: {spades_report}")
    spades_df = parse_kraken2_report(spades_report)
    
    # Merge reports
    spades_df.columns = [f'spades_{col}' if col not in ['tax_id', 'name', 'rank'] else col 
                         for col in spades_df.columns]
    megahit_df.columns = [f'megahit_{col}' if col not in ['tax_id', 'name', 'rank'] else col 
                          for col in megahit_df.columns]
    
    merged = pd.merge(spades_df, megahit_df, 
                     on=['tax_id', 'rank'], 
                     how='outer', 
                     suffixes=('_spades', '_megahit'))
    
    merged = merged.fillna(0)
    
    if 'name_spades' in merged.columns and 'name_megahit' in merged.columns:
        merged['name'] = merged['name_spades'].where(
            merged['name_spades'] != 0, 
            merged['name_megahit']
        )
        merged = merged.drop(['name_spades', 'name_megahit'], axis=1)
    
    # Generate text report
    with open("${sample}_merged_report.txt", 'w', encoding='utf-8') as f:
        f.write("="*80 + "\\n")
        f.write("Kraken2 Comprehensive Analysis Report - MEGAHIT vs SPAdes Assembly\\n")
        f.write("="*80 + "\\n\\n")
        
        # Overall statistics
        f.write("[Overall Statistics]\\n")
        f.write("-"*80 + "\\n")
        
        total_spades = merged['spades_reads'].sum()
        total_megahit = merged['megahit_reads'].sum()
        
        f.write(f"SPAdes total contigs:     {total_spades:,.1f}\\n")
        f.write(f"MEGAHIT total contigs:    {total_megahit:,.1f}\\n\\n")
        
        # Unclassified statistics
        unclass_spades = merged[merged['rank']=='U']['spades_reads'].sum()
        unclass_megahit = merged[merged['rank']=='U']['megahit_reads'].sum()
        
        f.write(f"SPAdes unclassified:      {unclass_spades:,.1f} ({unclass_spades/total_spades*100:.2f}%)\\n")
        f.write(f"MEGAHIT unclassified:     {unclass_megahit:,.1f} ({unclass_megahit/total_megahit*100:.2f}%)\\n\\n")
        
        # Virus classification statistics
        virus_rows = merged[merged['name'].str.contains('Viruses', na=False)]
        if not virus_rows.empty:
            virus_spades = virus_rows['spades_reads'].sum()
            virus_megahit = virus_rows['megahit_reads'].sum()
            
            f.write(f"SPAdes virus classified:  {virus_spades:,.1f} ({virus_spades/total_spades*100:.2f}%)\\n")
            f.write(f"MEGAHIT virus classified: {virus_megahit:,.1f} ({virus_megahit/total_megahit*100:.2f}%)\\n\\n")
        
        # Species level comparison
        f.write("\\n[Species Level Comparison]\\n")
        f.write("-"*80 + "\\n")
        f.write(f"{'Species Name':<50} {'SPAdes':<12} {'MEGAHIT':<12}\\n")
        f.write("-"*80 + "\\n")
        
        species_df = merged[merged['rank'].str.startswith('S', na=False)].copy()
        species_df['total_reads'] = species_df['spades_reads'] + species_df['megahit_reads']
        species_df = species_df.sort_values('total_reads', ascending=False)
        
        for _, row in species_df.head(30).iterrows():
            name = row['name'][:50]
            spades_r = int(row['spades_reads'])
            megahit_r = int(row['megahit_reads'])
            
            if spades_r > 0 or megahit_r > 0:
                f.write(f"{name:<50} {spades_r:<12} {megahit_r:<12}\\n")
        
        # Genus level comparison
        f.write("\\n[Genus Level Comparison]\\n")
        f.write("-"*80 + "\\n")
        f.write(f"{'Genus Name':<50} {'SPAdes':<12} {'MEGAHIT':<12}\\n")
        f.write("-"*80 + "\\n")
        
        genus_df = merged[merged['rank']=='G'].copy()
        genus_df['total_reads'] = genus_df['spades_reads'] + genus_df['megahit_reads']
        genus_df = genus_df.sort_values('total_reads', ascending=False)
        
        for _, row in genus_df.head(20).iterrows():
            name = row['name'][:50]
            spades_r = int(row['spades_reads'])
            megahit_r = int(row['megahit_reads'])
            
            if spades_r > 0 or megahit_r > 0:
                f.write(f"{name:<50} {spades_r:<12} {megahit_r:<12}\\n")
        
        # Family level comparison
        f.write("\\n[Family Level Comparison]\\n")
        f.write("-"*80 + "\\n")
        f.write(f"{'Family Name':<50} {'SPAdes':<12} {'MEGAHIT':<12}\\n")
        f.write("-"*80 + "\\n")
        
        family_df = merged[merged['rank']=='F'].copy()
        family_df['total_reads'] = family_df['spades_reads'] + family_df['megahit_reads']
        family_df = family_df.sort_values('total_reads', ascending=False)
        
        for _, row in family_df.head(15).iterrows():
            name = row['name'][:50]
            spades_r = int(row['spades_reads'])
            megahit_r = int(row['megahit_reads'])
            
            if spades_r > 0 or megahit_r > 0:
                f.write(f"{name:<50} {spades_r:<12} {megahit_r:<12}\\n")
        
        # Unique findings
        f.write("\\n[Unique Findings]\\n")
        f.write("-"*80 + "\\n\\n")
        
        # SPAdes-only species
        spades_only = species_df[(species_df['spades_reads'] > 0) & (species_df['megahit_reads'] == 0)].copy()
        spades_only = spades_only.sort_values('spades_reads', ascending=False)
        
        f.write("Species found only in SPAdes (Top 10):\\n")
        for _, row in spades_only.head(10).iterrows():
            name = row['name']
            count = int(row['spades_reads'])
            f.write(f"  - {name}: {count} contigs\\n")
        
        # MEGAHIT-only species
        f.write("\\n")
        megahit_only = species_df[(species_df['megahit_reads'] > 0) & (species_df['spades_reads'] == 0)].copy()
        megahit_only = megahit_only.sort_values('megahit_reads', ascending=False)
        
        f.write("Species found only in MEGAHIT (Top 10):\\n")
        for _, row in megahit_only.head(10).iterrows():
            name = row['name']
            count = int(row['megahit_reads'])
            f.write(f"  - {name}: {count} contigs\\n")
        
        f.write("\\n" + "="*80 + "\\n")
        f.write("Analysis Complete\\n")
        f.write("="*80 + "\\n")
    
    # Save CSV
    output_df = merged[['tax_id', 'rank', 'name', 
                        'spades_reads', 'spades_percent', 
                        'megahit_reads', 'megahit_percent']].copy()
    output_df['total_reads'] = output_df['spades_reads'] + output_df['megahit_reads']
    output_df = output_df.sort_values('total_reads', ascending=False)
    output_df.to_csv("${sample}_merged_report.csv", index=False)
    
    print(f"Report generated successfully: ${sample}")
    """
}

// Workflow completion message
workflow.onComplete {
    log.info """
    ==========================================
    🎯 Metagenome Assembly and Kraken2 Classification Results
    ==========================================
    Pipeline completed successfully!
    
    Results directory: ${params.outdir}
    
    Generated files:
    - fastp/: Quality control reports (if enabled)
      * *_fastp.html: HTML quality reports
      * *_fastp.json: JSON quality data
    - abundance_megahit/: MEGAHIT contigs abundance (RPM/RPKM)
      * *_megahit_abundance.txt: Detailed abundance for each contig
      * *_megahit_abundance_summary.txt: Summary statistics
    - abundance_spades/: SPAdes contigs abundance (RPM/RPKM)
      * *_spades_abundance.txt: Detailed abundance for each contig
      * *_spades_abundance_summary.txt: Summary statistics
    - kraken2_megahit/: Kraken2 classification of MEGAHIT contigs
      * *_megahit_classification.txt: Detailed classifications
      * *_megahit_report.txt: Summary reports
    - kraken2_spades/: Kraken2 classification of SPAdes contigs
      * *_spades_classification.txt: Detailed classifications
      * *_spades_report.txt: Summary reports
    - merged_reports/: Comprehensive analysis (if enabled)
      * *_merged_report.txt: Combined analysis report
      * *_merged_report.csv: Detailed comparison data
    
    ==========================================
    """
}

workflow.onError {
    log.error """
    ==========================================
    ❌ Metagenome Assembly and Kraken2 Classification Workflow Failed
    ==========================================
    Error: ${workflow.errorMessage}
    ==========================================
    """
}

