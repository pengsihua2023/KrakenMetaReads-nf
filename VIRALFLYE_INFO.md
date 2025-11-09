# viralFlye Integration - Viral-Optimized Assembly

## 🦠 什么是viralFlye？

**viralFlye是针对病毒基因组优化的Flye变体**，使用相同的Flye程序但添加`--plasmids`参数，特别适合：
- 病毒宏基因组
- 噬菌体组装
- 小型环状DNA（类质粒结构）

## 🔬 metaFlye vs viralFlye

| 特性 | metaFlye | viralFlye |
|------|----------|-----------|
| **目标** | 一般宏基因组 | 病毒/噬菌体基因组 |
| **参数** | `--meta` | `--meta --plasmids` |
| **优化对象** | 细菌、真核生物 | 病毒、环状DNA |
| **contig类型** | 线性为主 | 环状+线性 |
| **最佳用途** | 完整宏基因组 | 病毒组（virome） |

## ✨ 为什么同时运行两者？

### 互补优势：
1. **metaFlye** → 捕获所有宏基因组内容（细菌+病毒）
2. **viralFlye** → 更好地组装病毒基因组（特别是环状病毒）

### 您的工作流配置：
- ✅ Kraken2病毒数据库 (`kraken2_Viral_ref`)
- ✅ 同时运行两个拼接器
- ✅ 分别计算RPM/RPKM
- ✅ 可以比较两种结果

## 📊 输出文件结构

```
results_long/
├── abundance_flye/                    # metaFlye RPM/RPKM
│   ├── *_flye_abundance.txt
│   └── *_flye_abundance_summary.txt
├── abundance_viralflye/               # viralFlye RPM/RPKM ⭐新增
│   ├── *_viralflye_abundance.txt
│   └── *_viralflye_abundance_summary.txt
├── kraken2_flye/                      # metaFlye分类
│   ├── *_flye_classification.txt
│   └── *_flye_report.txt
└── kraken2_viralflye/                 # viralFlye分类 ⭐新增
    ├── *_viralflye_classification.txt
    └── *_viralflye_report.txt
```

## 🎯 使用方法

### 默认：同时运行两个拼接器（推荐）⭐

```bash
# 默认配置已启用viralFlye
sbatch run_long_only.sh
```

会得到：
- ✅ metaFlye结果
- ✅ viralFlye结果
- ✅ 两套独立的RPM/RPKM和分类

### 只运行metaFlye（禁用viralFlye）

编辑 `metagenome_hybrid_workflow.config` 第190行：
```groovy
run_viralflye = false  // 禁用viralFlye
```

然后运行：
```bash
sbatch run_long_only.sh
```

## 📈 预期结果差异

### metaFlye结果：
- 更多contigs（包括细菌、真核生物等）
- 更完整的宏基因组图谱
- 病毒contigs可能较短或不完整

### viralFlye结果：
- 较少但更完整的病毒contigs
- 更好的环状病毒基因组闭合
- 特别适合噬菌体和小型DNA病毒

## 💡 分析建议

### 1. 比较两个拼接器的病毒发现

```bash
# 查看metaFlye的病毒分类
grep -i "virus" results_long/kraken2_flye/*_report.txt

# 查看viralFlye的病毒分类
grep -i "virus" results_long/kraken2_viralflye/*_report.txt
```

### 2. 比较contig质量

```bash
# metaFlye统计
cat results_long/abundance_flye/*_summary.txt

# viralFlye统计
cat results_long/abundance_viralflye/*_summary.txt
```

### 3. 查找高丰度病毒contigs

```bash
# metaFlye中RPKM最高的病毒
sort -t$'\t' -k5 -nr results_long/abundance_flye/*_abundance.txt | head -20

# viralFlye中RPKM最高的病毒
sort -t$'\t' -k5 -nr results_long/abundance_viralflye/*_abundance.txt | head -20
```

## 🔑 关键参数

### viralFlye的核心差异：

```bash
# metaFlye
flye --nano-raw reads.fq --meta --genome-size 5m

# viralFlye  
flye --nano-raw reads.fq --meta --plasmids --genome-size 5m
#                                ^^^^^^^^^^
#                                病毒优化参数
```

`--plasmids`参数：
- 启用环状DNA组装算法
- 检测并闭合小型环状分子
- 对病毒/噬菌体基因组特别有效

## ⚙️ 资源配置

两个拼接器使用相同资源（并行运行）：
- **CPUs**: 32
- **Memory**: 128 GB
- **Time**: 72h

总资源需求：
- 如果两个样本并行：可能需要 64 CPUs, 256 GB RAM
- 如果SLURM队列限制：会串行运行

## 🎊 优势总结

通过同时运行metaFlye和viralFlye，您可以：
1. ✅ 获得完整的宏基因组视图（metaFlye）
2. ✅ 获得优化的病毒组装（viralFlye）
3. ✅ 比较两者发现的差异
4. ✅ 两套独立的RPM/RPKM丰度数据
5. ✅ 更全面的病毒分类结果

**特别适合病毒宏基因组研究！** 🦠✨

