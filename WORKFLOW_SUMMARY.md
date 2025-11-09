# Hybrid Metagenome Workflow - Complete Summary

## 📦 已创建的文件

### 核心工作流文件
1. **metagenome_hybrid_workflow.nf** (838行)
   - 主工作流文件
   - 支持短读长（Illumina）和长读长（Nanopore/PacBio）
   - 包含所有进程定义

2. **metagenome_hybrid_workflow.config** (177行)
   - 资源配置文件
   - SLURM集群设置
   - 进程特定的CPU/内存/时间分配

3. **run_hybrid_workflow.sh** (230行)
   - SLURM作业提交脚本
   - 自动检测输入文件
   - 智能选择运行模式

### 示例文件
4. **samplesheet_short.csv** - 短读长样本表模板
5. **samplesheet_long.csv** - 长读长样本表模板

### 文档文件
6. **README_HYBRID.md** - 详细使用文档
7. **QUICK_START.md** - 快速入门指南

## 🔬 工作流架构

### 短读长流程 (Short-Read Pipeline)
```
Input: Paired-end FASTQ (R1, R2)
  ↓
[FASTP] Quality Control
  ↓
┌─────────────┬─────────────┐
│  MEGAHIT    │   SPAdes    │ Assembly
└─────────────┴─────────────┘
       ↓              ↓
  [Bowtie2]      [Bowtie2]    Build Index
       ↓              ↓
  [Bowtie2]      [Bowtie2]    Align Reads
       ↓              ↓
  [Calculate]    [Calculate]  RPM/RPKM ⭐
       ↓              ↓
  [Kraken2]      [Kraken2]    Classification
       ↓              ↓
       └──────┬───────┘
              ↓
         [Merge Reports]
```

### 长读长流程 (Long-Read Pipeline)
```
Input: Single-end FASTQ
  ↓
[metaFlye] Assembly
  ↓
[Minimap2] Align Reads
  ↓
[Calculate] RPM/RPKM ⭐
  ↓
[Kraken2] Classification
```

## 📊 输出文件说明

### 短读长结果 (results_short/)

| 目录 | 文件 | 说明 |
|------|------|------|
| `fastp/` | `*_fastp.html` | 质控HTML报告 |
| | `*_fastp.json` | 质控JSON数据 |
| `abundance_megahit/` | `*_megahit_abundance.txt` | MEGAHIT每个contig的RPM/RPKM ⭐ |
| | `*_megahit_abundance_summary.txt` | MEGAHIT统计汇总 |
| `abundance_spades/` | `*_spades_abundance.txt` | SPAdes每个contig的RPM/RPKM ⭐ |
| | `*_spades_abundance_summary.txt` | SPAdes统计汇总 |
| `kraken2_megahit/` | `*_megahit_classification.txt` | MEGAHIT详细分类 |
| | `*_megahit_report.txt` | MEGAHIT分类汇总 |
| `kraken2_spades/` | `*_spades_classification.txt` | SPAdes详细分类 |
| | `*_spades_report.txt` | SPAdes分类汇总 |
| `merged_reports/` | `*_merged_report.txt` | MEGAHIT vs SPAdes对比 |
| | `*_merged_report.csv` | 详细对比数据 |

### 长读长结果 (results_long/)

| 目录 | 文件 | 说明 |
|------|------|------|
| `abundance_flye/` | `*_flye_abundance.txt` | metaFlye每个contig的RPM/RPKM ⭐ |
| | `*_flye_abundance_summary.txt` | metaFlye统计汇总 |
| `kraken2_flye/` | `*_flye_classification.txt` | Flye详细分类 |
| | `*_flye_report.txt` | Flye分类汇总 |

## 🔑 关键特性

### 1. RPM/RPKM 丰度计算 ⭐
- **所有拼接器**都会计算每个contig的丰度
- **短读长**: MEGAHIT和SPAdes分别独立计算
- **长读长**: metaFlye独立计算
- 输出格式统一：`Contig_ID, Length, Mapped_Reads, RPM, RPKM`

### 2. 多拼接器支持
- **短读长**: MEGAHIT（快速）+ SPAdes（高质量）
- **长读长**: metaFlye（长读长专用）

### 3. 智能依赖处理
- 自动创建软链接解决`libbz2.so.1.0`依赖问题
- 无需手动配置系统库

### 4. 灵活运行模式
- 可以只运行短读长分析
- 可以只运行长读长分析
- 可以同时运行两种分析

### 5. 平台自适应
- Nanopore: `--long_read_type nanopore`（默认）
- PacBio CLR: `--long_read_type pacbio`
- PacBio HiFi: `--long_read_type pacbio-hifi`

## 🚀 使用示例

### 1. 添加执行权限
```bash
chmod +x run_hybrid_workflow.sh
```

### 2. 提交作业
```bash
sbatch run_hybrid_workflow.sh
```

### 3. 监控进度
```bash
# 查看作业状态
squeue -u $USER

# 实时查看输出
tail -f Hybrid_Metagenome_*.out
```

## 🔧 自定义配置

### 修改短读长样本路径
编辑 `run_hybrid_workflow.sh` 第58行：
```bash
SAMPLESHEET_SHORT="/your/path/to/samplesheet_short.csv"
```

### 修改长读长样本路径
编辑 `run_hybrid_workflow.sh` 第59行：
```bash
SAMPLESHEET_LONG="/your/path/to/samplesheet_long.csv"
```

### 修改Kraken2数据库
编辑 `run_hybrid_workflow.sh` 第57行：
```bash
KRAKEN2_DB="/your/path/to/kraken2/db"
```

### 修改长读长类型
编辑 `metagenome_hybrid_workflow.config` 第161行：
```groovy
long_read_type = 'pacbio'  // or 'pacbio-hifi'
```

## 📈 资源需求

### 短读长分析
- **MEGAHIT**: 16 CPUs, 64 GB RAM, 12h
- **SPAdes**: 32 CPUs, 512 GB RAM, 48h
- **Bowtie2 mapping**: 16 CPUs, 32 GB RAM, 8h
- **Kraken2**: 16 CPUs, 48 GB RAM, 8h

### 长读长分析
- **metaFlye**: 32 CPUs, 128 GB RAM, 72h
- **Minimap2 mapping**: 16 CPUs, 32 GB RAM, 8h
- **Kraken2**: 16 CPUs, 48 GB RAM, 8h

## 🎯 与原工作流的区别

| 特性 | 原工作流 | 新混合工作流 |
|------|---------|-------------|
| 短读长支持 | ✅ | ✅ |
| 长读长支持 | ❌ | ✅ Nanopore/PacBio |
| RPM/RPKM计算 | ✅ | ✅ 所有拼接器 |
| 拼接器 | MEGAHIT + SPAdes | MEGAHIT + SPAdes + metaFlye |
| 输出目录 | `results/` | `results_short/` + `results_long/` |
| Samplesheet | `samplesheet.csv` | `samplesheet_short.csv` + `samplesheet_long.csv` |

## ✅ 已解决的问题

1. ✅ **libbz2依赖** - 自动软链接设置
2. ✅ **多平台支持** - Nanopore/PacBio/Illumina
3. ✅ **独立的RPM/RPKM** - 每个拼接器独立计算
4. ✅ **灵活的输入** - 支持单独或混合运行
5. ✅ **纯英文代码** - 所有注释和输出都是英文

## 📞 故障排查

### 问题：conda缓存导致依赖错误
```bash
rm -rf /scratch/sp96859/Meta-genome-data-analysis/conda_cache/
rm -rf work/
sbatch run_hybrid_workflow.sh
```

### 问题：查看失败任务的详细信息
```bash
# 进入失败任务的工作目录
cd work/xx/xxxxxx...

# 查看命令
cat .command.sh

# 查看输出
cat .command.out

# 查看错误
cat .command.err
```

## 🎉 完成！

您现在拥有一个功能完整的混合宏基因组分析工作流，支持：
- ✅ Illumina短读长数据
- ✅ Nanopore长读长数据  
- ✅ PacBio长读长数据
- ✅ 所有平台的RPM/RPKM丰度计算
- ✅ Kraken2物种分类
- ✅ 自动依赖管理

