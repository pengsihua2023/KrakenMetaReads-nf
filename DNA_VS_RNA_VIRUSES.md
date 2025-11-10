# DNA vs RNA Virus Detection Guide

## Overview

This document explains the **critical difference** between DNA and RNA virus detection in metagenomics, and why this workflow can only detect DNA viruses.

## 🧬 Fundamental Difference

### DNA Sequencing (Current Workflow)

```
Sample → DNA Extraction → Nanopore DNA Sequencing → metaFlye Assembly
            ↓
   Only DNA molecules are captured
            ↓
   DNA viruses ✅  |  RNA viruses ❌
            ↓
   viralFlye + Kraken2
            ↓
   DNA virus classification
```

### RNA Sequencing (For RNA Viruses)

```
Sample → RNA Extraction → cDNA synthesis → Nanopore Sequencing → RNA Assembly
            ↓                  OR
   Only RNA molecules → Direct RNA-seq
            ↓
   RNA viruses ✅  |  DNA viruses (depends)
            ↓
   Kraken2 classification
            ↓
   RNA virus classification
```

---

## ✅ What This Workflow CAN Detect (DNA Viruses)

| Virus Family | Genome Type | Example | Typical Size |
|--------------|-------------|---------|--------------|
| **Caudovirales** | dsDNA | Bacteriophages (T4, λ, Ralstonia phage) | 20-200 kb |
| **Poxviridae** | dsDNA | Vaccinia virus, Monkeypox | 130-375 kb |
| **Herpesviridae** | dsDNA | HSV-1, CMV, EBV | 120-230 kb |
| **Mimiviridae** | dsDNA | Megavirus, Mimivirus | 400 kb-1.5 Mb |
| **Circoviridae** | ssDNA | Circovirus | 1.7-2.3 kb |
| **Adenoviridae** | dsDNA | Human adenovirus | 26-48 kb |

**Why detected**: These viruses have **DNA genomes** that are present in DNA extracted from samples.

---

## ❌ What This Workflow CANNOT Detect (RNA Viruses)

| Virus Family | Genome Type | Example | Typical Size |
|--------------|-------------|---------|--------------|
| **Orthomyxoviridae** | (-) ssRNA, segmented | Influenza A/B/C (8 segments) | 0.9-2.3 kb per segment |
| **Coronaviridae** | (+) ssRNA | SARS-CoV-2, MERS-CoV | 27-32 kb |
| **Retroviridae** | (+) ssRNA (RT) | HIV, HTLV | 9-10 kb |
| **Picornaviridae** | (+) ssRNA | Poliovirus, Norovirus | 7-9 kb |
| **Flaviviridae** | (+) ssRNA | Dengue, Zika, Yellow fever | 9-12 kb |
| **Filoviridae** | (-) ssRNA | Ebola, Marburg | 19 kb |

**Why NOT detected**: These viruses have **RNA genomes** that are NOT present in DNA extracted from samples.

**Exception**: Retroviruses (like HIV) may be detected if integrated into host genome, but this captures the proviral DNA, not the active viral RNA.

---

## 🔍 Why Can't metaFlye Detect RNA Viruses?

### The Problem Chain:

```
1. Sample Collection
   ↓
2. DNA Extraction
   ├─ DNA molecules extracted ✅ (bacteria, DNA viruses, eukaryotes)
   └─ RNA molecules lost ❌ (degraded or not extracted)
   ↓
3. DNA Sequencing (Nanopore)
   ├─ Reads DNA sequences
   └─ RNA virus genomes are RNA, not in the DNA pool
   ↓
4. metaFlye Assembly
   ├─ Assembles DNA sequences
   └─ No RNA virus sequences to assemble
   ↓
5. viralFlye + Kraken2
   ├─ Can find DNA viruses ✅
   └─ Cannot find RNA viruses ❌ (not in data)
```

### Key Point:

- **metaFlye works fine** - it's a great DNA assembler
- **viralFlye works fine** - it can identify DNA viruses accurately  
- **Kraken2 works fine** - it can classify both DNA and RNA viruses

**The limitation is in the SAMPLE PREPARATION**: DNA extraction doesn't capture RNA molecules.

---

## ✅ How to Detect RNA Viruses with Nanopore

### Nanopore Supports RNA Sequencing! 🎉

Nanopore is actually **the best platform for RNA virus detection** because it offers:

1. **Direct RNA Sequencing** (unique to Nanopore)
   - Sequences RNA molecules directly without reverse transcription
   - Preserves RNA modifications (m6A, m5C, etc.)
   - Full-length viral transcripts

2. **cDNA Sequencing** (traditional)
   - Reverse transcription: RNA → cDNA
   - Then sequence cDNA with Nanopore
   - Higher throughput

### Workflow for RNA Viruses:

```bash
# Sample preparation
Sample → RNA Extraction (use RNA extraction kit, not DNA!)
         ↓
# Library preparation (choose one):
Option A: Direct RNA-seq kit → Direct RNA sequencing
Option B: cDNA synthesis kit → cDNA sequencing
         ↓
# Sequencing
Nanopore sequencing
         ↓
# Analysis
Assembly: Trinity, rnaSPAdes, or Flye (for cDNA)
         ↓
Classification: Kraken2 (works for RNA viruses!)
         ↓
# Result
RNA virus genomes identified ✅
```

### Minimal Changes Needed:

Your current workflow can be **mostly reused** for RNA viruses:
1. ✅ Input: cDNA or Direct RNA-seq FASTQ (instead of DNA-seq FASTQ)
2. ✅ Assembly: Trinity or rnaSPAdes (instead of metaFlye for metagenome)
3. ✅ Mapping: Still use Minimap2 (works for RNA)
4. ✅ Abundance: Same RPM/RPKM calculation
5. ✅ Classification: Same Kraken2 (can classify RNA viruses)

---

## 🔬 Kraken2 and Virus Detection

### Important Clarification:

**Kraken2 is NOT limited to DNA viruses!**

Kraken2 database contains:
- DNA virus reference genomes ✅
- RNA virus reference genomes ✅
- Bacterial genomes ✅
- Eukaryotic genomes ✅

**Kraken2 can classify ANY sequence** against its database.

### The Real Limitation:

```
Your sequencing data (DNA-seq):
  - Contains: Bacterial DNA, DNA viruses
  - Does NOT contain: RNA viruses
  ↓
Kraken2 classification:
  - Can match: DNA viruses ✅ (data has them)
  - Cannot match: RNA viruses ❌ (data doesn't have them)
```

**Analogy**: 
- Kraken2 = A universal translator (can translate any language)
- Your data = An English book
- Kraken2 database = Dictionary with English, Chinese, Japanese
- Result: Can translate English ✅, but cannot translate Chinese ❌ because the book doesn't have Chinese text

---

## 📊 Detection Summary Table

| Virus Type | DNA-seq (Current) | RNA-seq | cDNA-seq | Example Viruses |
|------------|-------------------|---------|----------|-----------------|
| **DNA viruses (dsDNA)** | ✅ Detected | ❌ Not captured | ❌ Not captured | Phages, Herpesviruses |
| **DNA viruses (ssDNA)** | ✅ Detected | ❌ Not captured | ❌ Not captured | Circoviruses |
| **RNA viruses (+ssRNA)** | ❌ Not captured | ✅ Detected | ✅ Detected | Coronaviruses, Poliovirus |
| **RNA viruses (-ssRNA)** | ❌ Not captured | ✅ Detected | ✅ Detected | Influenza, Ebola |
| **RNA viruses (dsRNA)** | ❌ Not captured | ✅ Detected | ✅ Detected | Rotavirus |
| **Retroviruses** | ⚠️ If integrated | ✅ Detected | ✅ Detected | HIV |

### Legends:
- **✅ Detected**: Can be found with this sequencing method
- **❌ Not captured**: Not present in this type of sequencing data
- **⚠️ If integrated**: Only detectable if integrated into host genome (rare)

---

## 🎯 Recommendations

### For DNA Virus Studies (Current Setup)
✅ **Your workflow is perfect!**
- metaFlye assembly
- viralFlye identification
- Kraken2 classification
- Expected results: Phages, large DNA viruses

### For RNA Virus Studies
🔧 **Need different sample prep:**
1. Use RNA extraction (not DNA extraction)
2. Use Direct RNA-seq or cDNA-seq library prep
3. Use RNA assembly tools (Trinity, rnaSPAdes)
4. Keep Kraken2 classification (works for RNA!)

### For Comprehensive Virus Studies
🔬 **Use both approaches:**
1. DNA-seq for DNA viruses
2. RNA-seq for RNA viruses
3. Merge results for complete virome

---

## 💡 Common Misconceptions

### ❌ WRONG: "Kraken2 can only classify DNA viruses"
✅ **CORRECT**: Kraken2 can classify BOTH DNA and RNA viruses, but it can only classify what's in your sequencing data.

### ❌ WRONG: "metaFlye cannot handle RNA viruses"
✅ **CORRECT**: metaFlye is a DNA assembler, so it cannot assemble RNA sequences. For RNA, use Trinity or rnaSPAdes.

### ❌ WRONG: "Nanopore cannot sequence RNA"
✅ **CORRECT**: Nanopore is the ONLY commercial platform offering Direct RNA Sequencing! It's excellent for RNA virus detection.

### ❌ WRONG: "viralFlye failed because it didn't find RNA viruses"
✅ **CORRECT**: viralFlye works as designed - it identifies DNA viruses. RNA viruses were never in the DNA-seq data to begin with.

---

## 🔧 Practical Examples

### Example 1: Wastewater Monitoring for SARS-CoV-2

**Goal**: Detect coronavirus (RNA virus)

**WRONG Approach ❌**:
```bash
Wastewater → DNA extraction → DNA-seq → metaFlye → viralFlye
# Result: No coronavirus (it's an RNA virus!)
```

**CORRECT Approach ✅**:
```bash
Wastewater → RNA extraction → cDNA-seq → Trinity → Kraken2
# Result: Coronavirus detected!
```

### Example 2: Phage Discovery in Sewage

**Goal**: Identify bacteriophages (DNA viruses)

**CORRECT Approach ✅**:
```bash
Sewage → DNA extraction → DNA-seq → metaFlye → viralFlye
# Result: Many phages identified! (Your current workflow)
```

### Example 3: Complete Virome Analysis

**Goal**: All viruses (DNA + RNA)

**CORRECT Approach ✅**:
```bash
Sample → Split into two aliquots
         ↓                    ↓
    DNA extraction      RNA extraction
         ↓                    ↓
    DNA-seq              cDNA-seq
         ↓                    ↓
    metaFlye + viralFlye  Trinity
         ↓                    ↓
    DNA viruses          RNA viruses
         ↓                    ↓
         Merge results
         ↓
    Complete virome!
```

---

## 📚 Further Reading

### For RNA Virus Detection:
- **Nanopore Direct RNA Sequencing**: https://nanoporetech.com/applications/rna-sequencing
- **Trinity RNA-seq Assembler**: https://github.com/trinityrnaseq/trinityrnaseq
- **rnaSPAdes**: https://github.com/ablab/spades

### For DNA Virus Detection:
- **viralFlye**: https://github.com/Dmitry-Antipov/viralFlye
- **metaFlye**: https://github.com/fenderglass/Flye

### Virus Classification:
- **Kraken2**: https://github.com/DerrickWood/kraken2
- **NCBI Viral Genomes**: https://www.ncbi.nlm.nih.gov/genome/viruses/

---

## ✅ Quick Decision Tree

```
Do you want to detect RNA viruses (flu, COVID, etc.)?
├─ YES → Use RNA extraction + RNA-seq
│         └─ Nanopore Direct RNA-seq or cDNA-seq
│         └─ Trinity/rnaSPAdes assembly
│         └─ Kraken2 classification ✅
│
└─ NO → Want DNA viruses (phages, herpesviruses)?
         └─ Use DNA extraction + DNA-seq (current setup) ✅
         └─ metaFlye + viralFlye ✅
         └─ Kraken2 classification ✅
```

---

## 🎓 Summary

| Component | DNA Viruses | RNA Viruses |
|-----------|-------------|-------------|
| **Sample prep** | DNA extraction | RNA extraction |
| **Library prep** | DNA-seq | Direct RNA-seq or cDNA-seq |
| **Assembler** | metaFlye ✅ | Trinity, rnaSPAdes ✅ |
| **Viral ID** | viralFlye ✅ | Custom scripts or manual |
| **Classifier** | Kraken2 ✅ | Kraken2 ✅ |
| **Your workflow** | ✅ Ready! | ⚠️ Needs RNA-seq data |

**Bottom line**: Your workflow is excellent for DNA viruses. For RNA viruses, you need RNA-seq data, not DNA-seq data.

