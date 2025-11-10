# Dual Database Integration Guide - RefSeq + RVDB

## 🎯 为什么使用两个数据库？

### 互补优势：

```
RefSeq Viral:
  ✅ 高质量、经审核
  ✅ 分类准确、注释详细
  ✅ 低假阳性率
  ❌ 覆盖范围有限
  ❌ 更新较慢

RVDB:
  ✅ 覆盖全面（~5倍于RefSeq）
  ✅ 包含环境/未培养病毒
  ✅ 更新频繁（月度）
  ❌ 可能有冗余
  ❌ 质量参差不齐

两者结合:
  ⭐⭐⭐ 既有RefSeq的准确性
  ⭐⭐⭐ 又有RVDB的全面性
```

---

## 🔧 整合策略

### 方法1：分别分类，后期合并（推荐）⭐⭐⭐

**优势**：
- ✅ 清楚区分来源
- ✅ 可以评估数据库差异
- ✅ 灵活控制可信度阈值

**步骤**：

#### Step 1: RefSeq分类（已完成）

```bash
# 使用当前配置运行
sbatch run_short_only.sh
# 输出 → results_short/
```

#### Step 2: RVDB分类（复用组装结果）

```bash
# 1. 构建RVDB Kraken2数据库（一次性工作）
mkdir /scratch/sp96859/.../rvdb_kraken2
cd /scratch/sp96859/.../rvdb_kraken2

# 下载RVDB
wget https://rvdb.dbi.udel.edu/download/C-RVDBvXX.X.fasta.gz

# 构建Kraken2数据库
kraken2-build --download-taxonomy --db .
kraken2-build --add-to-library C-RVDBvXX.X.fasta --db .
kraken2-build --build --db . --threads 32

# 2. 修改运行脚本使用RVDB
# 创建新脚本或编辑run_short_only.sh
KRAKEN2_DB="/scratch/sp96859/.../rvdb_kraken2"

# 3. 重新运行（只会重新分类，不重新组装）
sbatch run_short_only.sh
# 或手动指定输出目录避免覆盖
nextflow run metagenome_hybrid_workflow.nf \
    -c metagenome_hybrid_workflow.config \
    --input_short samplesheet_short.csv \
    --outdir_short results_short_rvdb \
    --kraken2_db /scratch/sp96859/.../rvdb_kraken2 \
    -resume
```

#### Step 3: 整合两个结果

```bash
# 使用提供的整合脚本
python integrate_dual_databases.py \
    --refseq results_short/kraken2_spades/sample_spades_report.txt \
    --rvdb results_short_rvdb/kraken2_spades/sample_spades_report.txt \
    --output integrated_spades_virus_report.txt

# 对MEGAHIT也同样操作
python integrate_dual_databases.py \
    --refseq results_short/kraken2_megahit/sample_megahit_report.txt \
    --rvdb results_short_rvdb/kraken2_megahit/sample_megahit_report.txt \
    --output integrated_megahit_virus_report.txt
```

---

### 方法2：构建合并数据库 ⭐⭐

**优势**：
- ✅ 一次运行，同时查询两个库
- ✅ 自动去重

**劣势**：
- ❌ 无法区分病毒来自哪个数据库
- ❌ 数据库更大（运行更慢）

**步骤**：

```bash
# 1. 下载两个数据库的FASTA
# RefSeq Viral
wget ftp://ftp.ncbi.nlm.nih.gov/refseq/release/viral/*.genomic.fna.gz

# RVDB
wget https://rvdb.dbi.udel.edu/download/C-RVDBvXX.X.fasta.gz

# 2. 合并构建Kraken2数据库
mkdir /scratch/sp96859/.../kraken2_viral_merged
cd /scratch/sp96859/.../kraken2_viral_merged

kraken2-build --download-taxonomy --db .

# 添加RefSeq序列
for f in viral.*.genomic.fna.gz; do
    kraken2-build --add-to-library $f --db .
done

# 添加RVDB序列
kraken2-build --add-to-library C-RVDBvXX.X.fasta --db .

# 构建（去重自动进行）
kraken2-build --build --db . --threads 32

# 3. 使用合并数据库
KRAKEN2_DB="/scratch/sp96859/.../kraken2_viral_merged"
sbatch run_short_only.sh
```

---

### 方法3：RefSeq主分析，RVDB补充验证 ⭐

**优势**：
- ✅ 主要结果基于高质量RefSeq
- ✅ RVDB用于发现潜在的新型病毒
- ✅ 最平衡的方案

**步骤**：

```bash
# 1. 主分析：RefSeq（当前）
sbatch run_short_only.sh
# 得到高置信度病毒列表

# 2. 提取"Unclassified"的contigs
# 这些可能是RefSeq中没有的病毒
grep "unclassified" results_short/kraken2_spades/*_classification.txt | \
    cut -f2 > unclassified_contigs.list

# 3. 对Unclassified contigs用RVDB验证
seqtk subseq results_short/spades_assembly/*_contigs.fa \
              unclassified_contigs.list > unclassified.fa

kraken2 --db /path/to/rvdb_kraken2 \
        --threads 16 \
        --report rvdb_unclassified_report.txt \
        unclassified.fa > rvdb_unclassified_output.txt

# 4. 合并：RefSeq分类 + RVDB补充
```

---

## 📊 整合结果示例

### 使用 `integrate_dual_databases.py` 后：

```
================================================================================
Dual Database Virus Integration - RefSeq + RVDB
================================================================================

Total unique viral classifications: 52
  ✅ Both databases (HIGH CONFIDENCE): 35
  ⚠️  RefSeq only (VALIDATED): 8
  ⚠️  RVDB only (NOVEL/RECENT): 9

Database overlap rate: 67.3%
================================================================================

════════════════════════════════════════════════════════════════════════════════
HIGH CONFIDENCE VIRUSES (Detected by BOTH Databases)
════════════════════════════════════════════════════════════════════════════════

Klebsiella phage ST147-VIM1phi7.1
  Tax ID: 2510480
  Rank: S1
  RefSeq: 13 contigs
  RVDB: 15 contigs
  Agreement: 0.87 ⭐
  Confidence: Very High

Ralstonia phage
  Tax ID: 123456
  Rank: G
  RefSeq: 8 contigs
  RVDB: 10 contigs
  Agreement: 0.80 ⭐
  Confidence: Very High

[更多共识病毒...]

────────────────────────────────────────────────────────────────────────────────
REFSEQ-ONLY VIRUSES (Validated, may be classical/well-studied)
────────────────────────────────────────────────────────────────────────────────

Human herpesvirus 1
  Tax ID: 10298
  RefSeq: 5 contigs
  Note: High-quality reference, RVDB may lack this specific strain

────────────────────────────────────────────────────────────────────────────────
RVDB-ONLY VIRUSES (Novel/Recent/Environmental - Needs validation)
────────────────────────────────────────────────────────────────────────────────

uncultured marine phage
  Tax ID: 999999
  RVDB: 12 contigs
  Note: May be novel/recent virus, recommend BLAST validation

================================================================================

RECOMMENDATIONS:
  1. Focus on 'Both databases' viruses (highest confidence)
  2. Use Agreement >0.5 for main conclusions
  3. Validate 'RVDB only' hits with BLAST
  4. 'RefSeq only' are likely well-characterized viruses
================================================================================
```

---

## 🎓 结果解读

### 三类病毒的置信度：

| 类别 | 置信度 | 含义 | 建议 |
|------|--------|------|------|
| **Both (Consensus)** | ⭐⭐⭐ 最高 | 两个独立数据库都检测到 | 直接用于发表 |
| **RefSeq only** | ⭐⭐ 高 | 高质量参考库中的病毒 | 可靠，可能是经典病毒 |
| **RVDB only** | ⭐ 中等 | 可能是新型/环境病毒 | **需要验证**（BLAST）|

### Agreement评分（针对Both类）：

```
Agreement >0.7: 两个库结果非常一致 → 极高可信度
Agreement 0.5-0.7: 结果较一致 → 高可信度（推荐阈值）
Agreement 0.3-0.5: 有差异但可接受 → 中等可信度
Agreement <0.3: 差异较大 → 需要进一步验证
```

---

## 💡 实际应用场景

### 场景1：病毒多样性研究

**目标**：全面了解样本中的病毒组成

**策略**：
```
1. RefSeq分类 → 获得经典/已知病毒
2. RVDB分类 → 发现可能的新型病毒
3. 整合结果 → 完整病毒多样性图谱

报告：
- Both databases: 35个（核心病毒组）
- RVDB only: 9个（潜在新型病毒）
- 总多样性: 44个病毒类群
```

### 场景2：新病毒发现

**目标**：识别可能的新型病毒

**策略**：
```
1. RefSeq分类 → 排除已知病毒
2. RVDB分类 → 初步筛选候选
3. 关注"RVDB only"类别 → 可能的新病毒
4. BLAST验证 → 确认新颖性

重点：
- RVDB only且contigs数量多的 → 候选新病毒
- Agreement很低的 → 分类不确定，手动检查
```

### 场景3：耐药基因监测

**目标**：检测携带耐药基因的噬菌体

**策略**：
```
1. 两个库都分类 → 全面检测
2. 关注"Both databases"高一致性的 → 可靠检测
3. 对检测到的噬菌体序列做基因注释
4. 筛选耐药基因（VIM, KPC, NDM等）

可靠性：
- Both + High agreement → 确信检测到
- 可以进一步测序验证
```

---

## 📈 预期收益

### 基于您当前的结果估算：

**RefSeq结果**（当前）：
```
SPAdes: 803个病毒contigs
MEGAHIT: 483个病毒contigs
```

**使用RVDB可能发现**：
```
额外病毒contigs: +5-15% (约40-120个)
来源：
- 环境噬菌体（RefSeq没收录的）
- 最新发现的病毒
- 病毒变异株
```

**两个库的重叠（估计）**：
```
Both databases: ~70% (约560个，高置信度)
RefSeq only: ~20% (约160个，经典病毒)
RVDB only: ~10% (约80个，新型/环境病毒)
```

---

## 🚀 完整实施流程

### Phase 1: RefSeq分析（已完成）

```bash
# 当前配置
KRAKEN2_DB="/scratch/sp96859/.../kraken2_Viral_ref"
sbatch run_short_only.sh

# 输出
results_short/
├── kraken2_megahit/*_report.txt  ← RefSeq结果
├── kraken2_spades/*_report.txt   ← RefSeq结果
└── merged_reports/*_virus_consensus.txt ← RefSeq共识
```

### Phase 2: 构建RVDB数据库（一次性）

```bash
# 创建数据库目录
mkdir -p /scratch/sp96859/Meta-genome-data-analysis/Apptainer/databases/rvdb_kraken2
cd /scratch/sp96859/Meta-genome-data-analysis/Apptainer/databases/rvdb_kraken2

# 下载RVDB（选择最新版本）
# 访问 https://rvdb.dbi.udel.edu/ 获取最新版本号
wget https://rvdb.dbi.udel.edu/download/C-RVDBv27.0.fasta.gz

# 解压
gunzip C-RVDBv27.0.fasta.gz

# 下载分类信息
kraken2-build --download-taxonomy --db .

# 添加RVDB序列到数据库
kraken2-build --add-to-library C-RVDBv27.0.fasta --db .

# 构建数据库（耗时，可能需要1-2小时）
kraken2-build --build --db . --threads 32 --max-db-size 50000000000

# 验证数据库
kraken2 --db . --report test_report.txt \
        results_short/spades_assembly/*_contigs.fa > test_output.txt
```

### Phase 3: RVDB分类

```bash
# 复制结果目录（避免覆盖）
cp -r results_short results_short_refseq

# 修改数据库路径
# 编辑run_short_only.sh 第47行：
KRAKEN2_DB="/scratch/sp96859/.../rvdb_kraken2"

# 运行RVDB分类
sbatch run_short_only.sh
# 输出到 results_short/（或重命名为results_short_rvdb）
```

### Phase 4: 整合结果

```bash
# 对SPAdes结果整合
python integrate_dual_databases.py \
    --refseq results_short_refseq/kraken2_spades/sample_spades_report.txt \
    --rvdb results_short/kraken2_spades/sample_spades_report.txt \
    --output integrated_spades_dual_db.txt

# 对MEGAHIT结果整合
python integrate_dual_databases.py \
    --refseq results_short_refseq/kraken2_megahit/sample_megahit_report.txt \
    --rvdb results_short/kraken2_megahit/sample_megahit_report.txt \
    --output integrated_megahit_dual_db.txt

# 查看结果
cat integrated_spades_dual_db.txt
```

---

## 📊 多层次置信度评估

整合后，您会有**四层置信度**：

### 🏆 Tier 1: 超高置信度
```
RefSeq ∩ RVDB ∩ (MEGAHIT ∩ SPAdes)

即：四个检测都命中
- RefSeq检测到 ✅
- RVDB检测到 ✅  
- MEGAHIT检测到 ✅
- SPAdes检测到 ✅

→ 发表级别可靠性！⭐⭐⭐⭐
```

### ⭐⭐⭐ Tier 2: 很高置信度
```
(RefSeq ∩ RVDB) 但只有一个组装器

或

(MEGAHIT ∩ SPAdes) 但只有一个数据库

→ 高可信度，推荐用于主要结论
```

### ⭐⭐ Tier 3: 中等置信度
```
单个数据库 + 单个组装器

→ 需要额外验证
```

### ⭐ Tier 4: 低置信度
```
RVDB only + 单个组装器 + Agreement低

→ 候选新型病毒，需严格验证
```

---

## 🔬 分析示例

### 假设的整合结果：

```csv
tax_id,rank,name,refseq_reads,rvdb_reads,detection,agreement
2510480,S1,Klebsiella phage ST147-VIM1phi7.1,13,15,Both,0.87
2842527,C1,Hendrixvirinae,37,35,Both,0.95
123456,G,Novel marine phage,0,25,RVDB only,NA
789012,S,T4-like phage,8,0,RefSeq only,NA
```

### 解读：

**Klebsiella phage** (Agreement: 0.87):
```
✅ RefSeq: 13 contigs
✅ RVDB: 15 contigs
✅ Agreement: 87% → 非常一致！
→ 极高置信度，适合发表
```

**Hendrixvirinae** (Agreement: 0.95):
```
✅ RefSeq: 37 contigs
✅ RVDB: 35 contigs
✅ Agreement: 95% → 几乎完全一致！
→ 最高置信度
```

**Novel marine phage** (RVDB only):
```
❌ RefSeq: 0
✅ RVDB: 25 contigs
→ 可能的新型病毒！
→ 建议：BLAST验证、功能注释
```

**T4-like phage** (RefSeq only):
```
✅ RefSeq: 8 contigs
❌ RVDB: 0
→ RefSeq中有，RVDB可能遗漏
→ 这可能是经典、已研究透的病毒
```

---

## 💰 成本-收益分析

### 成本：

| 项目 | 估计 |
|------|------|
| **下载RVDB** | ~5-10 GB, 10-30分钟 |
| **构建Kraken2数据库** | 1-2小时（32线程）|
| **存储空间** | ~30-50 GB |
| **RVDB分类运行** | +10-30%时间 |
| **整合分析** | 5-10分钟 |
| **总时间成本** | ~3-4小时（一次性）|

### 收益：

| 收益 | 估计提升 |
|------|---------|
| **病毒检出数量** | +5-15% |
| **新型病毒发现** | +可能5-20个候选 |
| **结果可信度** | Agreement评分提高 |
| **发表质量** | 双数据库验证更有说服力 |

---

## 🎯 我的推荐

### 阶段性实施：

#### 阶段1：当前（RefSeq）✅
```
现在：
✅ 使用RefSeq完成主要分析
✅ 获得共识病毒列表
✅ 识别完整病毒基因组

优势：
- 快速得到可靠结果
- RefSeq质量高
```

#### 阶段2：补充RVDB（可选）💡
```
如果：
- 发现有趣的"Unclassified"高丰度contigs
- 想提高病毒检出率
- 寻找新型病毒

行动：
1. 构建RVDB数据库（一次性）
2. 对现有contigs重新分类
3. 整合两个结果
4. 关注"RVDB only"的潜在新型病毒
```

#### 阶段3：验证与发表
```
重点：
✅ Both databases + High agreement → 主要发现
⚠️ RVDB only → 补充发现（需验证）
✅ 结合长读长viralFlye → 完整基因组

发表策略：
- 主要结果：双数据库共识病毒
- 补充结果：单数据库检测（标注需验证）
- 新发现：RVDB only经BLAST验证的
```

---

## 📋 快速决策

### 问自己：

**Q1: 我的主要目标是什么？**
- 已知病毒定量 → RefSeq足够 ✅
- 新病毒发现 → 需要RVDB 🔧

**Q2: 我有时间和资源吗？**
- 时间紧 → 用RefSeq ✅
- 想要全面分析 → 值得用RVDB 🔧

**Q3: 当前RefSeq结果满意吗？**
- 满意（检测到预期的病毒）→ RefSeq足够 ✅
- 不满意（检出率低）→ 尝试RVDB 🔧

**Q4: 是否要发表？**
- 是，且想要最高质量 → 双数据库验证 ⭐
- 否，内部分析 → RefSeq足够 ✅

---

## ✅ 总结

### 是否有意义？
**YES！非常有意义！** ⭐⭐⭐

**优势**：
1. ✅ **提高检出率** - 更全面的病毒覆盖
2. ✅ **交叉验证** - 两个库都检测到 = 高可信度
3. ✅ **发现新型病毒** - RVDB only = 候选新病毒
4. ✅ **发表质量** - 双数据库验证更有说服力

### 如何整合？
**推荐方法1**：分别分类 + Python脚本合并

**我已提供**：
- ✅ `integrate_dual_databases.py` - 整合脚本
- ✅ 完整的实施步骤
- ✅ 结果解读指南

### 建议执行时间？
**现在不急**，但未来值得做：
1. 先完成当前RefSeq分析
2. 发表或深入研究时，考虑RVDB补充
3. 使用整合脚本获得四层置信度评估

**两个数据库结合是高级病毒组学分析的最佳实践！** 🦠✨
