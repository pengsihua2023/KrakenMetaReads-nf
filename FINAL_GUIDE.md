# 🎯 Final Usage Guide - Hybrid Metagenome Workflow

Version 3.0 - Complete with Virus Consensus & viralFlye Integration

## ✅ What's Complete

### New Capabilities (Version 3.0)
1. ✨ **Virus Consensus Analysis** - High-confidence virus identification
2. ✨ **viralFlye Integration** - Complete DNA viral genome identification
3. ✨ **Three Contig Sets** - Multi-level viral analysis (metaFlye + linear + circular)
4. ✨ **DNA vs RNA Awareness** - Clear documentation of limitations
5. ✨ **Auto Dependency Resolution** - Python version, symlinks, containers

### Core Features (All Versions)
- ✅ Short-read + Long-read support
- ✅ RPM/RPKM abundance for all assemblers
- ✅ Kraken2 taxonomic classification
- ✅ Automatic environment management

---

## 🚀 Quick Start (3 Steps)

### Step 1: Choose Your Mode

```bash
# For short reads only (Illumina)
sbatch run_short_only.sh

# For long reads only (Nanopore/PacBio)
sbatch run_long_only.sh

# For both (auto-detect)
sbatch run_hybrid_workflow.sh
```

### Step 2: Prepare Samplesheets

**Short reads**: `samplesheet_short.csv`
```csv
sample,fastq_1,fastq_2
sample1,/path/to/R1.fastq.gz,/path/to/R2.fastq.gz
```

**Long reads**: `samplesheet_long.csv`
```csv
sample,fastq_long
sample1,/path/to/reads.fastq.gz
```

### Step 3: Wait for Results

Check completion message in SLURM output.

---

## 📊 What You'll Get

### Short-Read Results (results_short/)

#### Standard Outputs:
- ✅ Quality control reports (fastp)
- ✅ Two assemblies (MEGAHIT + SPAdes)
- ✅ RPM/RPKM for each assembler ⭐
- ✅ Kraken2 classification for each

#### 🆕 Enhanced Outputs:
- ⭐ **Merged comparison** (MEGAHIT vs SPAdes)
- ⭐⭐ **Virus consensus report** - High-confidence viruses only!

**Key file**: `merged_reports/*_virus_consensus.txt`

Example content:
```
Total viral classifications: 45
  ✅ Consensus viruses (detected by BOTH): 28  ← Focus here!
  ⚠️ SPAdes only: 12
  ⚠️ MEGAHIT only: 5

Consensus rate: 62.2%

HIGH CONFIDENCE VIRUSES:
Klebsiella phage ST147-VIM1phi7.1
  SPAdes: 13 contigs
  MEGAHIT: 7 contigs
  Agreement: 0.54 ← Reliable!
```

### Long-Read Results (results_long/)

#### Standard Outputs:
- ✅ metaFlye assembly (all contigs)
- ✅ RPM/RPKM for all contigs ⭐

#### 🆕 Enhanced Outputs (viralFlye):
- ⭐ **Set 1**: metaFlye all contigs (complete metagenome)
- ⭐⭐ **Set 2**: viralFlye linear DNA viruses
- ⭐⭐⭐ **Set 3**: viralFlye circular DNA viruses (complete genomes!)

**Key directories**:
- `viralflye/` - Original viral FASTA files
- `abundance_viralflye_circular/` - Complete viral genomes ⭐⭐⭐

Example result:
```
Circular Viral Contigs Summary
Sample: llnl_66d1047e
Total viral contigs: 1

contig_1085
  Length: 39,632 bp
  RPKM: 25,232 (very high!)
  Identity: Ralstonia phage RS138 (94.5% match)
  Status: Complete circular genome ✅
```

---

## 🦠 Understanding Virus Detection

### What Gets Detected?

**DNA Viruses** (✅ Detected):
- Bacteriophages - Most common in environmental samples
- Large DNA viruses - Herpesviruses, Poxviruses, Megaviruses
- Small DNA viruses - Circoviridae (~2kb)

**RNA Viruses** (❌ NOT Detected):
- Influenza, Coronavirus, HIV, Norovirus, Dengue
- **Why**: DNA-seq data doesn't contain RNA virus genomes
- **Solution**: Use Nanopore RNA-seq

**See**: `DNA_VS_RNA_VIRUSES.md` for complete explanation

### Why 99% Unclassified?

**If using viral database** (`kraken2_Viral_ref`):
```
Your sample: ~95% bacteria, ~1% viruses, ~4% others
Kraken2 viral DB: Only has virus references

Result:
- Viruses: Classified ✅ (~1%)
- Bacteria: Unclassified ❌ (~95%, DB doesn't have bacteria)
- Others: Unclassified ❌ (~4%)
→ Total unclassified: ~99% ← Normal!
```

**Solution**: Use standard Kraken2 database for complete classification

---

## 🔧 Configuration Files

### metagenome_hybrid_workflow.config

**Key settings to review**:

```groovy
// Paths
input_short = 'samplesheet_short.csv'
outdir_short = 'results_short'
input_long = 'samplesheet_long.csv'
outdir_long = 'results_long'

// Kraken2 database
kraken2_db = '/scratch/sp96859/.../kraken2_Viral_ref'  // Viral DB

// Long-read platform
long_read_type = 'nanopore'  // or 'pacbio', 'pacbio-hifi'

// viralFlye (DNA virus identification)
run_viralflye = true
viralflye_hmm = '/scratch/sp96859/.../Pfam/Pfam-A.hmm'  // REQUIRED
viralflye_min_length = 2000       // 2kb for small DNA viruses
viralflye_completeness = 0.5      // 50% completeness threshold

// Apptainer
runOptions = '--no-mount /lscratch'  // For clusters without /lscratch
```

---

## 🎓 Advanced Usage

### Disable viralFlye (Long Reads)

If you only want metaFlye without viral identification:

Edit `metagenome_hybrid_workflow.config`:
```groovy
run_viralflye = false
```

### Change Kraken2 Database

For complete microbiome (not just viruses):

Edit run script:
```bash
KRAKEN2_DB="/path/to/kraken2_standard"  # Bacteria + Viruses + Eukaryotes
```

### Adjust viralFlye Sensitivity

For more viral contigs (lower quality threshold):

Edit config:
```groovy
viralflye_min_length = 1500       // Lower to 1.5kb
viralflye_completeness = 0.3      // Lower to 30%
```

**Warning**: May increase false positives

---

## 🛠️ Troubleshooting

### Problem: viralFlye module not found

**Solution**:
```bash
conda activate viralFlye_env
cd /path/to/viralFlye
pip install -e .
python -c "from viralflye.main import main"  # Should not error
```

### Problem: No viruses detected by viralFlye

**Possible reasons**:
1. Low viral abundance in sample (common)
2. No complete viral genomes (fragments only)
3. Parameters too strict

**Check**:
```bash
# See if Kraken2 detected viruses in metaFlye
grep -i virus results_long/kraken2_flye/*_report.txt

# If yes → viralFlye parameters may be too strict
# If no → Sample has low viral content
```

### Problem: High percentage unclassified

**If using viral database**: Normal! Bacteria aren't in the viral DB.

**Solution**: Use standard Kraken2 database to classify bacteria too.

### Problem: Pandas/numpy errors

**Solution**: The workflow now auto-manages this with conda environments.

If still occurs:
```bash
rm -rf /scratch/sp96859/.../conda_cache/
rm -rf work/
sbatch run_[your_script].sh
```

---

## 📖 Recommended Workflow

### For DNA Virus Discovery:

1. **Start with long reads** (`run_long_only.sh`)
   - Get complete viral genomes (viralFlye circular)
   - High-quality, publication-ready

2. **Validate with short reads** (`run_short_only.sh`)
   - Check consensus viruses
   - Agreement >0.5 = High confidence

3. **Combine results**
   - Long reads: Complete viral genomes
   - Short reads: Validation + additional fragments

### For Complete Microbiome Analysis:

1. **Use standard Kraken2 database**
   - See bacteria + viruses + eukaryotes

2. **Run both short + long reads**
   - Short: High resolution for abundant species
   - Long: Complete genomes for novel species

3. **Analyze separately**:
   - Bacteria: From metaFlye Set 1 classification
   - Viruses: From viralFlye Sets 2+3

---

## 🎊 Success Checklist

After workflow completion:

### Short Reads:
- [ ] Quality control reports generated
- [ ] MEGAHIT abundance calculated
- [ ] SPAdes abundance calculated
- [ ] Merged report created
- [ ] **Virus consensus report generated** 🆕
  - [ ] Consensus viruses listed
  - [ ] Agreement ratios calculated

### Long Reads:
- [ ] metaFlye assembly completed
- [ ] **viralFlye viral contigs identified** 🆕
  - [ ] Linear viral FASTA exists
  - [ ] Circular viral FASTA exists
- [ ] Three abundance files created (all + linear + circular)
- [ ] Three Kraken2 classifications completed

---

## 💡 Next Steps After Results

### 1. Identify High-Confidence Viruses

**Short reads**:
```bash
# Focus on consensus viruses
cat results_short/merged_reports/*_virus_consensus.txt
# Look for Agreement >0.5
```

**Long reads**:
```bash
# Focus on circular viruses (complete genomes)
cat results_long/abundance_viralflye_circular/*_abundance.txt
# High RPKM = Abundant viruses
```

### 2. Extract Viral Sequences

For downstream analysis (gene annotation, phylogeny):

```bash
# Circular viral genomes (highest quality)
cp results_long/viralflye/circulars_viralFlye.fasta my_viruses.fasta

# Or specific contigs based on abundance
# Filter by RPKM threshold, etc.
```

### 3. Functional Annotation

```bash
# Use Prokka or Pharokka for phage annotation
prokka --kingdom Viruses my_viruses.fasta

# Or BLAST against viral protein database
```

### 4. Validate Findings

- Compare short-read consensus with long-read results
- Check if same viruses appear in both platforms
- High agreement = Very reliable discovery

---

## 📞 Support

### Check Logs:
```bash
cat .nextflow.log               # Nextflow execution log
cat Hybrid_Metagenome_*.out    # SLURM output
cat Hybrid_Metagenome_*.err    # SLURM errors
```

### Inspect Failed Jobs:
```bash
cd work/xx/xxxxx...  # Work directory from error message
cat .command.sh      # Executed command
cat .command.out     # Command output
cat .command.err     # Command errors
```

---

## 🏆 What Makes This Workflow Special

1. **Consensus validation** - Only short-read workflow with built-in consensus analysis
2. **Complete viral genomes** - viralFlye identifies circular (complete) genomes
3. **Three-tier analysis** - Multi-level viral investigation (all/linear/circular)
4. **Publication ready** - High-confidence results suitable for scientific publication
5. **Fully automated** - From FASTQ to publication-ready results
6. **Clear limitations** - Explicit about DNA-only detection

---

## 🎯 Final Recommendations

### For Phage Research:
- ✅ Use long reads (`run_long_only.sh`)
- ✅ Focus on viralFlye circular contigs
- ✅ High RPKM circular viruses = Your discoveries!

### For General Virology:
- ✅ Use both short + long reads
- ✅ Short reads: Consensus list
- ✅ Long reads: Complete genomes
- ✅ Cross-validate findings

### For Microbiome Studies:
- ✅ Use standard Kraken2 database
- ✅ Analyze bacteria from Set 1 (metaFlye all contigs)
- ✅ Study phage-host relationships

### For RNA Viruses:
- ⚠️ This workflow won't work
- ✅ Use Nanopore RNA-seq instead
- ✅ See `DNA_VS_RNA_VIRUSES.md` for alternatives

---

## 🎊 You're Ready!

Everything is configured and documented. Just run:

```bash
sbatch run_long_only.sh   # or your chosen mode
```

And explore the results! 🧬✨

**Happy virus hunting!** 🦠🔬
