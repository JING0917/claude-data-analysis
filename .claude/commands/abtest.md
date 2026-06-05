---
allowed-tools: Task, Read, Write, Bash, Grep, Glob
argument-hint: [dataset] [metric] [variant_col]
description: A/B测试分析 — 实验设计，样本量计算，显著性检验
---

# A/B测试分析命令

对数据集 `$1` 进行A/B测试分析，主要指标为 `$2`，分组变量为 `$3`。

## Context
- 数据集位置: @data_storage/$1
- 分析指标: $2
- 分组变量: $3 (包含对照组和实验组标识)
- 对照组标识: control (可指定)
- 当前工作目录: !`pwd`

## 分析任务

使用 **ab-testing** subagent 执行A/B测试分析：

### 1. 实验前设计（如仅有历史数据）
- 根据基线指标计算所需样本量
- 给定MDE（最小可检测效应），推荐实验时长
- 功效分析（power ≥ 80%）

### 2. 实验数据分析（如有实验数据）
- **SRM检验**: 样本比例不匹配检测（p < 0.001 则实验无效）
- **主要指标**: t检验 / Z检验 + 置信区间 + lift%
- **效应量**: Cohen's d / 相对提升率
- **自助法CI**: Bootstrap 置信区间（稳健性）

### 3. 多指标分析
- 护栏指标逐一检验
- 多重比较校正（Benjamini-Hochberg FDR）
- 多臂实验的方差分析

### 4. 异质性分析
- 新老用户子群分析
- 平台/设备子群分析
- CUPED方差缩减（如有实验前数据）

### 5. 决策建议
- 主要指标 + 护栏指标综合判断
- Launch / No-Launch / 延长实验
- 实验Learnings记录

## 预期输出文件
- `analysis_reports/abtest_report_$1.md` — A/B测试完整报告
- `analysis_reports/abtest_metrics_$1.csv` — 各指标检验结果
- `analysis_reports/abtest_subgroup_$1.csv` — 子群分析结果

## 示例
```bash
/abtest experiment_0421.csv conversion_rate variant_group
/abtest landing_page_test.csv ctr page_version
/abtest pricing_test.csv avg_order_value price_tier
```
