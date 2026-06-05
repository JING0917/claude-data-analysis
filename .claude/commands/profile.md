---
allowed-tools: Task, Read, Write, Bash, Grep, Glob
argument-hint: [dataset] [value_col] [date_col]
description: 用户画像建模 — RFM分析，LTV预估，流失预测，用户分群
---

# 用户画像建模命令

对数据集 `$1` 进行用户画像建模，价值列 `$2`，日期间隔列 `$3`。

## Context
- 数据集位置: @data_storage/$1
- 价值列 (Value): $2
- 日期间隔列 (Date): $3
- 当前工作目录: !`pwd`

## 分析任务

使用 **user-profile-modeling** subagent 执行用户画像分析：

### 1. RFM 建模
- Recency / Frequency / Monetary 三维计算
- 1-5 分评分体系
- RFM 立方体分组 (125 格 → 8 类核心标签)
- 经典标签: 高价值、重点保持、重点发展、流失挽回

### 2. LTV 预估
- BG/NBD + Gamma-Gamma 概率模型
- 同期群 (Cohort) LTV 分析
- 预测 LTV vs 实际 LTV 对比
- LTV/CAC 比分析（如有成本数据）

### 3. 流失预测
- 流失定义和告警阈值
- XGBoost/LightGBM 流失模型
- 流失概率排名（TOP 1000 风险用户）
- Top 流失风险因素 + SHAP 解释

### 4. 综合画像
- K-Means 分群 + PCA 可视化
- 各客群特征的雷达图
- 差异化运营策略建议

## 预期输出文件
- `analysis_reports/user_rfm_$1.csv` — RFM 评分明细
- `analysis_reports/user_ltv_$1.csv` — LTV 预估结果
- `analysis_reports/user_churn_$1.csv` — 流失预测名单
- `analysis_reports/user_profiles_$1.csv` — 用户综合画像标签
- `analysis_reports/user_profile_report_$1.md` — 用户画像分析报告

## 示例
```bash
/profile user_orders.csv order_amount order_date
/profile membership_data.csv spend_amount last_purchase_date
/profile user_behavior.csv gmv visit_date
```
