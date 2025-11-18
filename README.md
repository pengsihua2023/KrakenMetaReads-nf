# KrakenMetaReads-nf

A comprehensive Nextflow workflow for viral metagenomic classification and abundance analysis using nf-core/taxprofiler. This pipeline supports both short-read (Illumina) and long-read (Nanopore/PacBio) sequencing data, providing automated taxonomic classification with Kraken2 and abundance quantification using RPM (Reads Per Million) and RPKM (Reads Per Kilobase Million) metrics.

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Usage](#usage)
- [Output Structure](#output-structure)
- [Abundance Calculation](#abundance-calculation)
- [Troubleshooting](#troubleshooting)
- [Citation](#citation)

## Features

- **Dual Sequencing Support**: Optimized workflows for both short-read (Illumina) and long-read (Nanopore/PacBio) data
- **Automated Classification**: Uses Kraken2 for fast and accurate taxonomic classification
- **Abundance Quantification**: 
  - Short-read: Kraken2 + Bracken statistical correction
  - Long-read: Direct extraction from Kraken2 reports (Bracken not needed)
- **Multiple Metrics**: Calculates both RPM and RPKM for comprehensive abundance analysis
- **Batch Processing**: Automated batch processing of multiple samples
- **Containerized**: Uses Apptainer/Singularity for reproducible analysis
- **Quality Control**: Integrated QC steps with MultiQC reporting
- **Standardized Output**: Generates BIOM format files for downstream analysis

## Requirements

### Software Dependencies

- **Nextflow** (>= 22.10.0)
- **Java** (>= 17)
- **Apptainer/Singularity** (>= 1.1.0)
- **Python 3** (>= 3.7) with pandas
- **nf-core/taxprofiler** (>= 1.2.0)

### System Requirements

- **CPU**: 32 cores recommended
- **Memory**: 256 GB RAM recommended
- **Storage**: Sufficient space for databases and results (varies by dataset size)
- **SLURM**: For cluster execution (scripts include SLURM directives)

### Database Requirements

- Kraken2 viral reference database (specified in `databases.csv`)
- Bracken database (for short-read analysis, built from Kraken2 database)

## Installation

### 1. Clone the Repository

```bash
git clone <repository-url>
cd KrakenMetaReads-nf
```

### 2. Set Up Nextflow Environment

Create a conda environment with required dependencies:

```bash
conda create -n nextflow_env python=3.9 java=17
conda activate nextflow_env
conda install -c bioconda nextflow apptainer
```

### 3. Prepare Databases

Ensure your Kraken2 viral database is built and accessible. Update the database path in `databases.csv`:

```csv
tool,db_name,db_params,db_path
kraken2,Viral_ref,"",/path/to/kraken2_Viral_ref
bracken,Viral_ref,";-r 150",/path/to/kraken2_Viral_ref
```

### 4. Install Python Dependencies

```bash
pip install pandas
```

## Quick Start

### For Short-Read Data (Illumina)

1. **Prepare samplesheet**: Edit `samplesheet_short.csv` with your sample information
2. **Submit job**: 
   ```bash
   sbatch submit_short.sh
   ```

### For Long-Read Data (Nanopore/PacBio)

1. **Prepare samplesheet**: Edit `samplesheet_long.csv` with your sample information
2. **Submit job**:
   ```bash
   sbatch submit_long.sh
   ```

## Configuration

### Samplesheet Format

#### Short-Read Samplesheet (`samplesheet_short.csv`)

```csv
sample,run_accession,instrument_platform,fastq_1,fastq_2,fasta
sample1,run1,ILLUMINA,/path/to/sample1_R1.fastq.gz,/path/to/sample1_R2.fastq.gz,
sample2,run2,ILLUMINA,/path/to/sample2_R1.fastq.gz,/path/to/sample2_R2.fastq.gz,
```

#### Long-Read Samplesheet (`samplesheet_long.csv`)

```csv
sample,run_accession,instrument_platform,fastq_1,fastq_2,fasta
sample1,run1,OXFORD_NANOPORE,/path/to/sample1.fastq.gz,,
sample2,run2,OXFORD_NANOPORE,/path/to/sample2.fastq.gz,,
```

### Configuration Files

#### `nextflow_short.config` (Short-Read Configuration)

Key parameters:
- `input`: Path to short-read samplesheet
- `outdir`: Output directory (default: `results_viral_short`)
- `databases`: Path to databases CSV file
- `run_kraken2`: Enable Kraken2 classification (default: `true`)
- `run_bracken`: Enable Bracken abundance estimation (default: `true`)
- `bracken_precision`: Taxonomic level for Bracken (default: `'S'` for species)
- `bracken_readlen`: Read length for Bracken (default: `150`)

#### `nextflow_long.config` (Long-Read Configuration)

Key parameters:
- `input`: Path to long-read samplesheet
- `outdir`: Output directory (default: `results_viral_long`)
- `run_kraken2`: Enable Kraken2 classification (default: `true`)
- `run_bracken`: Disabled for long-read data (default: `false`)
- `perform_longread_qc`: Enable long-read QC (default: `true`)

### Database Configuration (`databases.csv`)

```csv
tool,db_name,db_params,db_path
kraken2,Viral_ref,"",/path/to/kraken2_Viral_ref
bracken,Viral_ref,";-r 150",/path/to/kraken2_Viral_ref
```

## Usage

### Automated Workflow (Recommended)

The submission scripts (`submit_short.sh` and `submit_long.sh`) automatically:
1. Run the nf-core/taxprofiler workflow
2. Calculate abundance metrics (RPM & RPKM) for all samples
3. Generate summary tables

### Manual Execution

#### Step 1: Run TaxProfiler

```bash
# Short-read
nextflow run nf-core/taxprofiler \
  -r 1.2.0 \
  -profile apptainer \
  -c nextflow_short.config \
  -resume

# Long-read
nextflow run nf-core/taxprofiler \
  -r 1.2.0 \
  -profile apptainer \
  -c nextflow_long.config \
  -resume
```

#### Step 2: Calculate Abundance

```bash
# Short-read (with Bracken)
bash batch_calculate_abundance_en.sh results_viral_short

# Long-read (Kraken2 only)
bash batch_calculate_abundance_longread_en.sh results_viral_long
```

### Single Sample Abundance Calculation

#### Short-Read Data

```bash
# Files may be in subdirectories or directly in tool directories
# The script will search both locations automatically
python3 calculate_abundance_en.py \
  --bracken results_viral_short/bracken/sample1/sample1_bracken.tsv \
  --kraken results_viral_short/kraken2/sample1/sample1.report \
  --output sample1_abundance.tsv

# Or if files are directly in tool directories:
python3 calculate_abundance_en.py \
  --bracken results_viral_short/bracken/sample1_bracken.tsv \
  --kraken results_viral_short/kraken2/sample1.report \
  --output sample1_abundance.tsv
```

#### Long-Read Data

```bash
# Note: Long-read data does NOT use Bracken
# Files may be in subdirectories or directly in tool directories
python3 calculate_abundance_longread_en.py \
  --kraken results_viral_long/kraken2/sample1/sample1.report \
  --output sample1_abundance.tsv \
  --level S

# Or if files are directly in tool directories:
python3 calculate_abundance_longread_en.py \
  --kraken results_viral_long/kraken2/sample1.report \
  --output sample1_abundance.tsv \
  --level S
```

## Output Structure

### Short-Read Data Structure

```
results_viral_short/
├── kraken2/                          # Kraken2 classification results
│   ├── sample1/                      # Sample-specific subdirectory (may exist)
│   │   └── sample1.report            # or sample1.kraken2.report.txt
│   ├── sample2/
│   │   └── sample2.report
│   ├── sample1.report                # Or files directly in kraken2/
│   └── sample2.report
├── bracken/                          # Bracken abundance estimates (short-read only)
│   ├── sample1/                      # Sample-specific subdirectory (may exist)
│   │   └── sample1_bracken.tsv       # or sample1.bracken_species.tsv
│   ├── sample2/
│   │   └── sample2_bracken.tsv
│   ├── sample1_bracken.tsv           # Or files directly in bracken/
│   └── sample2_bracken.tsv
├── abundance/                        # Calculated abundance metrics (created by scripts)
│   ├── sample1_abundance.tsv
│   ├── sample2_abundance.tsv
│   ├── all_samples_abundance_summary.tsv
│   └── top_viruses_summary.tsv
├── fastqc/                           # Quality control reports
├── multiqc/                          # MultiQC quality control report
│   └── multiqc_report.html
├── pipeline_info/                    # Pipeline execution metadata
└── [other tool outputs]/             # Additional tool outputs if enabled
```

### Long-Read Data Structure

```
results_viral_long/
├── kraken2/                          # Kraken2 classification results
│   ├── sample1/                      # Sample-specific subdirectory (may exist)
│   │   └── sample1.report            # or sample1.kraken2.report.txt
│   ├── sample2/
│   │   └── sample2.report
│   ├── sample1.report                # Or files directly in kraken2/
│   └── sample2.report
├── abundance/                        # Calculated abundance metrics (created by scripts)
│   ├── sample1_abundance.tsv
│   ├── sample2_abundance.tsv
│   ├── all_samples_abundance_summary.tsv
│   └── top_viruses_summary.tsv
├── nanoplot/                         # Long-read quality control (Nanoplot)
├── multiqc/                          # MultiQC quality control report
│   └── multiqc_report.html
├── pipeline_info/                    # Pipeline execution metadata
└── [other tool outputs]/             # Additional tool outputs if enabled
```

**Note**: 
- nf-core/taxprofiler may organize files in sample-specific subdirectories or directly in tool directories
- The batch scripts automatically search both locations
- **Bracken directory is NOT present for long-read data** (Bracken is designed for short reads only)

### Abundance Output Format

Each sample abundance file (`*_abundance.tsv`) contains:

| Column | Description |
|--------|-------------|
| Species | Taxonomic species name |
| Taxonomy_ID | NCBI taxonomy ID |
| Assigned_Reads | Number of reads assigned to this species |
| Fraction | Fraction of total reads (0-1) |
| RPM | Reads Per Million |
| Genome_Length_bp | Genome length in base pairs (if available) |
| RPKM | Reads Per Kilobase Million (if genome length available) |

## Abundance Calculation

### Metrics Explained

#### RPM (Reads Per Million)
```
RPM = (assigned_reads / total_reads) × 1,000,000
```
- Normalizes read counts by total sequencing depth
- Useful for comparing abundance across samples with different sequencing depths

#### RPKM (Reads Per Kilobase Million)
```
RPKM = assigned_reads / (genome_length_kb × total_reads_million)
```
- Normalizes by both sequencing depth and genome length
- Accounts for genome size differences between viruses
- More accurate for comparing abundance across different viral species

### Short-Read vs Long-Read

**Short-Read (Illumina)**:
- Uses Kraken2 for classification
- Applies Bracken statistical correction to improve abundance estimates
- Bracken is designed for short reads (50-300 bp)
- **Output structure**: Contains both `kraken2/` and `bracken/` directories
- **Abundance calculation**: Uses both Kraken2 reports and Bracken output files
- **QC tools**: FastQC for quality control

**Long-Read (Nanopore/PacBio)**:
- Uses Kraken2 for classification
- No Bracken correction needed (long reads contain more information)
- Direct extraction from Kraken2 reports is sufficient
- **Output structure**: Contains only `kraken2/` directory (no `bracken/` directory)
- **Abundance calculation**: Uses only Kraken2 report files
- **QC tools**: Nanoplot for long-read quality control

### Custom Genome Length Database

You can provide a custom genome length database:

```bash
python3 calculate_abundance_en.py \
  --bracken sample1_bracken.tsv \
  --kraken sample1.report \
  --output sample1_abundance.tsv \
  --genome-db custom_genome_lengths.tsv
```

Format of `custom_genome_lengths.tsv`:
```
Species Name<TAB>Genome_Length_bp
Severe acute respiratory syndrome coronavirus 2<TAB>29903
Influenza A virus<TAB>13588
```

## Troubleshooting

### Common Issues

#### 1. Bracken Results Not Found (Short-Read)

**Symptom**: Warning message about missing Bracken results

**Solution**: 
- Check that `run_bracken = true` in configuration
- Verify Bracken database is properly configured in `databases.csv`
- The script will automatically fall back to Kraken2-only method if Bracken fails

#### 2. Container Mount Errors

**Symptom**: Apptainer mount point errors

**Solution**: The configuration includes `--no-mount /lscratch` option. If you encounter other mount issues, update `apptainer.runOptions` in the config file.

#### 3. Memory Issues

**Symptom**: Out of memory errors

**Solution**: 
- Increase `max_memory` in configuration file
- Reduce `max_cpus` to limit parallel processes
- Process samples in smaller batches

#### 4. Database Path Errors

**Symptom**: Database not found errors

**Solution**:
- Verify database paths in `databases.csv` are absolute paths
- Ensure database directories are accessible
- Check that Kraken2 database is properly built

#### 5. Python Dependencies Missing

**Symptom**: `ModuleNotFoundError: No module named 'pandas'`

**Solution**:
```bash
pip install pandas
# or
conda install pandas
```

### Getting Help

1. Check Nextflow logs: `work/` directory contains detailed execution logs
2. Check MultiQC report: `results_*/multiqc/multiqc_report.html`
3. Review SLURM output files: `*_%j.out` and `*_%j.err`

## Citation

If you use this workflow in your research, please cite:

1. **nf-core/taxprofiler**: 
   - Ewels, P. A., et al. (2023). The nf-core framework for community-curated bioinformatics pipelines. *Nature Biotechnology*, 41(2), 178-183.

2. **Kraken2**:
   - Wood, D. E., Lu, J., & Langmead, B. (2019). Improved metagenomic analysis with Kraken 2. *Genome Biology*, 20(1), 257.

3. **Bracken**:
   - Lu, J., Breitwieser, F. P., Thielen, P., & Salzberg, S. L. (2017). Bracken: estimating species abundance in metagenomics data. *PeerJ Computer Science*, 3, e104.

4. **Nextflow**:
   - Di Tommaso, P., et al. (2017). Nextflow enables reproducible computational workflows. *Nature Biotechnology*, 35(4), 316-319.

## License

[Specify your license here]

## Contact

[Your contact information]

---

**Note**: This workflow is designed for viral metagenomic analysis. For broader taxonomic profiling including bacteria, archaea, and eukaryotes, consider using a comprehensive database instead of a viral-only database.

