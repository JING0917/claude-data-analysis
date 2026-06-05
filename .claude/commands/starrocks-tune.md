---
allowed-tools: Task, Read, Write, Bash, Grep, Glob
argument-hint: [profile_or_issue] [cluster_spec]
description: StarRocks集群调优 — Query Profile诊断，参数优化，资源管理，数据均衡
---

# StarRocks 集群调优命令

对StarRocks集群进行诊断调优，诊断对象 `$1`，集群规格 `$2`。

## Context
- 诊断对象: $1 (Query Profile文本 / 慢查询ID / 集群配置 / "cluster"表示全集群诊断)
- 集群规格: $2 (例如: "3FE+6BE, 16C64G, NVMe 3.5TB × 4", 可为空)
- 当前工作目录: !`pwd`

## 分析任务

使用 **starrocks-tuning** subagent 执行集群调优：

### 1. Query Profile 诊断
- 逐 Fragment → Operator 时间分解
- 各算子内存使用量分析
- 识别数据倾斜（各Instance处理行数差异）
- Exchange 数据量分析（Shuffle/Broadcast是否合理）

### 2. 慢查询定位
- 从审计日志/Profile找出慢查询
- Top N 耗资源查询（扫描行数 / 内存 / CPU）
- 相似查询模式聚类

### 3. 参数优化
- 会话级参数调整建议（并行度、Join策略、内存）
- BE/CN 配置审查 （mem_limit、线程池）
- FE 配置建议（Catalog管理、Compaction调度）

### 4. 资源与均衡
- CPU/内存/磁盘使用率水位评估
- Tablet分布均衡性检查
- Compaction积压诊断
- 副本健康状态

### 5. 输出方案
- 改动优先级排序 (P0/P1/P2)
- 参数调整前后对比
- 监控告警方案

## 预期输出文件
- `analysis_reports/sr_tuning_report.md` — 调优报告
- `analysis_reports/sr_profile_analysis.md` — Query Profile 节点级诊断
- `analysis_reports/sr_config_recommendations.md` — 配置参数建议

## 示例
```bash
/starrocks-tune query_profile.txt "3FE+6BE, 16C64G"
/starrocks-tune cluster "1FE+3BE, 8C32G, SSD 1TB"
/starrocks-tune "SELECT ... 执行超5分钟" "3FE+6BE, 16C64G"
```
