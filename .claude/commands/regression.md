---
allowed-tools: Task, Read, Write, Bash, Grep, Glob
argument-hint: [dataset] [dependent_var] [independent_vars]
description: 回归分析 — 关系建模，预测，特征重要性评估
---

# 回归分析命令

对数据集 `$1` 进行回归分析，因变量为 `$2`，自变量为 `$3`。

## Context
- 数据集位置: @data_storage/$1
- 因变量 (DV): $2
- 自变量 (IVs): $3 (逗号分隔)
- 当前工作目录: !`pwd`

## 分析任务

使用 **regression-analysis** subagent 执行回归分析：

### 1. 探索性分析
- 各变量分布特征（均值、中位数、偏度、峰度）
- 变量间相关性矩阵
- 散点图矩阵（DV vs 各IV）

### 2. 模型构建
- **OLS 基准模型**: 全变量回归 + 完整诊断
- **正则化模型**: Ridge / Lasso / Elastic Net 交叉验证
- **非线性扩展**: 多项式项、交互项、样条回归
- **稳健回归**: Huber / RANSAC（如有异常值）

### 3. 模型诊断
- 残差分析：残差vs拟合图、Q-Q图、Scale-Location图
- 多重共线性：VIF > 10 标记
- 异方差检验：Breusch-Pagan + White 检验
- 影响点：Cook's D > 4/n 标记
- 自相关：Durbin-Watson 检验

### 4. 结果解释
- 系数解释（原始单位 + 标准化）
- 边际效应（含交互项时尤为重要）
- 特征重要性排序
- 反事实预测：关键场景模拟

## 预期输出文件
- `analysis_reports/regression_report_$1.md` — 回归分析完整报告
- `analysis_reports/regression_coefficients_$1.csv` — 回归系数表
- `analysis_reports/regression_diagnostics_$1.csv` — 诊断检验结果

## 示例
```bash
/regression sales_data.csv revenue "ad_spend,price,discount,season_index"
/regression user_data.csv lifetime_value "avg_order,tenure_days,referrals,complaints"
/regression churn_data.csv is_churned "usage_freq,coupon_usage,service_calls,tenure"
```
