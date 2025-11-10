# Hybrid Metagenome Workflow - Complete Summary

Version 3.0 - With Virus Consensus Analysis & viralFlye Integration

## 📦 Core Files

### Workflow Files
1. **metagenome_hybrid_workflow.nf** (1400+ lines)
   - Main Nextflow workflow
   - Supports short-read (Illumina) and long-read (Nanopore/PacBio)
   - Includes all process definitions

2. **metagenome_hybrid_workflow.config** (245 lines)
   - Resource configuration
   - SLURM cluster settings
   - Process-specific CPU/memory/time allocations

3. **Run scripts**:
   - `run_hybrid_workflow.sh` - Both short + long reads (auto-detect)
   - `run_short_only.sh` - Short reads only
   - `run_long_only.sh` - Long reads only

### Documentation
4. **README_HYBRID.md** - Complete documentation
5. **QUICK_START.md** - Quick start guide
6. **DNA_VS_RNA_VIRUSES.md** - DNA vs RNA virus detection explanation
7. **VIRALFLYE_INFO.md** - viralFlye integration details

---

## 🔬 Workflow Architecture

### Short-Read Pipeline (Illumina)

```
Paired-end FASTQ (R1, R2)
  ↓
[FASTP] Quality Control
  ↓
┌──────────────┬──────────────┐
│  MEGAHIT     │   SPAdes     │ Parallel Assembly
└──────────────┴──────────────┘
       ↓              ↓
  [Bowtie2]      [Bowtie2]      Build Index (Apptainer)
       ↓              ↓
  [Bowtie2]      [Bowtie2]      Align Reads (Apptainer)
       ↓              ↓
  [Calculate]    [Calculate]    RPM/RPKM ⭐ (Conda + symlink)
       ↓              ↓
  [Kraken2]      [Kraken2]      Classification (Conda)
       ↓              ↓
       └──────┬───────┘
              ↓
      [Merge & Consensus]         🆕 Virus Consensus Analysis ⭐⭐
              ↓
    ┌─────────┴─────────┐
    │                   │
Merged Report    Virus Consensus Report
                 ├─ Consensus (Both) ✅
                 ├─ SPAdes only ⚠️
                 └─ MEGAHIT only ⚠️
```

### Long-Read Pipeline (Nanopore/PacBio) - DNA Viruses Only

```
Single-end FASTQ (DNA-seq)
  ↓
[metaFlye] Assembly (Apptainer)
  ├─ All contigs (bacteria + DNA viruses + eukaryotes)
  └─ Assembly directory → viralFlye input
  ↓
[viralFlye] DNA Viral Identification (Conda: viralFlye_env) 🆕
  ├─ Linear DNA viral contigs
  └─ Circular DNA viral contigs (complete genomes) ⭐
  ↓
Three Parallel Tracks:
  ↓
┌────────────┬─────────────────┬──────────────────┐
│ Set 1:     │ Set 2:          │ Set 3:           │
│ All        │ Linear          │ Circular         │
│ Contigs    │ DNA Viruses     │ DNA Viruses      │
└────────────┴─────────────────┴──────────────────┘
     ↓              ↓                  ↓
[Minimap2]     [Minimap2]          [Minimap2]       Mapping (Conda + symlink)
     ↓              ↓                  ↓
[Calculate]    [Calculate]         [Calculate]      RPM/RPKM ⭐
     ↓              ↓                  ↓
[Kraken2]      [Kraken2]           [Kraken2]        Classification
     ↓              ↓                  ↓
Complete       DNA Virus           Complete DNA
Metagenome     Fragments           Viral Genomes ⭐⭐
```

---

## 🎯 Key Features

### 1. **Virus Consensus Analysis** (Short Reads) 🆕

**Purpose**: Identify high-confidence viruses detected by both assemblers

**Method**:
- Compare Kraken2 results from MEGAHIT and SPAdes
- Categorize viruses: Consensus (Both) vs Single-assembler
- Calculate agreement ratio for consensus viruses

**Output**:
```
Virus Consensus Report:
├─ Total viral classifications
├─ ✅ Consensus viruses (Both) - HIGH CONFIDENCE
├─ ⚠️ SPAdes only - MEDIUM CONFIDENCE
└─ ⚠️ MEGAHIT only - MEDIUM CONFIDENCE

For each consensus virus:
- Tax ID, Rank, Name
- SPAdes contigs count
- MEGAHIT contigs count  
- Agreement ratio (0-1) ⭐
```

**Use case**: Focus on high-confidence viruses for publication

### 2. **Three Contig Sets** (Long Reads) 🆕

**Purpose**: Multi-level viral analysis from metaFlye assembly

#### Set 1: metaFlye All Contigs
- All assembled contigs (complete metagenome)
- Bacteria + DNA viruses + Eukaryotes
- Comprehensive view

#### Set 2: viralFlye Linear DNA Viruses
- Linear DNA viral contigs extracted by viralFlye
- Filters: ≥2kb length, ≥50% completeness
- Partial or linear viral genomes

#### Set 3: viralFlye Circular DNA Viruses ⭐⭐
- Circular DNA viral contigs (closed genomes)
- **Complete viral genomes** - Highest quality
- Typical: Bacteriophages, small DNA viruses

**Each set**: Independent RPM/RPKM + Kraken2 classification

### 3. **RPM/RPKM Abundance Calculation** ⭐

**All assemblers** calculate abundance metrics:

| Assembler | Output Files |
|-----------|-------------|
| MEGAHIT | `*_megahit_abundance.txt` + summary |
| SPAdes | `*_spades_abundance.txt` + summary |
| metaFlye (all) | `*_flye_abundance.txt` + summary |
| viralFlye (linear) | `*_viralflye_linear_abundance.txt` + summary |
| viralFlye (circular) | `*_viralflye_circular_abundance.txt` + summary |

**Format**:
```
Contig_ID    Length(bp)  Mapped_Reads  RPM       RPKM
contig_001   5000        1200          8500.5    1700.1
```

### 4. **Automatic Dependency Management**

- ✅ Conda environments auto-created by Nextflow
- ✅ Containers auto-pulled (MEGAHIT, SPAdes, metaFlye, Bowtie2)
- ✅ Symbolic links auto-created (libbz2.so.1.0 issue)
- ✅ Python version compatibility handled (viralFlye)

**Only manual setup**: viralFlye_env (pre-install required)

### 5. **Platform Flexibility**

Supports three long-read platforms:
- **Nanopore**: `--long_read_type nanopore` (default)
- **PacBio CLR**: `--long_read_type pacbio`
- **PacBio HiFi**: `--long_read_type pacbio-hifi`

Auto-adjusts:
- Flye parameters (`--nano-raw`, `--pacbio-raw`, `--pacbio-hifi`)
- Minimap2 presets (`map-ont`, `map-pb`, `asm20`)

---

## 📊 Output Files Summary

### Short Reads (results_short/)

| Directory | Files | Content |
|-----------|-------|---------|
| `fastp/` | HTML, JSON | QC reports |
| `megahit_assembly/` | FASTA | MEGAHIT contigs |
| `spades_assembly/` | FASTA | SPAdes contigs |
| `abundance_megahit/` | TXT | RPM/RPKM per contig ⭐ |
| `abundance_spades/` | TXT | RPM/RPKM per contig ⭐ |
| `kraken2_megahit/` | TXT | Taxonomic classification |
| `kraken2_spades/` | TXT | Taxonomic classification |
| `merged_reports/` | TXT, CSV | **Virus consensus** 🆕 |

### Long Reads (results_long/)

| Directory | Files | Content |
|-----------|-------|---------|
| `flye_assembly/` | FASTA, GFA | metaFlye assembly + graph |
| `viralflye/` | FASTA | **Viral contigs** (linear + circular) 🆕 |
| `abundance_flye/` | TXT | All contigs RPM/RPKM ⭐ |
| `abundance_viralflye_linear/` | TXT | Linear viruses RPM/RPKM 🆕 |
| `abundance_viralflye_circular/` | TXT | Circular viruses RPM/RPKM 🆕 |
| `kraken2_flye/` | TXT | All contigs classification |
| `kraken2_viralflye_linear/` | TXT | Linear viruses classification 🆕 |
| `kraken2_viralflye_circular/` | TXT | Circular viruses classification 🆕 |

---

## 🔧 Configuration Parameters

### Short-Read Parameters
```groovy
input_short = 'samplesheet_short.csv'
outdir_short = 'results_short'
megahit_min_contig_len = 1000
skip_fastp = false
```

### Long-Read Parameters
```groovy
input_long = 'samplesheet_long.csv'
outdir_long = 'results_long'
flye_genome_size = '5m'
long_read_type = 'nanopore'  // or 'pacbio', 'pacbio-hifi'
```

### viralFlye Parameters (DNA Virus Identification) 🦠
```groovy
run_viralflye = true
viralflye_hmm = '/path/to/Pfam-A.hmm'  // REQUIRED
viralflye_min_length = 2000      // 2kb to capture small DNA viruses
viralflye_completeness = 0.5     // 50% completeness threshold
viralflye_threads = 10
```

### Kraken2 Parameters
```groovy
kraken2_db = '/path/to/kraken2/db'  // REQUIRED
kraken2_confidence = 0.05
```

---

## 🦠 DNA vs RNA Virus Detection

### ✅ What This Workflow Detects (DNA Viruses)

**Detectable with DNA-seq data**:
- Bacteriophages (T4, λ, Ralstonia phage, Klebsiella phage)
- Large DNA viruses (Herpesviruses, Poxviruses, Megaviruses)
- Small DNA viruses (Circoviridae ~2kb)
- Adenoviruses, Papillomaviruses

**Example from results**:
- Ralstonia phage RS138 (39.6kb, circular, complete genome)
- Klebsiella phage ST147-VIM1phi7.1 (20 contigs, consensus detection)

### ❌ What This Workflow Does NOT Detect (RNA Viruses)

**Not detectable with DNA-seq data**:
- Influenza viruses (8 segmented RNA genome)
- Coronaviruses (SARS-CoV-2, MERS)
- HIV (retrovirus, unless integrated)
- Noroviruses, Dengue, Zika

**Why**: DNA sequencing does not capture RNA molecules

**Solution**: Use Nanopore RNA-seq or Direct RNA-seq for RNA viruses

---

## 🎓 Understanding Results

### Consensus Virus Example:

```
Klebsiella phage ST147-VIM1phi7.1
  SPAdes: 13 contigs
  MEGAHIT: 7 contigs
  Agreement: 0.54 (54%) ← High confidence! ✅
```

**Interpretation**:
- Both assemblers independently detected this phage
- Agreement >0.5 = Reliable detection
- Not likely to be false positive or assembly artifact

### Three Contig Sets Example:

```
Sample: llnl_66d1047e (Long-read)

Set 1 - metaFlye All Contigs:
  Total: 1,212 contigs
  Content: Complete metagenome (bacteria + viruses + eukaryotes)

Set 2 - viralFlye Linear Viruses:
  Total: 0 contigs
  Content: No linear DNA viruses meeting criteria

Set 3 - viralFlye Circular Viruses: ⭐
  Total: 1 contig (contig_1085)
  Identity: Ralstonia phage RS138 (94.5% BLAST match)
  Size: 39,632 bp
  RPKM: 25,232 (very high abundance!)
  Completeness: Complete circular genome
```

---

## 🔑 Critical Concepts

### 1. **Agreement Ratio**

For consensus viruses (detected by both assemblers):

```
Agreement = min(SPAdes_count, MEGAHIT_count) / max(SPAdes_count, MEGAHIT_count)
```

**Interpretation**:
- **> 0.7**: Very high confidence ⭐⭐⭐
- **0.5-0.7**: High confidence ⭐⭐ (Recommended for publication)
- **0.3-0.5**: Medium confidence ⭐ (Consider validation)
- **< 0.3**: Low confidence ⚠️ (Needs verification)

### 2. **Circular vs Linear Viruses**

**Circular contigs** (Highest quality):
- Closed circular genomes = **Complete viral genomes**
- Typical: Bacteriophages, small DNA viruses
- High confidence for downstream analysis
- Example: Your Ralstonia phage (39.6kb circular)

**Linear contigs**:
- Partial viral genomes or linear viruses
- May represent viral fragments
- Still valuable but less complete

### 3. **Kraken2 Database Impact**

**Viral reference database** (`kraken2_Viral_ref`):
```
Sample composition:
├── Bacteria: ~95% → Classified as "Unclassified" (not in viral DB)
├── Viruses: ~1% → Classified correctly ✅
└── Others: ~4% → Classified as "Unclassified"
```

**Result**: ~99% Unclassified is **normal** when using viral database

**Alternative**: Use standard database (`kraken2_standard`) for complete microbiome classification

### 4. **DNA Sequencing Limitation**

```
DNA extraction + DNA sequencing:
  → Captures: DNA viruses ✅, Bacteria ✅, Eukaryotic DNA ✅
  → Does NOT capture: RNA viruses ❌

RNA extraction + RNA sequencing:
  → Captures: RNA viruses ✅, RNA transcripts ✅
  → May capture: DNA viruses (if total nucleic acid extraction)
```

**Critical**: The limitation is in **sample preparation**, not the tools!

---

## 📈 Technology Stack

### Short-Read Tools:
- **QC**: fastp (Conda)
- **Assembly**: MEGAHIT, SPAdes (Apptainer containers)
- **Mapping**: Bowtie2 (Apptainer containers)
- **Abundance**: Python + samtools (Conda + auto symlink)
- **Classification**: Kraken2 (Conda)
- **Merge**: Python + pandas (Conda) 🆕

### Long-Read Tools:
- **Assembly**: metaFlye (Apptainer container)
- **Viral ID**: viralFlye (Pre-installed Conda env) 🆕
- **Mapping**: Minimap2 + samtools (Conda + auto symlink)
- **Abundance**: Python + samtools (Conda + auto symlink)
- **Classification**: Kraken2 (Conda)

### Infrastructure:
- **Workflow engine**: Nextflow DSL2
- **Scheduler**: SLURM
- **Containers**: Apptainer/Singularity
- **Environments**: Conda/Mamba

---

## 🏆 Unique Advantages

### 1. **Comprehensive Virus Analysis**

**Short reads**:
- Consensus detection (both assemblers) = High confidence
- Agreement scoring
- Separate SPAdes-only and MEGAHIT-only lists

**Long reads**:
- Three-tier analysis (all contigs + linear viruses + circular viruses)
- Complete viral genomes (circular)
- DNA virus-specific identification

### 2. **Abundance Quantification**

**Every contig** from every assembler gets:
- Length
- Mapped reads count
- RPM (normalized to sequencing depth)
- RPKM (normalized to sequencing depth AND contig length)

### 3. **Automatic Problem Solving**

- ✅ libbz2.so.1.0 dependency → Auto symlink
- ✅ Python version conflicts → Explicit conda Python
- ✅ Container mount issues → Auto-configured `--no-mount`
- ✅ viralFlye installation → Pre-installed env + PYTHONPATH

### 4. **Intelligent Execution**

- Auto-detects available samplesheets
- Runs only available data types
- Skips missing inputs gracefully
- Three dedicated run scripts (hybrid/short/long)

---

## 🔬 Scientific Applications

### 1. **Phage Discovery**
- Use long-read data
- viralFlye identifies complete phage genomes (circular)
- High RPKM = Abundant phages
- Example: Ralstonia phage RS138

### 2. **Antibiotic Resistance Monitoring**
- Detect resistance-associated phages
- Example: Klebsiella phage ST147-VIM1phi7.1 (VIM-1 resistance)
- Consensus detection ensures reliability

### 3. **Microbiome Characterization**
- Use standard Kraken2 database
- Get complete bacterial + viral profiles
- Understand phage-host relationships

### 4. **Comparative Metagenomics**
- Compare short-read vs long-read results
- Validate findings across platforms
- Combine strengths of both approaches

---

## ⚙️ Resource Requirements

### Minimal Setup:
- Short reads only: ~600 GB RAM (for SPAdes)
- Long reads only: ~150 GB RAM

### Typical Runtime:
- Short reads: 1-2 days (mainly SPAdes)
- Long reads: 6-12 hours (mainly metaFlye)
- viralFlye: 2-6 hours (depends on assembly size)

### Storage:
- Work directory: 50-200 GB (temporary)
- Results: 10-50 GB (permanent)

---

## 📚 Documentation Guide

| Document | Purpose | When to Read |
|----------|---------|--------------|
| **QUICK_START.md** | Get started fast | First time user |
| **README_HYBRID.md** | Complete reference | Detailed usage |
| **DNA_VS_RNA_VIRUSES.md** | Understand limitations | Planning experiments |
| **VIRALFLYE_INFO.md** | viralFlye deep dive | Long-read virus analysis |
| **WORKFLOW_SUMMARY.md** | This file | Overview |

---

## 🎯 Decision Tree

```
What data do you have?

├─ Illumina paired-end only
│  └─ Use: run_short_only.sh
│     └─ Get: Consensus virus list ⭐
│
├─ Nanopore/PacBio only
│  └─ Use: run_long_only.sh
│     └─ Get: Three contig sets + complete viral genomes ⭐
│
└─ Both Illumina + Nanopore/PacBio
   └─ Use: run_hybrid_workflow.sh
      └─ Get: Complete analysis (all features) ⭐⭐

Do you want RNA viruses (flu, COVID)?
├─ YES → Need RNA-seq data (not DNA-seq)
│        See: DNA_VS_RNA_VIRUSES.md
└─ NO → Current workflow is perfect ✅
```

---

## ✅ Completed Enhancements

| Feature | Status | Version |
|---------|--------|---------|
| RPM/RPKM for all assemblers | ✅ Complete | 1.0 |
| Long-read support | ✅ Complete | 2.0 |
| viralFlye integration | ✅ Complete | 3.0 |
| Virus consensus analysis | ✅ Complete | 3.0 🆕 |
| Three contig sets | ✅ Complete | 3.0 🆕 |
| DNA vs RNA documentation | ✅ Complete | 3.0 🆕 |
| Auto dependency resolution | ✅ Complete | 3.0 |

---

## 🎊 Summary

This is a **production-ready**, **publication-quality** metagenome analysis workflow with:

- ✨ Multi-platform support (Illumina + Nanopore + PacBio)
- ✨ Comprehensive abundance quantification (RPM/RPKM)
- ✨ Intelligent virus detection (consensus + complete genomes)
- ✨ Automatic dependency management
- ✨ Detailed documentation
- ✨ Three flexible running modes

**Perfect for**: Microbiome research, phage discovery, virus ecology, antibiotic resistance monitoring

**Current limitation**: DNA viruses only (for RNA viruses, use RNA-seq)

**Ready to use!** 🧬✨
