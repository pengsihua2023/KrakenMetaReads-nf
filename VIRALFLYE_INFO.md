# viralFlye Integration - Viral Contig Identification

## 🦠 什么是viralFlye？

**viralFlye是从metaFlye组装结果中识别病毒contigs的后处理工具**，它：
- 从metaFlye的组装图（assembly graph）中提取病毒序列
- 识别线性和环状病毒contigs
- 基于覆盖度和长度过滤（默认：5kb-1Mb，>10x覆盖度）
- 可选的病毒蛋白注释（使用Pfam HMM）

## 🔬 正确的工作流程

```
长读长测序数据
   ↓
metaFlye组装 (--meta)
   ↓
   ├─ assembly.fasta (所有contigs)
   ├─ assembly_graph.gfa (组装图)
   └─ assembly_info.txt (contig信息)
   ↓
viralFlye分析 (输入: metaFlye目录 + 原始reads)
   ↓
   ├─ linears_viralFlye.fasta (线性病毒contigs)
   ├─ circulars_viralFlye.fasta (环状病毒contigs)
   └─ components_viralFlye.fasta (多边连接组件)
   ↓
分别计算丰度和分类
```

## ✨ metaFlye vs viralFlye

| 特性 | metaFlye | viralFlye |
|------|----------|-----------|
| **类型** | 组装器 | 后处理/识别工具 |
| **输入** | 原始reads | metaFlye输出目录 + reads |
| **输出** | 所有contigs | 病毒contigs子集 |
| **目标** | 完整宏基因组 | 病毒/噬菌体 |
| **优势** | 全面 | 专注病毒，质量高 |

## ✨ 为什么使用viralFlye？

### 关键优势：
1. **metaFlye** → 组装所有宏基因组内容（细菌+病毒+真核生物）
2. **viralFlye** → 从metaFlye结果中提取和识别病毒序列
   - 过滤低覆盖度contigs
   - 识别环状病毒基因组
   - 聚焦病毒大小范围（5kb-1Mb）

### 工作流配置：
- ✅ metaFlye先组装 → 获得assembly目录
- ✅ viralFlye分析assembly目录 → 识别病毒contigs
- ✅ 分别计算所有contigs和病毒contigs的RPM/RPKM
- ✅ Kraken2病毒数据库分类

## 📊 输出文件结构

```
results_long/
├── flye_assembly/                         # metaFlye组装目录（用于viralFlye）
│   └── *_flye_assembly/
│       ├── assembly.fasta
│       ├── assembly_graph.gfa
│       └── assembly_info.txt
├── viralflye/                             # viralFlye识别的病毒contigs ⭐
│   ├── linears_viralFlye.fasta           # 线性病毒
│   ├── circulars_viralFlye.fasta         # 环状病毒
│   └── components_viralFlye.fasta        # 多边组件
├── abundance_flye/                        # metaFlye所有contigs的RPM/RPKM
│   ├── *_flye_abundance.txt
│   └── *_flye_abundance_summary.txt
├── abundance_viralflye_linear/            # 线性病毒contigs RPM/RPKM ⭐
│   ├── *_viralflye_linear_abundance.txt
│   └── *_viralflye_linear_abundance_summary.txt
├── abundance_viralflye_circular/          # 环状病毒contigs RPM/RPKM ⭐
│   ├── *_viralflye_circular_abundance.txt
│   └── *_viralflye_circular_abundance_summary.txt
├── kraken2_flye/                          # metaFlye分类
│   ├── *_flye_classification.txt
│   └── *_flye_report.txt
├── kraken2_viralflye_linear/              # 线性病毒分类 ⭐
│   ├── *_viralflye_linear_classification.txt
│   └── *_viralflye_linear_report.txt
└── kraken2_viralflye_circular/            # 环状病毒分类 ⭐
    ├── *_viralflye_circular_classification.txt
    └── *_viralflye_circular_report.txt
```

## 🎯 使用方法

### 默认：启用viralFlye（推荐）⭐

```bash
# 默认配置已启用viralFlye
sbatch run_long_only.sh
```

工作流程：
1. ✅ metaFlye组装 → 所有contigs
2. ✅ viralFlye识别 → 从metaFlye结果中提取病毒contigs
3. ✅ 分别计算：
   - metaFlye所有contigs的RPM/RPKM
   - 线性病毒contigs的RPM/RPKM
   - 环状病毒contigs的RPM/RPKM
4. ✅ Kraken2分类（三套独立结果）

### 禁用viralFlye（只运行metaFlye）

如果只需要metaFlye，编辑 `metagenome_hybrid_workflow.config`：
```groovy
run_viralflye = false
```

然后运行：
```bash
sbatch run_long_only.sh
```

## 📈 预期结果

### metaFlye结果：
- **所有contigs**（细菌、病毒、真核生物等）
- 完整的宏基因组图谱
- contig数量多（例如：1211个）

### viralFlye线性病毒结果：
- **线性病毒contigs**（从metaFlye中筛选）
- 长度5kb-1Mb，覆盖度>10x
- 聚焦线性病毒基因组

### viralFlye环状病毒结果：
- **环状病毒contigs**（闭合的环状基因组）
- 噬菌体、小型DNA病毒
- 基因组完整性高

## 💡 分析建议

### 1. 查看viralFlye识别到的病毒数量

```bash
# 查看viralFlye输出
ls -lh results_long/viralflye/

# 统计线性病毒contigs数量
grep -c ">" results_long/viralflye/linears_viralFlye.fasta

# 统计环状病毒contigs数量
grep -c ">" results_long/viralflye/circulars_viralFlye.fasta
```

### 2. 比较metaFlye全部contigs vs 病毒contigs

```bash
# metaFlye所有contigs统计
cat results_long/abundance_flye/*_summary.txt

# 线性病毒统计
cat results_long/abundance_viralflye_linear/*_summary.txt

# 环状病毒统计
cat results_long/abundance_viralflye_circular/*_summary.txt
```

### 3. 查找高丰度病毒contigs

```bash
# 线性病毒中RPKM最高的
sort -t$'\t' -k5 -nr results_long/abundance_viralflye_linear/*_abundance.txt | head -20

# 环状病毒中RPKM最高的
sort -t$'\t' -k5 -nr results_long/abundance_viralflye_circular/*_abundance.txt | head -20
```

### 4. 比较病毒分类结果

```bash
# metaFlye中的病毒分类（所有contigs）
grep -i "virus" results_long/kraken2_flye/*_report.txt

# 线性病毒contigs的分类（更聚焦）
grep -i "virus" results_long/kraken2_viralflye_linear/*_report.txt

# 环状病毒contigs的分类
grep -i "virus" results_long/kraken2_viralflye_circular/*_report.txt
```

## 🔑 关键参数

### viralFlye命令格式：

```bash
viralFlye.py \
    --dir flye_assembly_dir \        # metaFlye输出目录
    --reads path_to_reads \          # 原始长读长数据
    --outdir viralflye_output \      # 输出目录
    --min-len 5000 \                 # 最小contig长度（默认5kb）
    --max-len 1000000 \              # 最大contig长度（默认1Mb）
    --min-cov 10 \                   # 最小覆盖度（默认10x）
    --hmm Pfam-A.hmm.gz              # 可选：蛋白注释
```

### 可调整参数（在config中）：

- `viralflye_min_length = 5000` - 病毒contig最小长度
- `viralflye_max_length = 1000000` - 病毒contig最大长度
- `viralflye_min_coverage = 10` - 最小覆盖度阈值
- `viralflye_hmm = null` - Pfam HMM文件路径（可选）

## ⚙️ 资源配置

### metaFlye组装：
- **CPUs**: 32
- **Memory**: 128 GB
- **Time**: 72h

### viralFlye识别：
- **CPUs**: 16
- **Memory**: 64 GB
- **Time**: 12h

### 病毒contig后续分析（linear/circular）：
- **Mapping**: 8 CPUs, 16 GB, 4h
- **Abundance**: 2 CPUs, 8 GB, 1h
- **Kraken2**: 8 CPUs, 24 GB, 4h

工作流程是串行的：
1. 先metaFlye组装
2. 然后viralFlye识别（依赖metaFlye结果）
3. 最后并行处理linear和circular contigs

## 🎊 优势总结

通过metaFlye + viralFlye流程，您可以：
1. ✅ 获得完整的宏基因组组装（metaFlye所有contigs）
2. ✅ 获得高质量的病毒contig子集（viralFlye筛选）
3. ✅ 区分线性和环状病毒基因组
4. ✅ 三套独立的RPM/RPKM丰度数据：
   - metaFlye所有contigs
   - 线性病毒contigs
   - 环状病毒contigs
5. ✅ 三套独立的Kraken2分类结果
6. ✅ 聚焦高质量病毒序列（覆盖度>10x）

**完美适合病毒宏基因组研究！** 🦠✨

## 📌 重要说明

- viralFlye **不是**独立的拼接器
- viralFlye **是**从metaFlye结果中识别病毒的工具
- 它利用metaFlye的assembly graph来更好地识别病毒序列
- 输出的病毒contigs是metaFlye contigs的**子集**，但经过优化和过滤

