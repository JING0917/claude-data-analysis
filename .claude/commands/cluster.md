---
allowed-tools: Task, Read, Write, Bash, Grep, Glob
argument-hint: [dataset] [features] [task_type]
description: 聚类与分类分析 — 用户分群，客户画像，预测建模
---

# 聚类与分类分析命令

对数据集 `$1` 进行聚类或分类分析，特征列为 `$2`，任务类型为 `$3`。

## Context
- 数据集位置: @data_storage/$1
- 特征列: $2 (逗号分隔的特征名称)
- 任务类型: $3 (clustering / classification / both)
- 如有目标列，请在 $2 中额外标注 target_col=xxx
- 当前工作目录: !`pwd`

## 分析任务

使用 **clustering-classification** subagent 执行分析：

### 聚类任务 (clustering)
1. **数据预处理**: 标准化、缺失值处理、异常值识别
2. **最优K选择**: 肘部法则 + 轮廓系数 + Gap统计量
3. **多方法对比**: K-Means / GMM / HDBSCAN / 层次聚类
4. **聚类画像**: 每个聚类的特征均值、分布、业务含义
5. **可视化**: PCA/t-SNE降维图、雷达图

### 分类任务 (classification)
1. **数据准备**: 训练/验证/测试集划分（分层抽样）
2. **基线模型**: Logistic Regression 作为baseline
3. **多模型对比**: XGBoost / LightGBM / Random Forest / CatBoost
4. **模型评估**: AUC-ROC, F1, 混淆矩阵, 校准曲线
5. **特征重要性**: SHAP值 + 排列重要性

## 预期输出文件
- `analysis_reports/clustering_report_$1.md` — 聚类分析报告（含画像和可视化建议）
- `analysis_reports/classification_report_$1.md` — 分类模型报告（含模型对比）
- `analysis_reports/segments_$1.csv` — 分群结果数据
- `analysis_reports/model_metrics_$1.csv` — 分类模型评估指标

## 示例
```bash
/cluster user_data.csv "age,income,frequency,avg_order,recency" clustering
/cluster churn_data.csv "usage_days,complaints,tenure,target_col=churned" classification
/cluster customer_360.csv "orders,coupons,clicks,visits,gmv,platform" both
```
