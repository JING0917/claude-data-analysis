---
allowed-tools: Task, Read, Write, Bash, Grep, Glob
argument-hint: [table_name] [model_type] [description]
description: StarRocks建表设计 — 表模型选择，分区/分桶策略，物化视图，DDL生成
---

# StarRocks DDL 建模命令

为业务表 `$1` 设计StarRocks建表方案，模型类型 `$2`，业务描述 `$3`。

## Context
- 表名: $1
- 模型类型: $2 (duplicate: 明细 / primary: 主键 / aggregate: 聚合 / unique: 更新)
- 业务描述: $3 (含字段名、类型、查询模式的文字描述)
- 当前工作目录: !`pwd`

## 分析任务

使用 **starrocks-ddl** subagent 执行表结构设计：

### 1. 需求分析
- 业务场景判断（日志流水 / 事实表 / 维表 / 汇总表）
- 数据量级估算（日增、周增、月增）
- 访问模式分析（点查 / 范围扫描 / 聚合查询）
- 写入模式（实时流 / 批量导入 / 定时同步）

### 2. 模型选择
- 明细模型: 适合日志/事件表，无更新
- 主键模型: 适合有Upsert的事实表
- 聚合模型: 适合预聚合的汇总表
- 提供选型理由和技术权衡

### 3. 分区与分桶设计
- 分区键 + 分区粒度（按天/按月）
- 动态分区策略
- 分桶键 + 分桶数计算
- 数据均衡性评估

### 4. 索引与压缩
- 排序键 (Sort Key) 列选择和顺序
- Bloom Filter 索引建议
- Bitmap 索引建议
- 压缩算法选择 (LZ4 / ZSTD)

### 5. DDL 生成
- 完整 CREATE TABLE 语句
- 完整物化视图 DDL（如需要）
- Schema 设计文档和最佳实践说明

## 预期输出文件
- `analysis_reports/sr_ddl_{$1}.sql` — 完整建表DDL
- `analysis_reports/sr_mv_{$1}.sql` — 物化视图DDL
- `analysis_reports/sr_schema_design_{$1}.md` — 设计说明文档

## 示例
```bash
/starrocks-ddl order_events duplicate "订单事件流水: order_id, user_id, event_type, amount, event_time, 按天分区, 按order_id分桶"
/starrocks-ddl user_facts primary "用户事实表: user_id, last_order_time, total_gmv, order_cnt, 实时更新"
/starrocks-ddl daily_sales aggregate "日销汇总: dt, category, brand, order_cnt, revenue, 按天分区"
```
