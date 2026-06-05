---
allowed-tools: Task, Read, Write, Bash, Grep, Glob
argument-hint: [business_domain] [goal_description]
description: 指标体系设计 — 北极星指标、指标树拆解、指标字典
---

# 指标体系设计命令

根据业务目标 `$2`，在 `$1` 业务领域设计完整的指标体系。

## Context
- 业务领域: $1
- 业务目标: $2
- 当前工作目录: !`pwd`

## 分析任务

使用 **metrics-framework** subagent 执行指标体系设计：

### 1. 北极星指标设计
- 根据业务目标，提出 2-3 个北极星指标候选方案
- 评估每个候选的：可衡量性、前置性、业务可控性、价值相关性
- 推荐一个北极星指标并说明理由

### 2. 指标树拆解
- 从北极星指标出发，拆解 3 层指标树
- 识别输入指标（可操作）和输出指标（结果性）
- 设置护栏指标（防止过度优化）

### 3. 指标字典
- 每个指标的精确定义和计算公式
- 数据源、刷新频率、责任人
- 基线和目标值
- 异常检测规则

### 4. 平衡计分卡
- 财务 / 客户 / 流程 / 创新 四维度覆盖检查
- 先行指标 vs 滞后指标搭配

## 预期输出文件
- `analysis_reports/metric_tree_$1.md` — 完整指标树和拆解逻辑
- `analysis_reports/metric_dictionary_$1.csv` — 指标定义和元数据表
- `analysis_reports/north_star_evaluation_$1.md` — 北极星指标评估和推荐

## 示例
```bash
/metrics ecommerce "提升用户复购率"
/metrics saas "提高企业客户的周活跃率"
/metrics content_platform "增加用户日均使用时长"
```
