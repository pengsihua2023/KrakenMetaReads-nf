# 📚 Documentation Index

Quick guide to all documentation files in this workflow.

## 🎯 Start Here

### First Time Users
👉 **[QUICK_START.md](QUICK_START.md)**
- 3-minute setup guide
- Three running modes explained
- Essential prerequisites
- Quick results check

### Complete Reference
👉 **[README_HYBRID.md](README_HYBRID.md)**
- Full workflow documentation
- All parameters explained
- Complete output structure
- Troubleshooting guide

---

## 📖 By Topic

### Understanding Workflow Features

**[WORKFLOW_SUMMARY.md](WORKFLOW_SUMMARY.md)**
- Architecture diagrams
- All features explained
- Real-world result examples
- Decision tree for choosing mode

**[LATEST_UPDATES.md](LATEST_UPDATES.md)**
- Version 3.0 new features
- Virus consensus analysis explained
- viralFlye integration details
- Migration guide from previous versions

### Virus Detection

**[DNA_VS_RNA_VIRUSES.md](DNA_VS_RNA_VIRUSES.md)** ⭐ Important!
- Why only DNA viruses are detected
- RNA virus detection alternatives
- Kraken2 capability clarification
- Comprehensive virus type tables
- Decision tree for experimental design

**[VIRALFLYE_INFO.md](VIRALFLYE_INFO.md)**
- viralFlye deep dive (Chinese + English)
- Integration workflow
- Parameter explanations
- Output structure
- Example analysis steps

### Getting Started

**[FINAL_GUIDE.md](FINAL_GUIDE.md)**
- Step-by-step usage
- Best practices
- Success checklist
- Recommended workflows
- Next steps after results

---

## 🎓 By User Type

### Beginner (First time with metagenomics)

Read in this order:
1. **QUICK_START.md** - Setup basics
2. **DNA_VS_RNA_VIRUSES.md** - Understand what you can detect
3. **FINAL_GUIDE.md** - Step-by-step guide
4. **README_HYBRID.md** - Full reference (as needed)

### Intermediate (Familiar with metagenomics)

Focus on:
1. **QUICK_START.md** - Quick setup
2. **WORKFLOW_SUMMARY.md** - Feature overview
3. **README_HYBRID.md** - Parameter reference
4. **VIRALFLYE_INFO.md** - If using long reads

### Advanced (Experienced, customizing workflow)

Reference:
1. **README_HYBRID.md** - Complete parameter list
2. **LATEST_UPDATES.md** - Technical details
3. **VIRALFLYE_INFO.md** - viralFlye customization
4. Workflow code files (`.nf`, `.config`)

---

## 🔬 By Research Goal

### Goal: Discover Novel Phages

**Essential reading**:
1. **QUICK_START.md** → Option 2 (Long reads only)
2. **VIRALFLYE_INFO.md** → Circular viruses section
3. **FINAL_GUIDE.md** → Phage discovery pipeline

**Key output**: `results_long/abundance_viralflye_circular/`

### Goal: Monitor Antibiotic Resistance Phages

**Essential reading**:
1. **QUICK_START.md** → Option 1 (Short reads only)
2. **LATEST_UPDATES.md** → Virus consensus analysis
3. **README_HYBRID.md** → Consensus section

**Key output**: `results_short/merged_reports/*_virus_consensus.txt`

### Goal: Characterize Microbiome + Virome

**Essential reading**:
1. **QUICK_START.md** → Option 3 (Hybrid mode)
2. **DNA_VS_RNA_VIRUSES.md** → Understand limitations
3. **WORKFLOW_SUMMARY.md** → Three contig sets

**Key outputs**: 
- `results_long/abundance_flye/` (all contigs)
- `results_long/abundance_viralflye_circular/` (complete viruses)

### Goal: Detect RNA Viruses (Influenza, COVID, etc.)

**Essential reading**:
1. **DNA_VS_RNA_VIRUSES.md** ⭐⭐⭐ **Read this first!**
2. Understand: Current workflow **cannot** detect RNA viruses
3. Alternative: Use Nanopore RNA-seq (documented in DNA_VS_RNA_VIRUSES.md)

---

## 📊 By Output File Type

### Want to understand:

**Consensus viruses** (short reads):
- Read: README_HYBRID.md → "Virus Consensus Analysis" section
- Read: LATEST_UPDATES.md → Feature #1
- Check: `results_short/merged_reports/*_virus_consensus.txt`

**Three contig sets** (long reads):
- Read: README_HYBRID.md → "viralFlye Integration" section
- Read: VIRALFLYE_INFO.md → Complete guide
- Check: `results_long/viralflye/` + `abundance_viralflye_*/`

**RPM/RPKM abundance**:
- Read: README_HYBRID.md → "Features" section
- All assemblers output: `abundance_*/` directories
- Format: Contig_ID, Length, Mapped_Reads, RPM, RPKM

**Kraken2 classification**:
- Read: DNA_VS_RNA_VIRUSES.md → "Kraken2 Capability" section
- Understand: Can classify any sequence, but limited by input data
- Check: `kraken2_*/` directories

---

## 🛠️ Troubleshooting Guides

### Common Issues:

| Issue | Document | Section |
|-------|----------|---------|
| viralFlye errors | VIRALFLYE_INFO.md | Installation |
| High % unclassified | DNA_VS_RNA_VIRUSES.md | Kraken2 Capability |
| No RNA viruses found | DNA_VS_RNA_VIRUSES.md | Full document |
| Python/conda errors | README_HYBRID.md | Troubleshooting |
| Container errors | README_HYBRID.md | Troubleshooting |
| No circular viruses | LATEST_UPDATES.md | Troubleshooting |

---

## 📋 Quick Reference Cards

### File Naming Convention:

| Pattern | Content |
|---------|---------|
| `*_abundance.txt` | RPM/RPKM per contig |
| `*_summary.txt` | Statistical summary |
| `*_report.txt` | Kraken2 hierarchical report |
| `*_classification.txt` | Kraken2 per-read classification |
| `*_consensus.txt` | 🆕 Virus consensus analysis |
| `*viralFlye.fasta` | 🆕 Viral contig sequences |

### Directory Naming:

| Directory | Content | Platform |
|-----------|---------|----------|
| `results_short/` | Short-read results | Illumina |
| `results_long/` | Long-read results | Nanopore/PacBio |
| `*_megahit/` | MEGAHIT-specific | Short |
| `*_spades/` | SPAdes-specific | Short |
| `*_flye/` | metaFlye all contigs | Long |
| `*_viralflye_linear/` | Linear DNA viruses | Long |
| `*_viralflye_circular/` | Circular DNA viruses | Long |
| `merged_reports/` | Cross-assembler comparison | Short |
| `viralflye/` | Original viral FASTA | Long |

---

## 🎯 Documentation Maintenance

### Current (Version 3.0):
- ✅ All documents updated (November 10, 2025)
- ✅ Consistent terminology
- ✅ Real examples from test runs
- ✅ Cross-referenced

### To Add a New Feature:

Update these documents:
1. `README_HYBRID.md` - Add to Features + relevant sections
2. `WORKFLOW_SUMMARY.md` - Add to architecture + key features
3. `QUICK_START.md` - Add to output or usage if user-facing
4. `LATEST_UPDATES.md` - Document the change
5. This file - Update index if new document created

---

## 💡 Tips for Reading

### Color Coding in Docs:

- ✅ = Supported/Available/Recommended
- ❌ = Not supported/Not available
- ⚠️ = Warning/Caution/Medium confidence
- 🆕 = New in Version 3.0
- ⭐ = Important/Featured
- 🦠 = Virus-related
- 🧬 = Genomics/Biology

### Symbols:

- **Bold** = Important terms/features
- `code` = File names, commands, parameters
- > Quote = Notes, warnings
- Tables = Comparisons, options

---

## 📞 Still Have Questions?

### Check in this order:

1. **This index** - Find the right document
2. **Specific document** - Read relevant section
3. **README_HYBRID.md** - Comprehensive reference
4. **Workflow logs** - `.nextflow.log`, SLURM output
5. **Work directories** - `work/*/` for failed jobs

---

## 🎊 Document Summary

| Document | Size | Purpose | When to Read |
|----------|------|---------|--------------|
| **README_HYBRID.md** | ~460 lines | Complete reference | Always available |
| **QUICK_START.md** | ~180 lines | Fast setup | First time |
| **WORKFLOW_SUMMARY.md** | ~350 lines | Feature overview | Understanding workflow |
| **FINAL_GUIDE.md** | ~280 lines | Best practices | Getting started |
| **DNA_VS_RNA_VIRUSES.md** | ~340 lines | Limitations + alternatives | Planning experiments |
| **VIRALFLYE_INFO.md** | ~260 lines | viralFlye details | Long-read virus work |
| **LATEST_UPDATES.md** | ~400 lines | Version 3.0 changes | Current version info |
| **DOCUMENTATION_INDEX.md** | This file | Find what you need | Navigation |

**Total documentation**: ~2,500 lines of comprehensive guidance! 📚

---

**Choose your starting point above and dive in!** 🚀

