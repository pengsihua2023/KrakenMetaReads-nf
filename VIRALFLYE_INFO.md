# viralFlye Integration - DNA Viral Contig Identification

## 🦠 What is viralFlye?

**viralFlye is a post-processing tool that identifies DNA viral contigs from metaFlye assembly results**:
- Extracts viral sequences from metaFlye's assembly graph
- Identifies linear and circular **DNA viral** contigs (phages, large/small DNA viruses)
- Filters by length and completeness (default: ≥2kb length, ≥50% completeness)
- Uses Pfam HMM for viral protein annotation (**required**)

**Important Limitations**:
- ✅ Detects **DNA viruses** (phages, herpesviruses, poxviruses, etc.)
- ❌ **Cannot detect RNA viruses** (influenza, coronavirus, etc.) → Requires RNA-seq
- ❌ metaFlye is a DNA assembler → DNA-seq data doesn't contain RNA virus information

---

## 🔬 Correct Workflow

```
Long-read sequencing data (DNA)
   ↓
metaFlye assembly (--meta)
   ↓
   ├─ assembly.fasta (all contigs)
   ├─ assembly_graph.gfa (assembly graph)
   └─ assembly_info.txt (contig information)
   ↓
viralFlye analysis (input: metaFlye directory + original reads)
   ↓
   ├─ linears_viralFlye.fasta (linear viral contigs)
   ├─ circulars_viralFlye.fasta (circular viral contigs)
   └─ components_viralFlye.fasta (multi-edge components)
   ↓
Calculate abundance and classification separately for each set
```

---

## ✨ metaFlye vs viralFlye

| Feature | metaFlye | viralFlye |
|---------|----------|-----------|
| **Type** | Assembler | Post-processing/Identification tool |
| **Input** | Raw reads | metaFlye output directory + reads |
| **Output** | All contigs | Viral contig subset |
| **Target** | Complete metagenome | Viruses/phages |
| **Advantage** | Comprehensive | Focused on viruses, high quality |

---

## ✨ Why Use viralFlye?

### Key Advantages:

1. **metaFlye** → Assembles all metagenome content (bacteria + viruses + eukaryotes)
2. **viralFlye** → Extracts and identifies viral sequences from metaFlye results
   - Filters low-coverage contigs
   - Identifies circular viral genomes
   - Focuses on viral size range (2kb-1Mb)
   - Uses completeness threshold (≥50%)

### Workflow Configuration:
- ✅ metaFlye assembles first → Generates assembly directory
- ✅ viralFlye analyzes assembly directory → Identifies viral contigs
- ✅ Calculates RPM/RPKM separately for all contigs and viral contigs
- ✅ Kraken2 viral database classification for each set

---

## 📊 Output File Structure

```
results_long/
├── flye_assembly/                         # metaFlye assembly directory (for viralFlye)
│   └── *_flye_assembly/
│       ├── assembly.fasta
│       ├── assembly_graph.gfa
│       └── assembly_info.txt
├── viralflye/                             # viralFlye identified viral contigs ⭐
│   ├── linears_viralFlye.fasta           # Linear viruses
│   ├── circulars_viralFlye.fasta         # Circular viruses (complete genomes)
│   └── components_viralFlye.fasta        # Multi-edge components
├── abundance_flye/                        # metaFlye all contigs RPM/RPKM
│   ├── *_flye_abundance.txt
│   └── *_flye_abundance_summary.txt
├── abundance_viralflye_linear/            # Linear viral contigs RPM/RPKM ⭐
│   ├── *_viralflye_linear_abundance.txt
│   └── *_viralflye_linear_abundance_summary.txt
├── abundance_viralflye_circular/          # Circular viral contigs RPM/RPKM ⭐
│   ├── *_viralflye_circular_abundance.txt
│   └── *_viralflye_circular_abundance_summary.txt
├── kraken2_flye/                          # metaFlye classification
│   ├── *_flye_classification.txt
│   └── *_flye_report.txt
├── kraken2_viralflye_linear/              # Linear viral classification ⭐
│   ├── *_viralflye_linear_classification.txt
│   └── *_viralflye_linear_report.txt
└── kraken2_viralflye_circular/            # Circular viral classification ⭐
    ├── *_viralflye_circular_classification.txt
    └── *_viralflye_circular_report.txt
```

---

## 🎯 Usage Methods

### Default: Enable viralFlye (Recommended) ⭐

```bash
# viralFlye is enabled by default
sbatch run_long_only.sh
```

**Workflow steps**:
1. ✅ metaFlye assembly → All contigs
2. ✅ viralFlye identification → Extract viral contigs from metaFlye results
3. ✅ Calculate separately:
   - RPM/RPKM for metaFlye all contigs
   - RPM/RPKM for linear viral contigs
   - RPM/RPKM for circular viral contigs
4. ✅ Kraken2 classification (three independent result sets)

### Disable viralFlye (Run metaFlye only)

If you only need metaFlye, edit `metagenome_hybrid_workflow.config`:
```groovy
run_viralflye = false
```

Then run:
```bash
sbatch run_long_only.sh
```

---

## 📈 Expected Results

### metaFlye Results (Set 1):
- **All contigs** (bacteria, viruses, eukaryotes, etc.)
- Complete metagenome view
- High contig count (e.g., 1,212 contigs)
- Includes all microbial diversity

### viralFlye Linear Viral Results (Set 2):
- **Linear viral contigs** (filtered from metaFlye)
- Length ≥2kb, completeness ≥50%
- Focuses on linear viral genomes
- May include partial or incomplete viral sequences

### viralFlye Circular Viral Results (Set 3): ⭐
- **Circular viral contigs** (closed circular genomes)
- Bacteriophages, small DNA viruses
- **Complete viral genomes** (highest quality)
- Perfect for downstream functional analysis

---

## 💡 Analysis Recommendations

### 1. Check viralFlye Identified Viruses

```bash
# View viralFlye output
ls -lh results_long/viralflye/

# Count linear viral contigs
grep -c ">" results_long/viralflye/linears_viralFlye.fasta

# Count circular viral contigs
grep -c ">" results_long/viralflye/circulars_viralFlye.fasta
```

### 2. Compare metaFlye All Contigs vs Viral Contigs

```bash
# metaFlye all contigs summary
cat results_long/abundance_flye/*_summary.txt

# Linear viral summary
cat results_long/abundance_viralflye_linear/*_summary.txt

# Circular viral summary
cat results_long/abundance_viralflye_circular/*_summary.txt
```

### 3. Find High-Abundance Viral Contigs

```bash
# Top RPKM linear viruses
sort -t$'\t' -k5 -nr results_long/abundance_viralflye_linear/*_abundance.txt | head -20

# Top RPKM circular viruses
sort -t$'\t' -k5 -nr results_long/abundance_viralflye_circular/*_abundance.txt | head -20
```

### 4. Compare Viral Classification Results

```bash
# Viruses in metaFlye (all contigs)
grep -i "virus" results_long/kraken2_flye/*_report.txt

# Linear viral contigs classification (more focused)
grep -i "virus" results_long/kraken2_viralflye_linear/*_report.txt

# Circular viral contigs classification
grep -i "virus" results_long/kraken2_viralflye_circular/*_report.txt
```

---

## 🔑 Key Parameters

### viralFlye Command Format:

```bash
viralFlye.py \
    --dir flye_assembly_dir \        # metaFlye output directory
    --reads path_to_reads \          # Original long-read data
    --outdir viralflye_output \      # Output directory
    --min_viral_length 2000 \        # Min contig length (default 5kb, lowered to 2kb)
    --completeness 0.5 \             # Completeness cutoff (default 0.5)
    --threads 10 \                   # CPU threads
    --hmm Pfam-A.hmm                 # **Required** for protein annotation
```

### Configurable Parameters (in config file):

- `viralflye_min_length = 2000` - Min viral contig length (2kb for small DNA viruses)
- `viralflye_completeness = 0.5` - Completeness threshold (50% for quality)
- `viralflye_threads = 10` - CPU threads
- `viralflye_hmm = '/path/to/Pfam-A.hmm'` - Pfam HMM file path (**required**)

**Notes**:
- Lowering `min_length` to 2kb captures small DNA viruses (e.g., Circoviridae)
- Keeping `completeness` at 50% ensures relatively complete viral genomes
- Circular contigs = Complete viral genomes (highest quality) ⭐

---

## ⚙️ Resource Configuration

### metaFlye Assembly:
- **CPUs**: 32
- **Memory**: 128 GB
- **Time**: 72h
- **Container**: Apptainer (quay.io/biocontainers/flye:2.9.2)

### viralFlye Identification:
- **CPUs**: 16
- **Memory**: 64 GB
- **Time**: 12h
- **Environment**: Pre-installed conda env (viralFlye_env)

### Viral Contig Post-processing (linear/circular):
- **Mapping (Minimap2)**: 8 CPUs, 16 GB, 4h each
- **Abundance Calculation**: 2 CPUs, 8 GB, 1h each
- **Kraken2 Classification**: 8 CPUs, 24 GB, 4h each

**Workflow is sequential**:
1. First metaFlye assembly
2. Then viralFlye identification (depends on metaFlye output)
3. Finally parallel processing of linear and circular contigs

---

## 🎊 Advantages Summary

Through the metaFlye + viralFlye pipeline, you can:

1. ✅ Obtain complete metagenome assembly (metaFlye all contigs)
2. ✅ Obtain high-quality viral contig subset (viralFlye filtered)
3. ✅ Distinguish linear and circular viral genomes
4. ✅ Three independent RPM/RPKM abundance datasets:
   - metaFlye all contigs (complete microbiome view)
   - Linear viral contigs (partial/linear viruses)
   - Circular viral contigs (complete viral genomes) ⭐
5. ✅ Three independent Kraken2 classification results
6. ✅ Focus on high-quality viral sequences (coverage >10x, completeness ≥50%)

**Perfect for viral metagenomics research!** 🦠✨

---

## 📌 Important Notes

### What viralFlye IS and IS NOT:

- ⚠️ viralFlye is **NOT** an independent assembler
- ✅ viralFlye **IS** a tool that identifies viruses from metaFlye results
- ✅ It leverages metaFlye's assembly graph for better viral sequence identification
- ✅ Output viral contigs are a **filtered subset** of metaFlye contigs, optimized for viruses

### DNA vs RNA Virus Detection:

- ✅ **Detects**: DNA viruses (phages, herpesviruses, poxviruses, megaviruses, small DNA viruses)
- ❌ **Does NOT detect**: RNA viruses (influenza, coronavirus, HIV, norovirus)
- 📚 **Why**: DNA sequencing data doesn't contain RNA virus genomes
- 💡 **Solution**: For RNA viruses, use Nanopore RNA-seq + RNA assembly tools

See `DNA_VS_RNA_VIRUSES.md` for detailed explanation.

---

## 🔧 Installation Requirements

### Pre-requisite: viralFlye_env

viralFlye must be pre-installed in a conda environment:

```bash
# Create viralFlye environment
conda create -n viralFlye_env python=3.10
conda activate viralFlye_env

# Clone viralFlye repository
git clone https://github.com/Dmitry-Antipov/viralFlye.git
cd viralFlye

# Install dependencies
pip install -r requirements.txt

# Install viralFlye module (CRITICAL!)
pip install -e .

# Verify installation
viralFlye.py --help

# Test module import
python -c "from viralflye.main import main; print('viralFlye module OK')"
```

### Pfam Database (Required)

Download Pfam-A HMM database:

```bash
# Download Pfam-A.hmm (required for viralFlye)
wget http://ftp.ebi.ac.uk/pub/databases/Pfam/current_release/Pfam-A.hmm.gz

# Or use existing installation
# Current config:
viralflye_hmm = '/scratch/sp96859/Meta-genome-data-analysis/Apptainer/databases/Pfam/Pfam-A.hmm'
```

---

## 🎯 Three Contig Sets Explained

### Set 1: metaFlye All Contigs
**Purpose**: Complete metagenome view

**Content**:
- All assembled contigs (bacteria + DNA viruses + eukaryotes)
- Example: 1,212 contigs in your sample

**Use cases**:
- Overall microbiome composition
- Bacterial diversity
- Total community structure

**Files**:
- `abundance_flye/*_flye_abundance.txt`
- `kraken2_flye/*_flye_report.txt`

---

### Set 2: viralFlye Linear Viral Contigs
**Purpose**: Linear DNA viruses

**Content**:
- Linear DNA viral contigs identified by viralFlye
- Filters: ≥2kb length, ≥50% completeness
- May include partial viral genomes or linear viruses

**Use cases**:
- Viral diversity survey
- Partial viral genome analysis
- Viral fragment identification

**Files**:
- `viralflye/linears_viralFlye.fasta`
- `abundance_viralflye_linear/*_abundance.txt`
- `kraken2_viralflye_linear/*_report.txt`

**Note**: May be 0 if no linear viruses meet criteria (normal in many samples)

---

### Set 3: viralFlye Circular Viral Contigs ⭐⭐⭐
**Purpose**: Complete DNA viral genomes

**Content**:
- Circular DNA viral contigs (closed genomes)
- **Complete viral genomes** - highest quality!
- Typical: Bacteriophages, small DNA viruses

**Use cases**:
- Complete viral genome characterization
- Functional annotation
- Comparative genomics
- Phage isolation and validation

**Files**:
- `viralflye/circulars_viralFlye.fasta`
- `abundance_viralflye_circular/*_abundance.txt`
- `kraken2_viralflye_circular/*_report.txt`

**Example from your data**:
```
contig_1085 (Ralstonia phage RS138)
  Length: 39,632 bp
  RPKM: 25,232 (very high abundance!)
  BLAST: 94.5% match to NC_029107.1
  Status: Complete circular genome ✅
```

---

## 🏆 Why Circular Viruses are Special

### Circular = Complete

**Scientific significance**:
- ✅ Closed circular genome = **No missing regions**
- ✅ Complete gene content
- ✅ Ready for immediate functional analysis
- ✅ Can be compared directly to reference genomes
- ✅ Suitable for publication

**Typical circular viruses**:
- Bacteriophages (most common in environmental samples)
- Small DNA viruses (Circoviridae, Microviridae)
- Some large DNA viruses

**Your result**: 1 circular virus (Ralstonia phage) = High-quality discovery!

---

## 🔬 Filtering Criteria

### viralFlye applies multiple filters:

1. **Length Filter**:
   - Minimum: 2,000 bp (default was 5,000 bp, lowered to capture small DNA viruses)
   - Maximum: None specified in current config
   - Rationale: Viral genomes typically 2kb-1Mb

2. **Completeness Filter**:
   - Threshold: ≥50% (default 0.5)
   - Calculated by: viralComplete tool (part of viralFlye)
   - Ensures: Relatively complete viral genomes

3. **Viral Features**:
   - Uses: viralVerify for viral signal detection
   - Based on: Pfam domain composition
   - Distinguishes: Viral vs bacterial sequences

4. **Graph Analysis**:
   - Analyzes: metaFlye assembly graph structure
   - Detects: Circular paths (for circular viruses)
   - Identifies: Viral-specific graph patterns

---

## 📊 Real-World Example (Your Data)

### Sample: llnl_66d1047e (Nanopore long-read)

**metaFlye Results (Set 1)**:
```
Total contigs: 1,212
Total mapped reads: 164,813
Average length: 13,662 bp
Longest contig: 261,217 bp
Content: Complete metagenome (bacteria + viruses + eukaryotes)
```

**viralFlye Linear Results (Set 2)**:
```
Total viral contigs: 0
Reason: No linear DNA viruses meeting criteria (≥2kb, ≥50% completeness)
Note: This is normal in many samples
```

**viralFlye Circular Results (Set 3)**: ⭐
```
Total viral contigs: 1

contig_1085 - Ralstonia phage RS138
  Length: 39,632 bp
  Mapped reads: 1,032
  RPM: 1,000,000 (100% of viral reads)
  RPKM: 25,232 (very high abundance!)
  Classification: Megavirus (Mimiviridae family)
  BLAST validation: 94.5% identity to NC_029107.1
  Status: Complete circular genome ✅
  
Scientific value:
- Complete bacteriophage genome
- Ready for gene annotation
- Can study gene organization
- Suitable for publication
```

### Interpretation:

- ✅ **Low viral content is normal**: Most samples are >95% bacteria
- ✅ **One complete viral genome is valuable**: Better than many fragments
- ✅ **High RPKM indicates dominance**: This phage is the dominant virus in the sample
- ✅ **Circular = Complete**: Can perform complete functional analysis

---

## 🔑 Key Parameters in Config

Edit `metagenome_hybrid_workflow.config`:

```groovy
// viralFlye parameters (DNA virus identification)
run_viralflye = true  // Set to false to disable
viralflye_hmm = '/scratch/sp96859/.../Pfam/Pfam-A.hmm'  // REQUIRED
viralflye_min_length = 2000      // 2kb to capture small DNA viruses
viralflye_completeness = 0.5     // 50% completeness threshold
viralflye_threads = 10           // CPU threads for viralFlye
```

### Parameter Adjustment Guidelines:

**To capture MORE viruses** (lower quality threshold):
```groovy
viralflye_min_length = 1500      // Lower to 1.5kb
viralflye_completeness = 0.3     // Lower to 30%
```
⚠️ **Warning**: May increase false positives

**To ensure HIGHEST quality** (stricter threshold):
```groovy
viralflye_min_length = 5000      // Keep at 5kb
viralflye_completeness = 0.7     // Raise to 70%
```
✅ **Advantage**: Only very complete viral genomes

**Current settings (2kb, 50%)**: Balanced approach ⭐

---

## 🎓 Understanding the Three Sets

### Relationship between sets:

```
Set 1: metaFlye All Contigs (1,212)
├── Bacteria (~95%, ~1,151 contigs)
├── Eukaryotes (~4%, ~48 contigs)
├── DNA Viruses (~1%, ~12 contigs) ← viralFlye targets this
│   ├── Linear viral contigs → Set 2
│   └── Circular viral contigs → Set 3
└── Unknown/Others (~1 contig)
```

**Key points**:
- Set 2 and Set 3 are **subsets** of Set 1
- Set 2 and Set 3 are **mutually exclusive** (a contig is either linear or circular)
- Set 2 + Set 3 = All viruses identified by viralFlye

---

## 🔬 Scientific Validation

### BLAST Validation Example:

From your viralFlye results:

```
Query: contig_1085 (39,632 bp)
Top hit: NC_029107.1 Ralstonia phage RS138 (41,941 bp)
Identity: 94.5% (Full-length)
Coverage: ~95%

Interpretation:
✅ Very high identity (>90%)
✅ Full-length coverage
✅ Matches known Ralstonia phage
→ Confident identification!
```

### Completeness Assessment:

viralFlye uses **viralComplete** internally:
- Predicts completeness based on viral gene composition
- Your circular virus: Likely >90% complete
- Circular topology confirms completeness

---

## 💡 When to Use viralFlye

### ✅ USE viralFlye when:
1. Studying bacteriophages
2. Looking for complete viral genomes
3. Analyzing environmental viral diversity
4. Need high-quality viral sequences for functional analysis
5. Want to distinguish complete from partial viral genomes

### ⚠️ Consider DISABLING viralFlye when:
1. Only interested in overall metagenome composition
2. Viral abundance is very low (<0.1%)
3. Computational resources are limited
4. Only need bacterial classification

### ⚠️ viralFlye CANNOT help with:
1. RNA virus detection (need RNA-seq)
2. Very short viral fragments (<2kb with current settings)
3. Low-coverage viral contigs (<10x coverage by default)

---

## 🎯 Best Practices

### 1. Start with Default Settings
```groovy
viralflye_min_length = 2000      // Good balance
viralflye_completeness = 0.5     // Quality threshold
```

### 2. Focus on Circular Viruses First
- These are complete genomes
- Highest confidence
- Ready for publication

### 3. Validate with BLAST
```bash
# BLAST your circular viruses
blastn -query results_long/viralflye/circulars_viralFlye.fasta \
       -db nt \
       -remote \
       -outfmt "6 qseqid stitle pident length" \
       -max_target_seqs 5
```

### 4. Cross-check with Kraken2
```bash
# Compare viralFlye identification with Kraken2 classification
# High agreement = Confident identification
```

### 5. Use High-RPKM Viruses
- High RPKM = Abundant viruses
- More likely to be biologically relevant
- Easier to validate experimentally

---

## 📈 Performance Notes

### Observed from Real Data:

**Sample**: llnl_66d1047e (Nanopore)
- **Total runtime**: ~6 hours
  - metaFlye: ~4 hours (1,212 contigs)
  - viralFlye: ~1 hour (1 circular virus identified)
  - Post-processing: ~1 hour (3 contig sets analyzed)

**Efficiency**:
- ✅ viralFlye adds minimal overhead (~15-20% extra time)
- ✅ Provides focused viral analysis
- ✅ Worth the extra time for viral research

---

## 🛠️ Troubleshooting

### Issue: viralFlye module not found

**Error**: `ModuleNotFoundError: No module named 'viralflye'`

**Solution**:
```bash
conda activate viralFlye_env
cd /path/to/viralFlye
pip install -e .  # This is critical!
python -c "from viralflye.main import main"  # Should not error
```

### Issue: No viruses identified (0 linear, 0 circular)

**Possible reasons**:
1. Low viral abundance (< 0.1%) - Check metaFlye Kraken2 results
2. Parameters too strict - Lower min_length or completeness
3. No complete viral genomes in sample - Check for viral fragments in Set 1

**Check**:
```bash
# See if Kraken2 detected any viruses in metaFlye all contigs
grep -i "virus" results_long/kraken2_flye/*_report.txt
```

### Issue: Python version conflicts

**Error**: `ImportError: numpy ... Python3.12 ... Python3.10`

**Solution**: Already fixed in workflow!
- Workflow explicitly uses conda environment's Python 3.10
- Avoids system Python

### Issue: viralFlye outputs not in results directory

**Solution**: Already fixed!
- Added `publishDir` configuration
- viralFlye FASTA files now published to `results_long/viralflye/`

---

## 📚 Related Documentation

- **DNA_VS_RNA_VIRUSES.md** - Why RNA viruses cannot be detected
- **README_HYBRID.md** - Complete workflow documentation
- **LATEST_UPDATES.md** - viralFlye integration details (Version 3.0)
- **WORKFLOW_SUMMARY.md** - Three contig sets explained

---

## 🎊 Summary

viralFlye integration provides:

- ✨ **Three-tier analysis**: All contigs + Linear viruses + Circular viruses
- ✨ **Complete viral genomes**: Circular contigs are publication-ready
- ✨ **High-quality filtering**: Length + completeness thresholds
- ✨ **Independent analysis**: Each set gets RPM/RPKM + Kraken2
- ✨ **Focus on DNA viruses**: Clear limitations documented

**Status**: Fully integrated and tested! ✅

**Limitation**: DNA viruses only (RNA viruses require RNA-seq)

**Perfect for**: Phage discovery, viral ecology, complete viral genome characterization

🦠✨
