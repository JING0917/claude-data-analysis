---
allowed-tools: Task, Read, Write, Bash, Grep, Glob
argument-hint: [dataset] [treatment_var] [outcome_var] [method]
description: 因果推断分析 — 评估处理效应，准实验设计，区分相关与因果
---

# 因果推断分析命令

对数据集 `$1` 进行因果推断分析，评估 `$2` 对 `$3` 的因果效应，使用方法 `$4`。

## Context
- 数据集位置: @data_storage/$1
- 处理变量 (Treatment): $2
- 结果变量 (Outcome): $3
- 推断方法: $4 (did / psm / iv / rdd / scm / dml / all)
- 当前工作目录: !`pwd`

## 分析任务

使用 **causal-inference** subagent 执行因果推断：

### 1. 因果问题定义
- 明确处理和结果变量
- 确定目标估计量 (ATE / ATT / CATE)
- 绘制因果图 (DAG)，识别混杂、中介、对撞变量

### 2. 识别策略
- 根据数据结构和假设选择合适方法：
  - **DiD**: 有前后对照的面板数据
  - **PSM**: 可观测选择偏差，无面板数据
  - **IV**: 存在内生性，有工具变量
  - **RDD**: 有断点/阈值规则
  - **SCM**: 少量处理单元，多个对照单元
  - **DML**: 高维控制变量，需ML去偏

### 3. 估计与诊断
- 平衡性检验（PSM匹配前后）
- 平行趋势检验（DiD事件研究图）
- 弱工具变量检验（F > 10）
- 断点操纵检验（McCrary密度检验）

### 4. 稳健性检验
- 安慰剂检验（placebo test）
- 替换被解释变量/样本
- 敏感性分析（Rosenbaum bounds, E-value）

## 预期输出文件
- `analysis_reports/causal_inference_$1.md` — 因果推断分析报告
- `analysis_reports/causal_balance_$1.csv` — 协变量平衡性表
- `analysis_reports/causal_results_$1.csv` — 处理效应估计结果

## 示例
```bash
/causal policy_data.csv is_treated revenue did
/causal marketing_data.csv campaign participation_rate psm
/causal pricing_data.csv price_threshold sales rdd
/causal promotion_data.csv has_coupon order_value all
```
