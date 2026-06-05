---
allowed-tools: Task, Read, Write, Bash, Grep, Glob
argument-hint: [dataset] [text_column] [analysis_type]
description: 文本分析 — 情感分析，关键词提取，主题建模，用户反馈挖掘
---

# 文本分析命令

对数据集 `$1` 的文本列 `$2` 进行文本挖掘分析，分析类型为 `$3`。

## Context
- 数据集位置: @data_storage/$1
- 文本列: $2
- 分析类型: $3 (sentiment / keywords / topics / full / survey)
- 当前工作目录: !`pwd`

## 分析任务

使用 **text-analysis** subagent 执行文本分析：

### 1. 情感分析 (sentiment / full)
- 正面/中性/负面三分类
- 情感强度评分 (0-1)
- 时间序列情感趋势
- 负面突增告警

### 2. 关键词提取 (keywords / full)
- TF-IDF + TextRank + KeyBERT 多方法
- 高频关键词词云
- 关键词共现网络
- 分人群/分时段关键词差异

### 3. 主题建模 (topics / full)
- LDA / BERTopic 主题提取
- 主题一致性评估
- 主题-时间分布
- 每个主题的典型文本示例

### 4. 调研分析 (survey)
- 开放题答案自动聚类
- 各选项的情感分布
- 跨人群观点差异
- 典型引用摘录

### 5. 舆情监测
- 日维度情感得分追踪
- 高频提及品牌/产品名
- 竞品声量对比

## 预期输出文件
- `analysis_reports/text_sentiment_$1.csv` — 情感分析结果
- `analysis_reports/text_topics_$1.csv` — 主题分布
- `analysis_reports/text_keywords_$1.csv` — 关键词提取结果
- `analysis_reports/text_report_$1.md` — 文本分析报告

## 示例
```bash
/text app_reviews.csv review_text sentiment
/text survey_results.csv open_answer survey
/text customer_feedback.csv comment full
/text social_media.csv post_content full
```
