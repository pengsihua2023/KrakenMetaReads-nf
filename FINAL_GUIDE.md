# 🎯 最终使用指南 - Hybrid Metagenome Workflow

## ✅ 已完成的工作

### 创建的新文件（混合工作流）

#### 核心文件：
1. **metagenome_hybrid_workflow.nf** - 主工作流（支持短+长读长）
2. **metagenome_hybrid_workflow.config** - 配置文件
3. **run_hybrid_workflow.sh** - 运行脚本

#### 示例文件：
4. **samplesheet_short.csv** - 短读长样本表模板
5. **samplesheet_long.csv** - 长读长样本表模板

#### 文档文件：
6. **README_HYBRID.md** - 详细文档
7. **QUICK_START.md** - 快速指南
8. **WORKFLOW_SUMMARY.md** - 功能总结

### 保留的原文件（仅短读长）
- **metagenome_assembly_classification_workflow_en.nf**
- **metagenome_assembly_classification_en.config**
- **run_metagenome_assembly_classification_en.sh**

## 🚀 立即开始使用

### 步骤1：准备samplesheet文件

#### 短读长样本 
创建或编辑：`/scratch/sp96859/Meta-genome-data-analysis/Apptainer/yitiaolong/data/reads/samplesheet_short.csv`

```csv
sample,fastq_1,fastq_2
sample1,/full/path/to/sample1_R1.fastq.gz,/full/path/to/sample1_R2.fastq.gz
sample2,/full/path/to/sample2_R1.fastq.gz,/full/path/to/sample2_R2.fastq.gz
```

#### 长读长样本
已存在：`/scratch/sp96859/Meta-genome-data-analysis/Apptainer/Contig-based-VirSorter2-DeepVirFinder/data/samplesheet_long.csv`

```csv
sample,fastq_long
llnl_66d1047e,/scratch/sp96859/Meta-genome-data-analysis/Apptainer/Contig-based-VirSorter2-DeepVirFinder/data/llnl_66d1047e.fastq.gz
```

### 步骤2：添加执行权限

```bash
chmod +x run_hybrid_workflow.sh
```

### 步骤3：提交作业

```bash
sbatch run_hybrid_workflow.sh
```

## 📋 工作流会自动执行

### 对于短读长数据：
1. ✅ fastp质控
2. ✅ MEGAHIT拼接 → Bowtie2比对 → **计算RPM/RPKM** ⭐
3. ✅ SPAdes拼接 → Bowtie2比对 → **计算RPM/RPKM** ⭐
4. ✅ Kraken2分类（MEGAHIT和SPAdes分别）
5. ✅ 生成MEGAHIT vs SPAdes对比报告

### 对于长读长数据：
1. ✅ metaFlye拼接
2. ✅ Minimap2比对 → **计算RPM/RPKM** ⭐
3. ✅ Kraken2分类

## 📊 结果位置

- **短读长结果**: `results_short/`
- **长读长结果**: `results_long/`

## 🎨 丰度文件格式示例

每个拼接器都会生成类似的文件：

### *_abundance.txt
```
Contig_ID       Length(bp)  Mapped_Reads  RPM      RPKM
k141_12345      2500        150           1250.5   500.2
k141_67890      5000        300           2501.0   600.2
NODE_1_length   3000        200           1667.2   555.7
```

### *_abundance_summary.txt
```
================================================================================
MEGAHIT Contigs Abundance Summary
================================================================================

Sample: llnl_66ce4dde
Total contigs: 50000
Total mapped reads: 1,200,000
Average contig length: 1250.50 bp
Longest contig: 25,000 bp
Shortest contig: 1,000 bp

================================================================================
```

## 💡 高级使用

### 只处理短读长
在 `run_hybrid_workflow.sh` 中注释掉：
```bash
# SAMPLESHEET_LONG="/path/to/samplesheet_long.csv"
```

### 只处理长读长
在 `run_hybrid_workflow.sh` 中注释掉：
```bash
# SAMPLESHEET_SHORT="/path/to/samplesheet_short.csv"
```

### 使用PacBio数据
在命令行添加参数或修改config：
```bash
--long_read_type pacbio-hifi
```

## ⚠️ 重要提示

1. **首次运行需要下载容器镜像**，可能需要一些时间
2. **确保Kraken2数据库路径正确**
3. **SPAdes需要大内存**（512GB），确保节点有足够资源
4. **长读长拼接耗时较长**（可能需要数天）

## 🔍 监控和调试

### 查看运行状态
```bash
# 查看SLURM输出
cat Hybrid_Metagenome_*.out

# 查看错误信息
cat Hybrid_Metagenome_*.err

# 查看Nextflow日志
cat .nextflow.log
```

### 如果遇到问题
```bash
# 清理缓存重新运行
rm -rf /scratch/sp96859/Meta-genome-data-analysis/conda_cache/
rm -rf work/
sbatch run_hybrid_workflow.sh
```

## 🎊 完成！

您现在拥有一个完整的混合宏基因组分析工作流，能够：
- ✨ 处理短读长（Illumina）和长读长（Nanopore/PacBio）数据
- ✨ 为所有拼接器计算RPM和RPKM丰度
- ✨ 进行物种分类
- ✨ 生成详细的比较报告
- ✨ 自动处理依赖问题

祝您分析顺利！🧬

