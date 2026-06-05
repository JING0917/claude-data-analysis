---
allowed-tools: Task, Read, Write, Bash, Grep, Glob
argument-hint: [dataset] [conversion_col] [channel_col]
description: 营销归因分析 — 渠道贡献量化，转化路径分析，预算优化
---

# 营销归因分析命令

对数据集 `$1` 进行营销归因分析，转化标记列为 `$2`，渠道列为 `$3`。

## Context
- 数据集位置: @data_storage/$1
- 转化标记列: $2
- 渠道列: $3
- 当前工作目录: !`pwd`

## 分析任务

使用 **multi-touch-attribution** subagent 执行归因分析：

### 1. 规则归因基线
- 首次触点 / 末次触点 / 线性 / 时间衰减 / 位置归因
- 五种模型渠道权重对比
- 归因一致性评估

### 2. 数据驱动归因
- **Shapley Value**: 每个渠道的边际贡献
- **马尔可夫链**: 移除效应计算渠道重要性
- 规则归因 vs 数据驱动归因差异分析

### 3. 转化路径分析
- 各渠道触点频次
- 转化路径长度分布
- 高转化率路径识别
- 路径间流转关系

### 4. 渠道ROI分析
- 各渠道归因收入 vs 渠道成本
- ROI / ROAS 计算
- 边际效益分析

### 5. 预算优化
- 当前预算分配效率评估
- 最优预算分配模拟
- 预算调整建议

## 预期输出文件
- `analysis_reports/attribution_results_$1.csv` — 各模型归因结果
- `analysis_reports/attribution_paths_$1.csv` — 转化路径明细
- `analysis_reports/attribution_report_$1.md` — 归因分析报告

## 示例
```bash
/attribution user_touchpoints.csv converted channel
/attribution campaign_data.csv is_converted utm_source
/attribution promotion_journey.csv purchase_flag touch_channel
```
