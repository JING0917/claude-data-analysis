---
allowed-tools: Task, Read, Write, Bash, Grep, Glob
argument-hint: [query_type] [description]
description: 复杂SQL生成 — 多层CTE、窗口函数、留存分析、漏斗、归因
---

# 复杂SQL生成命令

根据需求 `$2`，生成类型为 `$1` 的分析SQL。

## Context
- SQL类型: $1
- 需求描述: $2
- 数据库: StarRocks (默认) / MySQL / PostgreSQL / Hive
- 当前工作目录: !`pwd`

## 分析任务

使用 **sql-expert** subagent 生成高质量分析SQL：

### 1. 需求澄清
- 确认查询粒度（按天/按人/按订单）
- 明确输出字段和排序规则
- 确认分区键以优化查询性能

### 2. SQL生成
- 使用多层CTE拆解复杂逻辑
- 选择合适的窗口函数
- 显式处理NULL值
- 添加业务注释

### 3. 性能优化
- 确保分区裁剪生效
- 检查JOIN类型和顺序
- 谓词下推验证
- 预估扫描行数

### 4. 输出验证
- 提供每个CTE的预期行数
- 边界情况检查
- 提供简单的手工验证SQL

## 支持的查询类型

| 类型 | 说明 |
|------|------|
| `retention` | 同期群留存矩阵 |
| `funnel` | 多步骤转化漏斗 |
| `session` | 用户会话划分和统计 |
| `attribution` | 渠道归因（末次/首次/线性） |
| `cohort` | 同期群行为追踪 |
| `lifecycle` | 用户生命周期（新/活/沉/流） |
| `ranking` | Top-N分组排名 |
| `general` | 通用复杂查询 |

## 预期输出文件
- `SQL/{query_name}.sql` — 完整可执行SQL
- `SQL/{query_name}_explain.md` — 查询逻辑说明（复杂查询时）

## 示例
```bash
/sql retention "计算新用户注册后30天的每日留存率"
/sql funnel "首页→商品页→加购→下单→支付 各步骤转化率"
/sql session "按用户划分会话，30分钟无操作算新会话"
/sql attribution "计算各渠道的末次触点归因权重"
```
