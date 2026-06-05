---
allowed-tools: Task, Read, Write, Bash, Grep, Glob
argument-hint: [dataset] [metric] [baseline_period]
description: 异动归因分析 — 诊断指标波动，定位根因，维度下钻
---

# 异动归因分析命令

对数据集 `$1` 中的指标 `$2` 进行异动归因分析，基线期为 `$3`。

## Context
- 数据集位置: @data_storage/$1
- 分析指标: $2
- 基线期间: $3 (例如: "上周同期", "上月同期", "2026-04-01~2026-04-15")
- 当前工作目录: !`pwd`

## 分析任务

使用 **anomaly-attribution** subagent 执行异动归因分析：

### 1. 异常检测
- 计算指标在观测期与基线期的变化幅度和方向
- 评估变化的统计显著性（Z-score, p-value）
- 判断异常类型：突增/突降、趋势变化、季节性波动

### 2. 维度下钻
- 按关键维度（平台、区域、用户类型、渠道等）分解指标变化
- 计算每个维度值的贡献度和解释力
- 使用 Adtributor / 惊喜度评分 排序根因候选

### 3. 根因定位
- 验证候选根因的时间先后关系
- 排除混杂因素和替代解释
- 多指标交叉验证

### 4. 输出报告
- 异动摘要：幅度、方向、显著性
- Top 3-5 归因因素及贡献度
- 排除的替代解释
- 行动建议和监控方案

## 预期输出文件
- `analysis_reports/anomaly_attribution_$1_$2.md` — 异动归因分析报告
- `analysis_reports/anomaly_drilldown_$1.csv` — 维度下钻明细数据

## 示例
```bash
/anomaly order_data.csv order_cnt "上周同期"
/anomaly user_behavior.csv conversion_rate "上月同期"
/anomaly revenue.csv gmv "2026-04-01~2026-04-15"
```
