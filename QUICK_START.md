# Quick Start Guide - Hybrid Workflow

## 文件说明

### 新创建的文件：
1. **metagenome_hybrid_workflow.nf** - 主工作流文件（支持短读长+长读长）
2. **metagenome_hybrid_workflow.config** - 配置文件
3. **run_hybrid_workflow.sh** - 运行脚本
4. **samplesheet_short.csv** - 短读长样本表（示例）
5. **samplesheet_long.csv** - 长读长样本表（示例）

### 原有文件（仍可使用）：
- **metagenome_assembly_classification_workflow_en.nf** - 仅短读长工作流
- **metagenome_assembly_classification_en.config** - 仅短读长配置
- **run_metagenome_assembly_classification_en.sh** - 仅短读长运行脚本

## 快速使用步骤

### 1. 准备samplesheet文件

#### 短读长数据 (samplesheet_short.csv)
路径：`/scratch/sp96859/Meta-genome-data-analysis/Apptainer/yitiaolong/data/reads/samplesheet_short.csv`

格式：
```csv
sample,fastq_1,fastq_2
sample1,/full/path/to/sample1_R1.fastq.gz,/full/path/to/sample1_R2.fastq.gz
```

#### 长读长数据 (samplesheet_long.csv)
路径：`/scratch/sp96859/Meta-genome-data-analysis/Apptainer/Contig-based-VirSorter2-DeepVirFinder/data/samplesheet_long.csv`

格式：
```csv
sample,fastq_long
llnl_66d1047e,/scratch/sp96859/Meta-genome-data-analysis/Apptainer/Contig-based-VirSorter2-DeepVirFinder/data/llnl_66d1047e.fastq.gz
```

### 2. 添加执行权限

```bash
chmod +x run_hybrid_workflow.sh
```

### 3. 运行工作流

```bash
sbatch run_hybrid_workflow.sh
```

## 输出结果

### 短读长结果 (results_short/)
```
results_short/
├── fastp/                     # 质控报告
├── abundance_megahit/         # MEGAHIT RPM/RPKM ⭐
├── abundance_spades/          # SPAdes RPM/RPKM ⭐
├── kraken2_megahit/          # MEGAHIT分类
├── kraken2_spades/           # SPAdes分类
└── merged_reports/            # 合并报告
```

### 长读长结果 (results_long/)
```
results_long/
├── abundance_flye/            # metaFlye RPM/RPKM ⭐
└── kraken2_flye/             # Flye分类
```

## 高级选项

### 修改长读长平台类型

在 `run_hybrid_workflow.sh` 中添加参数：
```bash
--long_read_type pacbio         # For PacBio CLR
--long_read_type pacbio-hifi    # For PacBio HiFi
--long_read_type nanopore       # For Nanopore (default)
```

### 只运行短读长分析

编辑 `run_hybrid_workflow.sh`，注释掉长读长samplesheet：
```bash
# SAMPLESHEET_LONG="/path/to/samplesheet_long.csv"
```

### 只运行长读长分析

编辑 `run_hybrid_workflow.sh`，注释掉短读长samplesheet：
```bash
# SAMPLESHEET_SHORT="/path/to/samplesheet_short.csv"
```

## 丰度计算说明

- **RPM** (Reads Per Million) = (contig的reads数 / 总mapped reads数) × 10^6
- **RPKM** (Reads Per Kilobase per Million) = (contig的reads数 / (contig长度/1000)) / (总mapped reads数 / 10^6)

所有拼接器（MEGAHIT、SPAdes、metaFlye）都会生成独立的RPM/RPKM结果。

## 故障排查

### 如果遇到依赖问题：

```bash
# 清理缓存
rm -rf /scratch/sp96859/Meta-genome-data-analysis/conda_cache/
rm -rf work/

# 重新运行
sbatch run_hybrid_workflow.sh
```

### 查看详细日志：

```bash
# 查看Nextflow日志
cat .nextflow.log

# 查看SLURM日志
cat Hybrid_Metagenome_*.out
cat Hybrid_Metagenome_*.err
```

