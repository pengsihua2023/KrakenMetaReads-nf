# Quick Start Guide - Hybrid Metagenome Workflow

Version 3.0 - With Virus Consensus Analysis

## 🚀 Three Running Modes

### Option 1: Short Reads Only (Illumina)
```bash
sbatch run_short_only.sh
```
- Requires: `samplesheet_short.csv`
- Output: `results_short/`
- Features: MEGAHIT + SPAdes + **Virus Consensus** ⭐

### Option 2: Long Reads Only (Nanopore/PacBio)
```bash
sbatch run_long_only.sh
```
- Requires: `samplesheet_long.csv` + `viralFlye_env`
- Output: `results_long/`
- Features: metaFlye + viralFlye + **3 Contig Sets** ⭐

### Option 3: Both Short + Long Reads
```bash
sbatch run_hybrid_workflow.sh
```
- Auto-detects available samplesheets
- Output: `results_short/` + `results_long/`

---

## 📁 Input Files

### Short-Read Samplesheet (`samplesheet_short.csv`)
```csv
sample,fastq_1,fastq_2
sample1,/path/to/sample1_R1.fastq.gz,/path/to/sample1_R2.fastq.gz
```

**Default location**: Current directory or  
`/scratch/sp96859/Meta-genome-data-analysis/Apptainer/yitiaolong/data/reads/`

### Long-Read Samplesheet (`samplesheet_long.csv`)
```csv
sample,fastq_long
sample1,/path/to/sample1.fastq.gz
```

**Default location**: Current directory or  
`/scratch/sp96859/Meta-genome-data-analysis/Apptainer/Contig-based-VirSorter2-DeepVirFinder/data/`

---

## 📊 Output Structure

### Short Reads (`results_short/`)

```
results_short/
├── fastp/                         # Quality control reports
├── abundance_megahit/             # MEGAHIT RPM/RPKM ⭐
├── abundance_spades/              # SPAdes RPM/RPKM ⭐
├── kraken2_megahit/              # MEGAHIT classification
├── kraken2_spades/               # SPAdes classification
└── merged_reports/                # 🆕 Enhanced reports
    ├── *_merged_report.csv       # All taxa comparison
    └── *_virus_consensus.txt     # 🆕 Consensus virus analysis ⭐⭐
```

### Long Reads (`results_long/`)

```
results_long/
├── flye_assembly/                 # metaFlye assembly
├── viralflye/                     # 🆕 viralFlye viral contigs ⭐
│   ├── linears_viralFlye.fasta   # Linear DNA viruses
│   └── circulars_viralFlye.fasta # Circular DNA viruses (complete)
├── abundance_flye/                # Set 1: All contigs RPM/RPKM
├── abundance_viralflye_linear/    # Set 2: Linear viruses RPM/RPKM ⭐
├── abundance_viralflye_circular/  # Set 3: Circular viruses RPM/RPKM ⭐
├── kraken2_flye/                  # All contigs classification
├── kraken2_viralflye_linear/      # Linear viruses classification
└── kraken2_viralflye_circular/    # Circular viruses classification
```

---

## 🦠 Key Features

### 1. **Virus Consensus Analysis** (Short Reads) 🆕

Identifies viruses detected by **BOTH** assemblers:
- ✅ **Consensus viruses** (High confidence) - Detected by both
- ⚠️ **SPAdes only** (Medium confidence)
- ⚠️ **MEGAHIT only** (Medium confidence)

**Agreement score**: Measures consistency between assemblers  
→ Higher agreement = More reliable

**Output**: `results_short/merged_reports/*_virus_consensus.txt`

### 2. **Three Contig Sets** (Long Reads) 🆕

#### Set 1: metaFlye All Contigs
- All metagenome contigs (bacteria + viruses + eukaryotes)
- Complete microbiome view

#### Set 2: viralFlye Linear Viruses
- Linear DNA viral contigs
- Filtered: ≥2kb, ≥50% completeness

#### Set 3: viralFlye Circular Viruses ⭐
- Circular DNA viral genomes
- **Complete viral genomes** (highest quality)
- Example: Bacteriophages

**Each set**: Independent RPM/RPKM + Kraken2 classification

### 3. **RPM/RPKM Abundance** ⭐

All assemblers calculate:
- **RPM**: Reads Per Million
- **RPKM**: Reads Per Kilobase per Million

Every contig gets abundance metrics!

---

## ⚠️ Important Notes

### DNA vs RNA Viruses

**This workflow detects DNA viruses only:**
- ✅ Phages, Herpesviruses, Poxviruses, Megaviruses
- ❌ **NOT** Influenza, Coronavirus, HIV (RNA viruses)

**For RNA viruses**: Use Nanopore RNA-seq + RNA assembly tools

See: `DNA_VS_RNA_VIRUSES.md` for details

### Kraken2 Database

**Current setup**: Viral reference database (`kraken2_Viral_ref`)
- Contains: Virus genomes only
- Result: Bacteria appear as "Unclassified" (99%)

**Alternative**: Use standard database for complete microbiome classification

---

## 🔧 Prerequisites

### Required:
- ✅ Nextflow (installed in `nextflow_env`)
- ✅ Apptainer/Singularity
- ✅ Conda/Mamba
- ✅ SLURM cluster

### For Long Reads:
- ✅ `viralFlye_env` conda environment with viralFlye installed

```bash
# Verify viralFlye
conda activate viralFlye_env
python -c "from viralflye.main import main; print('OK')"
```

### Pfam Database (Required for viralFlye):
```bash
# Set in metagenome_hybrid_workflow.config
viralflye_hmm = '/scratch/sp96859/.../Pfam/Pfam-A.hmm'
```

---

## 📈 Resource Requirements

### Short Reads:
- **MEGAHIT**: 16 CPUs, 64 GB, 12h
- **SPAdes**: 32 CPUs, 512 GB, 48h ⚠️ High memory!
- **Bowtie2**: 16 CPUs, 32 GB, 8h each
- **Kraken2**: 16 CPUs, 48 GB, 8h each

### Long Reads:
- **metaFlye**: 32 CPUs, 128 GB, 72h
- **viralFlye**: 16 CPUs, 64 GB, 12h
- **Minimap2**: 16 CPUs, 32 GB, 8h each
- **Kraken2**: 16 CPUs, 48 GB, 8h each

---

## 🔍 Quick Results Check

### View consensus viruses (Short reads):
```bash
cat results_short/merged_reports/*_virus_consensus.txt
```

### View circular viruses (Long reads):
```bash
cat results_long/abundance_viralflye_circular/*_summary.txt
```

### View all viral abundance:
```bash
# Short reads - SPAdes
head -20 results_short/abundance_spades/*_abundance.txt

# Long reads - Circular viruses
head -20 results_long/abundance_viralflye_circular/*_abundance.txt
```

---

## 🎯 Platform Selection

### Nanopore (Default):
```bash
# No changes needed
sbatch run_long_only.sh
```

### PacBio CLR:
Edit `metagenome_hybrid_workflow.config`:
```groovy
long_read_type = 'pacbio'
```

### PacBio HiFi:
Edit `metagenome_hybrid_workflow.config`:
```groovy
long_read_type = 'pacbio-hifi'
```

---

## 🛠️ Troubleshooting

### Issue: Dependency errors
```bash
rm -rf work/ /scratch/sp96859/.../conda_cache/
sbatch run_[short/long/hybrid]_workflow.sh
```

### Issue: viralFlye module not found
```bash
conda activate viralFlye_env
cd /path/to/viralFlye
pip install -e .
python -c "from viralflye.main import main"  # Should not error
```

### Issue: Check failed job
```bash
# Find work directory from error message
cd work/xx/xxxxxx...
cat .command.out  # Check output
cat .command.err  # Check errors
```

---

## 📚 Documentation

| File | Content |
|------|---------|
| `README_HYBRID.md` | Complete documentation |
| `QUICK_START.md` | This guide |
| `DNA_VS_RNA_VIRUSES.md` | DNA vs RNA virus detection |
| `VIRALFLYE_INFO.md` | viralFlye integration details |

---

## ✅ Success Indicators

After completion, you should see:

### Short Reads:
```
✅ MEGAHIT abundance: N files
✅ SPAdes abundance: N files
✅ Merged reports: N files
✅ Virus consensus analysis: N files ⭐ (NEW!)
```

### Long Reads:
```
✅ metaFlye abundance: N files
✅ viralFlye linear viral abundance: N files ⭐
✅ viralFlye circular viral abundance: N files ⭐
✅ viralFlye identified viral contigs ⭐ (NEW!)
```

---

## 🎊 That's It!

Three simple steps:
1. Prepare samplesheets
2. Choose running mode
3. Submit job

The workflow handles everything else automatically! 🧬✨
