# viralFlye Integration Update Summary

## ✅ 已完成的修正

### 修正前的错误理解
❌ 将viralFlye当作独立的组装器  
❌ 与metaFlye并行运行  
❌ 直接从原始reads组装

### 修正后的正确实现
✅ viralFlye是**后处理工具**  
✅ 从metaFlye结果中**识别病毒contigs**  
✅ 分析metaFlye的assembly graph  
✅ 输出线性和环状病毒contigs

---

## 🔬 正确的工作流程

```
长读长数据 (*.fastq.gz)
   ↓
[FLYE_ASSEMBLY]
   metaFlye组装 (--meta)
   ↓
   ├─ flye_output/assembly.fasta (所有contigs)
   ├─ flye_output/assembly_graph.gfa (组装图)
   └─ flye_output/assembly_info.txt (contig信息)
   ↓
[VIRALFLYE_IDENTIFY]
   viralFlye.py --dir flye_output --reads *.fastq.gz
   ↓
   ├─ linears_viralFlye.fasta (线性病毒contigs)
   ├─ circulars_viralFlye.fasta (环状病毒contigs)
   └─ components_viralFlye.fasta (多边组件)
   ↓
并行处理三套contigs:
   ↓
┌──────────────────┬────────────────────┬───────────────────┐
│ metaFlye全部     │ 线性病毒          │ 环状病毒           │
│                  │                    │                    │
│ Minimap2比对     │ Minimap2比对       │ Minimap2比对       │
│      ↓           │      ↓             │      ↓             │
│ RPM/RPKM计算     │ RPM/RPKM计算       │ RPM/RPKM计算       │
│      ↓           │      ↓             │      ↓             │
│ Kraken2分类      │ Kraken2分类        │ Kraken2分类        │
└──────────────────┴────────────────────┴───────────────────┘
```

---

## 📁 更新的文件列表

### 核心工作流文件
1. ✅ **metagenome_hybrid_workflow.nf** (1248行)
   - 修正viralFlye为后处理步骤
   - 添加VIRALFLYE_IDENTIFY进程
   - 分离线性和环状病毒contigs的处理流程
   - metaFlye输出assembly_dir供viralFlye使用

2. ✅ **metagenome_hybrid_workflow.config** (244行)
   - 移除错误的VIRALFLYE_ASSEMBLY配置
   - 添加VIRALFLYE_IDENTIFY配置
   - 添加LINEAR和CIRCULAR处理的资源配置
   - 添加viralFlye参数设置

### 运行脚本
3. ✅ **run_long_only.sh** (186行)
   - 更新工作流步骤说明
   - 添加linear和circular结果检查

4. ✅ **run_hybrid_workflow.sh** (276行)
   - 更新长读长流程说明
   - 添加viralFlye输出目录检查

### 文档文件
5. ✅ **README_HYBRID.md** (350行)
   - 完整重写viralFlye部分
   - 正确描述工作流程
   - 更新输出目录结构

6. ✅ **VIRALFLYE_INFO.md** (253行)
   - 详细说明viralFlye原理
   - 提供分析建议
   - 强调其作为后处理工具的本质

---

## 🎯 新的进程列表

### metaFlye相关（1个）
- `FLYE_ASSEMBLY` - metaFlye组装，输出contigs和assembly_dir

### viralFlye相关（7个）
1. `VIRALFLYE_IDENTIFY` - 从metaFlye识别病毒contigs
2. `MINIMAP2_ALIGN_VIRALFLYE_LINEAR` - 比对到线性病毒contigs
3. `MINIMAP2_ALIGN_VIRALFLYE_CIRCULAR` - 比对到环状病毒contigs
4. `CALCULATE_ABUNDANCE_VIRALFLYE_LINEAR` - 线性病毒RPM/RPKM
5. `CALCULATE_ABUNDANCE_VIRALFLYE_CIRCULAR` - 环状病毒RPM/RPKM
6. `KRAKEN2_CLASSIFICATION_VIRALFLYE_LINEAR` - 线性病毒分类
7. `KRAKEN2_CLASSIFICATION_VIRALFLYE_CIRCULAR` - 环状病毒分类

---

## 📊 输出结构对比

### 修正前（错误）
```
results_long/
├── abundance_flye/          # metaFlye
├── abundance_viralflye/     # viralFlye拼接 ❌
├── kraken2_flye/
└── kraken2_viralflye/
```

### 修正后（正确）
```
results_long/
├── flye_assembly/                    # metaFlye组装目录
│   └── *_flye_assembly/             # 供viralFlye使用
├── viralflye/                        # viralFlye识别的病毒 ✅
│   ├── linears_viralFlye.fasta
│   ├── circulars_viralFlye.fasta
│   └── components_viralFlye.fasta
├── abundance_flye/                   # metaFlye所有contigs
├── abundance_viralflye_linear/       # 线性病毒contigs ✅
├── abundance_viralflye_circular/     # 环状病毒contigs ✅
├── kraken2_flye/                     # metaFlye分类
├── kraken2_viralflye_linear/         # 线性病毒分类 ✅
└── kraken2_viralflye_circular/       # 环状病毒分类 ✅
```

---

## 🔑 关键变化

### viralFlye输入变化
- **修正前**: `--nano-raw reads.fastq.gz`（原始reads）❌
- **修正后**: `--dir flye_output --reads reads.fastq.gz`（metaFlye目录+reads）✅

### 工作流程序变化
- **修正前**: metaFlye和viralFlye并行运行 ❌
- **修正后**: metaFlye → viralFlye串行运行 ✅

### 输出contigs变化
- **修正前**: viralFlye独立组装的contigs ❌
- **修正后**: viralFlye从metaFlye中筛选的病毒contigs ✅

---

## 💡 使用建议

### 1. 标准病毒宏基因组分析（启用viralFlye）

```bash
# 默认配置已启用viralFlye
sbatch run_long_only.sh
```

**获得3套结果**:
- metaFlye全部contigs（细菌+病毒+其他）
- 线性病毒contigs（viralFlye筛选）
- 环状病毒contigs（viralFlye筛选，闭合基因组）

### 2. 只需要基础拼接（禁用viralFlye）

编辑 `metagenome_hybrid_workflow.config`:
```groovy
run_viralflye = false
```

**只获得1套结果**:
- metaFlye全部contigs

### 3. 自定义viralFlye参数

编辑 `metagenome_hybrid_workflow.config`:
```groovy
viralflye_min_length = 3000      # 降低最小长度
viralflye_min_coverage = 5       # 降低覆盖度阈值
viralflye_hmm = "/path/to/Pfam-A.hmm.gz"  # 添加蛋白注释
```

---

## 🎊 优势

现在的工作流正确实现了viralFlye，您可以：

1. ✅ 从完整宏基因组中**精准提取病毒序列**
2. ✅ 区分**线性和环状**病毒基因组
3. ✅ 获得**高质量病毒contigs**（覆盖度>10x）
4. ✅ **三套独立的RPM/RPKM**丰度数据
5. ✅ **三套独立的Kraken2**分类结果
6. ✅ 利用metaFlye的**assembly graph**优化病毒识别

**完全符合viralFlye的设计理念和最佳实践！** 🦠✨

---

## 📌 重要提醒

- ⚠️ viralFlye需要metaFlye的**完整输出目录**（不只是contigs文件）
- ⚠️ viralFlye会**依赖metaFlye**，因此是串行执行
- ⚠️ 如果metaFlye没有病毒序列，viralFlye可能输出为空（这是正常的）
- ✅ 输出文件使用`optional: true`，避免空文件导致流程失败

感谢您的指正，现在实现完全正确了！🙏

