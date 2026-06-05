---
allowed-tools: Task, Read, Write, Bash, Grep, Glob
argument-hint: [analysis_report] [audience]
description: 数据叙事 — 将分析结果转化为面向决策者的叙事、摘要和行动建议
---

# 数据叙事命令

基于分析报告 `$1`，为 `$2` 受众撰写数据叙事和决策文件。

## Context
- 分析报告: @analysis_reports/$1
- 目标受众: $2 (executive / product / operations / engineering / data)
- 当前工作目录: !`pwd`

## 分析任务

使用 **data-storyteller** subagent 执行数据叙事：

### 1. 分析报告审阅
- 识别报告中最重要的 1-3 个发现
- 按业务影响大小排序
- 区分"有趣"和"能驱动决策"的洞察

### 2. 受众适配
- **executive (高管)**: 3句话摘要 + 1张图 + 1个建议
- **product (产品)**: 用户行为洞察 + A/B机会 + 优先级排序
- **operations (运营)**: 效率指标 + 流程瓶颈 + 可执行行动
- **engineering (工程)**: 数据质量 + 系统影响 + 技术建议
- **data (数据)**: 方法论 + 假设 + 可复现性

### 3. 叙事构建
- 用 SCR 框架或金字塔原理组织逻辑
- 写一句话核心结论（非分析师也能听懂）
- 预判 Top 3 反对意见并提前回应
- 构建证据链：观察 → 对比 → 因果推理 → 验证 → 建议

### 4. 决策推动
- 明确决策选项（A / B / C）
- 给出清晰推荐和理由
- 评估"不行动"的代价
- 设置后续验证指标

## 预期输出文件
- `analysis_reports/executive_summary_$1` — 1页高管摘要
- `analysis_reports/decision_memo_$1` — 结构化决策备忘
- `analysis_reports/narrative_script_$1` — 完整叙事含证据链

## 示例
```bash
/story churn_analysis_2026Q1.md executive
/story ab_test_results.md product
/story anomaly_attribution_gmv.md operations
/story user_profile_report.md data
```
