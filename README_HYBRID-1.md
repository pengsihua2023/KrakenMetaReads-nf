# Hybrid Metagenome Assembly and Classification Workflow

Version 3.0.0 - Support for both short-read and long-read data

## Overview

This workflow processes metagenome data from both Illumina (short-read) and Nanopore/PacBio (long-read) platforms, performing:
- Quality control (short reads only)
- Assembly using platform-specific tools
- **Abundance calculation (RPM/RPKM for all contigs)** ⭐
- Taxonomic classification with Kraken2

## Core Files

| File | Purpose |
|------|---------|
| `metagenome_hybrid_workflow.nf` | Main workflow (supports both short and long reads) |
| `metagenome_hybrid_workflow.config` | Resource configuration |
| `run_hybrid_workflow.sh` | Run both short + long reads (auto-detect) |
| `run_short_only.sh` | Run short reads only ⭐ |
| `run_long_only.sh` | Run long reads only ⭐ |

## Features

### Short-Read Processing (Illumina)
- **QC**: fastp with auto adapter detection
- **Assembly**: MEGAHIT + metaSPAdes (parallel)
- **Mapping**: Bowtie2 (Apptainer container)
- **Abundance**: RPM/RPKM for each contig ⭐
- **Classification**: Kraken2
- **Reports**: Merged MEGAHIT vs SPAdes comparison

### Long-Read Processing (Nanopore/PacBio)
- **Assembly**: metaFlye (general metagenome assembly)
- **Viral Identification**: viralFlye (identifies viral contigs from metaFlye) 🦠
  - Linear viral contigs
  - Circular viral contigs  
- **Mapping**: Minimap2 (Conda + auto symlink for dependencies)
- **Abundance**: RPM/RPKM for:
  - metaFlye all contigs ⭐
  - viralFlye linear viral contigs ⭐
  - viralFlye circular viral contigs ⭐
- **Classification**: Kraken2 for all three contig sets

## Environment Setup

### Short-Read Tools
- **fastp**: Conda environment
- **MEGAHIT, SPAdes**: Apptainer containers
- **Bowtie2**: Apptainer containers
- **Abundance calculation**: Conda + automatic symbolic linking

### Long-Read Tools
- **metaFlye**: Apptainer container (assembly)
- **viralFlye**: Conda environment (viral contig identification) 🦠
- **Minimap2, Samtools**: Conda + automatic symbolic linking ✅
- **Abundance calculation**: Conda + automatic symbolic linking

### Dependency Management
- ✅ **Automatic conda environments**: Nextflow creates tool-specific environments
  - fastp, Kraken2, Minimap2, Samtools, Python/Biopython
- ✅ **Pre-installed viralFlye**: Uses existing `viralFlye_env` conda environment 🦠
- ✅ **Automatic containers**: Nextflow pulls required containers
  - MEGAHIT, SPAdes, metaFlye, Bowtie2
- ✅ **Automatic symlinks**: Resolves libbz2.so.1.0 dependency automatically
- ✅ **Minimal manual setup**: Only viralFlye needs pre-installation, all other tools auto-downloaded

## Input Files

### Short-Read Samplesheet (`samplesheet_short.csv`)
```csv
sample,fastq_1,fastq_2
sample1,/path/to/sample1_R1.fastq.gz,/path/to/sample1_R2.fastq.gz
sample2,/path/to/sample2_R1.fastq.gz,/path/to/sample2_R2.fastq.gz
```

### Long-Read Samplesheet (`samplesheet_long.csv`)
```csv
sample,fastq_long
sample1,/path/to/sample1.fastq.gz
sample2,/path/to/sample2.fastq.gz
```

## Usage

### 🎯 Three Running Modes

#### Option 1: Only Long Reads (Recommended for single platform) ⭐
```bash
chmod +x run_long_only.sh
sbatch run_long_only.sh
```
- Requires: `samplesheet_long.csv` in current directory
- Output: `results_long/`
- Processes: 
  1. metaFlye assembly (all contigs)
  2. viralFlye identify viral contigs (linear + circular) 🦠
  3. Minimap2 mapping for all three contig sets
  4. RPM/RPKM calculation for all three sets
  5. Kraken2 classification for all three sets

#### Option 2: Only Short Reads
```bash
chmod +x run_short_only.sh
sbatch run_short_only.sh
```
- Requires: `samplesheet_short.csv` in current directory
- Output: `results_short/`
- Processes: fastp → MEGAHIT/SPAdes → Bowtie2 → RPM/RPKM → Kraken2

#### Option 3: Both Short and Long Reads
```bash
chmod +x run_hybrid_workflow.sh
sbatch run_hybrid_workflow.sh
```
- Auto-detects available samplesheets in current directory
- Requires: One or both samplesheet files
- Output: `results_short/` and/or `results_long/`
- Runs applicable workflows based on available data
- Long reads: Runs **metaFlye + viralFlye identification** by default 🦠
  - metaFlye assembles all contigs
  - viralFlye extracts viral contigs from metaFlye results

### 📝 Samplesheet File Detection

Scripts check for samplesheet files in this order:
1. **Current directory** (e.g., `./samplesheet_long.csv`) ← **Priority**
2. **Default absolute paths** (backup locations)

### 🔧 Manual Execution

If you prefer manual control:

**Both workflows:**
```bash
nextflow run metagenome_hybrid_workflow.nf \
    -c metagenome_hybrid_workflow.config \
    --input_short samplesheet_short.csv \
    --input_long samplesheet_long.csv \
    --outdir_short results_short \
    --outdir_long results_long \
    --kraken2_db /path/to/kraken2/db
```

**Short reads only:**
```bash
nextflow run metagenome_hybrid_workflow.nf \
    -c metagenome_hybrid_workflow.config \
    --input_short samplesheet_short.csv \
    --outdir_short results_short \
    --kraken2_db /path/to/kraken2/db
```

**Long reads only:**
```bash
nextflow run metagenome_hybrid_workflow.nf \
    -c metagenome_hybrid_workflow.config \
    --input_long samplesheet_long.csv \
    --outdir_long results_long \
    --kraken2_db /path/to/kraken2/db
```

## Output Structure

### Short-Read Results (`results_short/`)
```
results_short/
├── fastp/                      # Quality control reports
│   ├── *_fastp.html
│   └── *_fastp.json
├── abundance_megahit/          # MEGAHIT abundance (RPM/RPKM)
│   ├── *_megahit_abundance.txt
│   └── *_megahit_abundance_summary.txt
├── abundance_spades/           # SPAdes abundance (RPM/RPKM)
│   ├── *_spades_abundance.txt
│   └── *_spades_abundance_summary.txt
├── kraken2_megahit/           # Kraken2 classification
│   ├── *_megahit_classification.txt
│   └── *_megahit_report.txt
├── kraken2_spades/            # Kraken2 classification
│   ├── *_spades_classification.txt
│   └── *_spades_report.txt
└── merged_reports/             # Comparative analysis
    ├── *_merged_report.txt
    └── *_merged_report.csv
```

### Long-Read Results (`results_long/`)
```
results_long/
├── flye_assembly/                      # metaFlye assembly directory
│   └── *_flye_assembly/
├── viralflye/                          # viralFlye identified viral contigs 🦠
│   ├── linears_viralFlye.fasta        # Linear viral contigs
│   ├── circulars_viralFlye.fasta      # Circular viral contigs
│   └── components_viralFlye.fasta     # Multi-edge components
├── abundance_flye/                     # metaFlye all contigs (RPM/RPKM)
│   ├── *_flye_abundance.txt
│   └── *_flye_abundance_summary.txt
├── abundance_viralflye_linear/         # Linear viral contigs (RPM/RPKM) 🦠
│   ├── *_viralflye_linear_abundance.txt
│   └── *_viralflye_linear_abundance_summary.txt
├── abundance_viralflye_circular/       # Circular viral contigs (RPM/RPKM) 🦠
│   ├── *_viralflye_circular_abundance.txt
│   └── *_viralflye_circular_abundance_summary.txt
├── kraken2_flye/                       # metaFlye classification
│   ├── *_flye_classification.txt
│   └── *_flye_report.txt
├── kraken2_viralflye_linear/           # Linear viral classification 🦠
│   ├── *_viralflye_linear_classification.txt
│   └── *_viralflye_linear_report.txt
└── kraken2_viralflye_circular/         # Circular viral classification 🦠
    ├── *_viralflye_circular_classification.txt
    └── *_viralflye_circular_report.txt
```

## Key Parameters

### Short-Read Parameters
- `--input_short`: Short-read samplesheet path (CSV format)
- `--outdir_short`: Output directory for short reads (default: `results_short`)
- `--skip_fastp`: Skip quality control (default: false)
- `--megahit_min_contig_len`: Minimum contig length (default: 1000)

### Long-Read Parameters
- `--input_long`: Long-read samplesheet path (CSV format)
- `--outdir_long`: Output directory for long reads (default: `results_long`)
- `--flye_genome_size`: Estimated metagenome size (default: `5m`)
- `--flye_min_overlap`: Minimum overlap for assembly (default: 3000)
- `--long_read_type`: Platform type (options: `nanopore`, `pacbio`, `pacbio-hifi`)
- `--run_viralflye`: Run viralFlye to identify viral contigs (default: `true`) 🦠
- `--viralflye_min_length`: Min viral contig length (default: 5000)
- `--viralflye_max_length`: Max viral contig length (default: 1000000)
- `--viralflye_min_coverage`: Min coverage for viral contigs (default: 10)
- `--viralflye_hmm`: Optional Pfam HMM file path for protein annotation

### General Parameters
- `--kraken2_db`: Path to Kraken2 database (**required**)
- `--max_cpus`: Maximum CPUs to use (default: 32)
- `--max_memory`: Maximum memory (default: 256.GB)
- `--skip_merge_reports`: Skip merged report generation (default: false)

## Platform-Specific Settings

### For Nanopore Data (Default)
```bash
# No changes needed, use default settings
sbatch run_long_only.sh
```

### For PacBio CLR Data
Edit `metagenome_hybrid_workflow.config` line 161:
```groovy
long_read_type = 'pacbio'
```

### For PacBio HiFi Data
Edit `metagenome_hybrid_workflow.config` line 161:
```groovy
long_read_type = 'pacbio-hifi'
```

This automatically adjusts:
- Flye assembly parameters (`--nano-raw`, `--pacbio-raw`, or `--pacbio-hifi`)
- Minimap2 alignment presets (`map-ont`, `map-pb`, or `asm20`)

## Requirements

### System Requirements
- **Nextflow** >= 21.04 (installed in `nextflow_env`)
- **Apptainer/Singularity** (for containers)
- **Conda/Mamba** (for tool environments)
- **SLURM** cluster environment

### Pre-installed Tools (Required)
- **viralFlye**: Must be pre-installed in `viralFlye_env` conda environment 🦠

To install viralFlye:
```bash
# Create and activate viralFlye environment
conda create -n viralFlye_env python=3.8
conda activate viralFlye_env

# Install viralFlye from GitHub
git clone https://github.com/Dmitry-Antipov/viralFlye.git
cd viralFlye
pip install -r requirements.txt

# Verify installation
viralFlye.py --help
```

### Auto-installed Tools
✅ **All other tools are automatically managed by Nextflow:**
- Conda creates isolated environments: fastp, Kraken2, Minimap2, Samtools, Python/Biopython
- Containers are automatically pulled: MEGAHIT, SPAdes, metaFlye, Bowtie2

## Dependency Resolution

### Automatic Symbolic Linking
The workflow automatically resolves the `libbz2.so.1.0` dependency issue:
1. Searches system directories for libbz2 library
2. Creates symbolic link in `$HOME/.local/lib_tmp/`
3. Sets `LD_LIBRARY_PATH` for each process
4. Works across different Linux distributions

This applies to:
- All abundance calculation processes (MEGAHIT, SPAdes, metaFlye, viralFlye)
- Minimap2 alignment processes

## viralFlye Integration 🦠

### What is viralFlye?
viralFlye is a **post-processing tool** that identifies viral contigs from metaFlye assembly results:
- Analyzes metaFlye's assembly graph to extract viral sequences
- Identifies linear and circular viral genomes
- Filters by coverage (>10x) and length (5kb-1Mb)
- Optional viral protein annotation using Pfam HMM

**Note**: viralFlye must be pre-installed in `viralFlye_env` conda environment (not available in standard conda channels)

### Workflow Strategy
```
Long reads → metaFlye assembly → viralFlye identification → Viral contigs
                  ↓                        ↓
            All contigs              Linear + Circular
                  ↓                        ↓
           RPM/RPKM + Kraken2      RPM/RPKM + Kraken2
```

### Output Organization
You get **three sets of results**:
1. **metaFlye all contigs**: Complete metagenome view
2. **viralFlye linear**: Linear viral genomes (filtered)
3. **viralFlye circular**: Circular viral genomes (phages, small DNA viruses)

Each set has independent:
- RPM/RPKM abundance calculations
- Kraken2 taxonomic classifications

### Key Parameters
- `viralflye_min_length = 5000` - Min contig length for viral ID
- `viralflye_max_length = 1000000` - Max contig length
- `viralflye_min_coverage = 10` - Min coverage threshold
- `viralflye_hmm = null` - Optional Pfam HMM path

### Disable viralFlye
If you only want metaFlye, edit `metagenome_hybrid_workflow.config`:
```groovy
run_viralflye = false
```

### Important Note
⚠️ viralFlye is **NOT** a separate assembler  
✅ viralFlye **IS** a tool that extracts viral contigs from metaFlye results

## Troubleshooting

### Issue: Conda cache conflicts
```bash
# Clean conda cache
rm -rf /scratch/sp96859/Meta-genome-data-analysis/conda_cache/
rm -rf work/

# Rerun
sbatch run_long_only.sh  # or your chosen script
```

### Issue: Container download fails
- Most processes now use Conda instead of containers to avoid download issues
- Only assembly tools (MEGAHIT, SPAdes, metaFlye, Bowtie2) use containers

### Issue: Samplesheet not found
- Ensure samplesheet files are in the **current directory**
- Or they will be searched in default absolute paths
- Check the script output for searched locations

## Notes

- ✅ The workflow **automatically handles** `libbz2.so.1.0` dependency via symbolic linking
- ✅ Both workflows can run **simultaneously or independently**
- ✅ RPM and RPKM are calculated for **all contigs across all assemblers**
- ✅ **No manual tool installation** required - Nextflow handles everything
- ✅ First run may take longer (downloading tools), subsequent runs are fast

