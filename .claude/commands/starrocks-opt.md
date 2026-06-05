---
allowed-tools: Task, Read, Write, Bash, Grep, Glob
argument-hint: [sql_file_or_query] [optimize_target]
description: StarRocks SQL优化 — 执行计划分析，查询改写，索引/分区优化
---

# StarRocks SQL 优化命令

对SQL文件或查询 `$1` 进行StarRocks性能优化，优化目标 `$2`。

## Context
- SQL来源: $1 (文件路径 / 直接粘贴SQL)
- 优化目标: $2 (latency: 延迟优先 / throughput: 吞吐优先 / memory: 内存优先 / all)
- 当前工作目录: !`pwd`

## 分析任务

使用 **starrocks-optimization** subagent 执行SQL优化：

### 1. 执行计划分析
- EXPLAIN 完整执行计划解读
- 逐算子成本拆解 (OlapScan → Join → Aggregate → Sort)
- 识别扫描瓶颈、Join瓶颈、聚合瓶颈

### 2. Join 优化
- Colocate Join 检查（两表分桶键是否一致）
- Broadcast Join 适用性判断（右表行数 < broadcast_row_count_limit）
- Join 顺序重排建议

### 3. 谓词优化
- 分区裁剪验证 (是否命中分区列)
- 排序键过滤效率 (是否利用前缀索引)
- Bloom Filter / Bitmap 索引命中检查

### 4. 聚合与排序优化
- 二层聚合、三阶段聚合适用性
- 窗口函数边界和排序优化
- LIMIT 下推可能性

### 5. 改写方案输出
- 提供 2-3 个改写方案
- 每个方案的代价估算和执行计划对比
- 推荐方案 + 预期提升倍数

## 预期输出文件
- `analysis_reports/sr_optimization_report.md` — SQL优化报告
- `analysis_reports/sr_explain_analysis.md` — 执行计划分析

## 示例
```bash
/starrocks-opt slow_query.sql latency
/starrocks-opt "SELECT ... FROM orders JOIN users ..." memory
/starrocks-opt daily_report.sql all
```
