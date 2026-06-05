---
allowed-tools: Task, Read, Write, Bash, Grep, Glob
argument-hint: [dataset] [target_column] [date_column]
description: 时间序列预测 — 销量/营收/GMV预测，趋势分析，周期性检测
---

# 时间序列预测命令

对数据集 `$1` 进行时间序列预测，目标列 `$2`，时间列为 `$3`。

## Context
- 数据集位置: @data_storage/$1
- 目标列 (Target): $2
- 时间列 (Date): $3
- 当前工作目录: !`pwd`

## 分析任务

使用 **time-series-forecasting** subagent 执行时间序列分析：

### 1. 探索性分析
- 数据平稳性检验（ADF + KPSS）
- STL 趋势分解（趋势/季节/残差）
- ACF/PACF 自相关图
- 季节性检测和周期识别

### 2. 预测模型
- **SARIMA**: 考虑季节性的自回归移动平均模型
- **Holt-Winters**: 指数平滑（加法/乘法季节）
- **Prophet**: 处理节假日和趋势断点
- **XGBoost**: 机器学习预测（含lag特征）
- 多模型对比 + 时间序列交叉验证

### 3. 模型评估
- MAE, RMSE, MAPE, SMAPE 多指标对比
- 滚动窗口回测（rolling forecast origin）
- 残差诊断（白噪声检验、残差自相关）

### 4. 业务输出
- 预测值 + 置信区间（80%, 95%）
- 趋势解读和业务建议
- 关键影响因素识别

## 预期输出文件
- `analysis_reports/forecast_results_$1.csv` — 预测结果（含置信区间）
- `analysis_reports/forecast_metrics_$1.csv` — 各模型评估指标对比
- `analysis_reports/forecast_report_$1.md` — 预测分析报告

## 示例
```bash
/forecast daily_sales.csv revenue date
/forecast weekly_orders.csv order_cnt week_start
/forecast monthly_gmv.csv gmv month
```
