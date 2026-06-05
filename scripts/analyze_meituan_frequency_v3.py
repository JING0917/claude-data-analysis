#!/usr/bin/env python3
# 小蚕用户美团频次差异分析V3 - 包含同用户/非同用户指标，不剔除异常数据
import pandas as pd
import numpy as np
import os
import sys
from datetime import datetime

def load_and_prepare_data(input_excel_path):
    """加载数据并进行列名映射"""
    print(f"正在读取Excel文件: {input_excel_path}")

    # 读取原始Excel文件
    df = pd.read_excel(input_excel_path)
    print(f"原始数据形状: {df.shape}")
    print(f"原始用户数: {len(df):,}")

    # 显示列名
    print(f"原始列名: {list(df.columns)}")

    # 列名映射到英文（便于代码处理）
    column_mapping = {
        '用户ID': 'user_id',
        '采集美团下单量': 'meituan_order_count',
        '小蚕下单量': 'silk_total_orders',
        '小蚕美团下单量': 'silk_meituan_orders',
        '小蚕饿了么下单量': 'silk_eleme_orders',
        '小蚕京东下单量': 'silk_jd_orders',
        '同用户美团下单量': 'same_user_meituan_orders',
        '非同用户美团下单量': 'different_user_meituan_orders'
    }

    # 重命名列
    df = df.rename(columns=column_mapping)

    # 检查必要的列是否存在
    required_columns = ['meituan_order_count', 'silk_meituan_orders',
                       'same_user_meituan_orders', 'different_user_meituan_orders']

    for col in required_columns:
        if col not in df.columns:
            print(f"警告: 缺少必要列 {col}")

    print(f"处理后的列名: {list(df.columns)}")

    return df

def analyze_overall_metrics(df):
    """整体分析指标"""
    print(f"\n=== 整体分析 ===")

    # 基本统计
    total_users = len(df)

    # 订单匹配相关指标
    total_meituan_orders = df['meituan_order_count'].sum()
    total_silk_meituan_orders = df['silk_meituan_orders'].sum()
    total_same_user_orders = df['same_user_meituan_orders'].sum()
    total_different_user_orders = df['different_user_meituan_orders'].sum()

    # 平均值
    avg_meituan_orders = df['meituan_order_count'].mean().round(2)
    avg_silk_meituan_orders = df['silk_meituan_orders'].mean().round(2)
    avg_same_user_orders = df['same_user_meituan_orders'].mean().round(2)
    avg_different_user_orders = df['different_user_meituan_orders'].mean().round(2)

    # 匹配率计算
    # 总匹配订单数 = 同用户订单数 + 非同用户订单数
    total_matched_orders = total_same_user_orders + total_different_user_orders

    if total_meituan_orders > 0:
        overall_match_rate = round(total_matched_orders * 100.0 / total_meituan_orders, 2)
    else:
        overall_match_rate = 0

    if total_silk_meituan_orders > 0:
        silk_match_rate = round(total_matched_orders * 100.0 / total_silk_meituan_orders, 2)
    else:
        silk_match_rate = 0

    # 同用户匹配率
    if total_matched_orders > 0:
        same_user_match_rate = round(total_same_user_orders * 100.0 / total_matched_orders, 2)
    else:
        same_user_match_rate = 0

    # 业务逻辑检查（仅统计，不剔除）
    logic_violation = (df['silk_meituan_orders'] > df['meituan_order_count'])
    violation_count = logic_violation.sum()
    violation_percentage = round(violation_count * 100.0 / total_users, 2)

    print(f"总用户数: {total_users:,}")
    print(f"总美团订单数: {total_meituan_orders:,}")
    print(f"总小蚕美团订单数: {total_silk_meituan_orders:,}")
    print(f"总同用户订单数: {total_same_user_orders:,}")
    print(f"总非同用户订单数: {total_different_user_orders:,}")
    print(f"总匹配订单数: {total_matched_orders:,}")
    print(f"整体匹配率（匹配订单/美团订单）: {overall_match_rate}%")
    print(f"小蚕匹配率（匹配订单/小蚕美团订单）: {silk_match_rate}%")
    print(f"同用户匹配占比: {same_user_match_rate}%")
    print(f"违反业务逻辑记录数（小蚕>美团）: {violation_count:,} ({violation_percentage}%)")

    # 差异分析
    df['订单差异'] = df['meituan_order_count'] - df['silk_meituan_orders']
    df['差异率'] = np.where(
        df['meituan_order_count'] > 0,
        (df['订单差异'] * 100.0 / df['meituan_order_count']).round(2),
        0
    )

    # 差异分布
    positive_gap = (df['订单差异'] > 0).sum()
    zero_gap = (df['订单差异'] == 0).sum()
    negative_gap = (df['订单差异'] < 0).sum()

    positive_gap_rate = round(positive_gap * 100.0 / total_users, 2)
    zero_gap_rate = round(zero_gap * 100.0 / total_users, 2)
    negative_gap_rate = round(negative_gap * 100.0 / total_users, 2)

    print(f"\n订单差异分析:")
    print(f"正差异（美团>小蚕）: {positive_gap:,} ({positive_gap_rate}%)")
    print(f"零差异（美团=小蚕）: {zero_gap:,} ({zero_gap_rate}%)")
    print(f"负差异（美团<小蚕）: {negative_gap:,} ({negative_gap_rate}%)")

    # 用户分层（基于订单差异）
    conditions = [
        (df['订单差异'] >= 3) & (df['差异率'] >= 50),
        (df['订单差异'] >= 2),
        (df['订单差异'] == 1),
        (df['订单差异'] == 0),
        (df['订单差异'] < 0),
    ]

    choices = ['高潜力用户', '中潜力用户', '低潜力用户', '无差异用户', '负差异用户']
    df['用户分层'] = np.select(conditions, choices, default='其他')

    # 返回整体指标
    overall_metrics = {
        'total_users': total_users,
        'total_meituan_orders': total_meituan_orders,
        'total_silk_meituan_orders': total_silk_meituan_orders,
        'total_same_user_orders': total_same_user_orders,
        'total_different_user_orders': total_different_user_orders,
        'total_matched_orders': total_matched_orders,
        'overall_match_rate': overall_match_rate,
        'silk_match_rate': silk_match_rate,
        'same_user_match_rate': same_user_match_rate,
        'violation_count': violation_count,
        'violation_percentage': violation_percentage,
        'avg_meituan_orders': avg_meituan_orders,
        'avg_silk_meituan_orders': avg_silk_meituan_orders,
        'avg_same_user_orders': avg_same_user_orders,
        'avg_different_user_orders': avg_different_user_orders,
        'positive_gap': positive_gap,
        'zero_gap': zero_gap,
        'negative_gap': negative_gap,
        'positive_gap_rate': positive_gap_rate,
        'zero_gap_rate': zero_gap_rate,
        'negative_gap_rate': negative_gap_rate,
        'df': df  # 包含新增列的DataFrame
    }

    return overall_metrics

def analyze_by_match_type(df):
    """按匹配类型分析（根据用户业务逻辑重新分类）"""
    print(f"\n=== 按匹配类型分析（用户业务逻辑） ===")

    # 创建匹配类型分类（根据用户描述的业务逻辑）
    conditions = [
        (df['same_user_meituan_orders'] > 0) & (df['different_user_meituan_orders'] == 0),
        (df['same_user_meituan_orders'] == 0) & (df['different_user_meituan_orders'] > 0),
        (df['same_user_meituan_orders'] > 0) & (df['different_user_meituan_orders'] > 0),
        (df['same_user_meituan_orders'] == 0) & (df['different_user_meituan_orders'] == 0),
    ]

    # 根据用户描述的业务逻辑命名
    choices = ['用户自己下单', '订单完全由其他有关系用户下单', '订单部分由其他用户下单', '用户美团数据可能异常']
    df['匹配类型'] = np.select(conditions, choices, default='未知')

    # 添加匹配类型简写（用于报告显示）
    short_names = ['用户自己下单', '其他用户下单', '混合下单', '数据异常']
    df['匹配类型简写'] = np.select(conditions, short_names, default='未知')

    match_type_stats = []
    match_types_full = ['用户自己下单', '订单完全由其他有关系用户下单', '订单部分由其他用户下单', '用户美团数据可能异常']

    for match_type in match_types_full:
        type_df = df[df['匹配类型'] == match_type]
        if len(type_df) > 0:
            # 计算该类型的各项指标
            # 美团下单空间 = 美团订单 - 小蚕美团订单
            avg_remaining_space = (type_df['meituan_order_count'] - type_df['silk_meituan_orders']).mean().round(2)
            total_remaining_space = (type_df['meituan_order_count'] - type_df['silk_meituan_orders']).sum()

            # 用户中美团下单空间>0的比例
            positive_space_rate = round((type_df['meituan_order_count'] > type_df['silk_meituan_orders']).sum() * 100.0 / len(type_df), 2)

            stats = {
                'match_type': match_type,
                'short_name': short_names[match_types_full.index(match_type)],
                'user_count': len(type_df),
                'user_percentage': round(len(type_df) * 100.0 / len(df), 2),
                'avg_meituan_orders': type_df['meituan_order_count'].mean().round(2),
                'avg_silk_meituan_orders': type_df['silk_meituan_orders'].mean().round(2),
                'avg_same_user_orders': type_df['same_user_meituan_orders'].mean().round(2),
                'avg_different_user_orders': type_df['different_user_meituan_orders'].mean().round(2),
                'avg_order_gap': type_df['订单差异'].mean().round(2),
                'avg_gap_percentage': type_df['差异率'].mean().round(2),
                'violation_rate': round((type_df['silk_meituan_orders'] > type_df['meituan_order_count']).sum() * 100.0 / len(type_df), 2),
                'avg_remaining_space': avg_remaining_space,
                'total_remaining_space': total_remaining_space,
                'positive_space_rate': positive_space_rate,
            }
            match_type_stats.append(stats)

            print(f"\n{match_type}:")
            print(f"  用户数: {stats['user_count']:,} ({stats['user_percentage']}%)")
            print(f"  平均美团订单: {stats['avg_meituan_orders']}单")
            print(f"  平均小蚕美团订单: {stats['avg_silk_meituan_orders']}单")
            print(f"  平均同用户订单: {stats['avg_same_user_orders']}单")
            print(f"  平均非同用户订单: {stats['avg_different_user_orders']}单")
            print(f"  平均美团下单空间: {stats['avg_remaining_space']}单")
            print(f"  美团下单空间>0的用户比例: {stats['positive_space_rate']}%")
            print(f"  违反业务逻辑比例: {stats['violation_rate']}%")

    return match_type_stats, df

def analyze_by_user_segment(df):
    """按用户分层分析"""
    print(f"\n=== 按用户分层分析 ===")

    segment_stats = []
    for segment in ['高潜力用户', '中潜力用户', '低潜力用户', '无差异用户', '负差异用户']:
        segment_df = df[df['用户分层'] == segment]
        if len(segment_df) > 0:
            # 计算该分层的各项指标
            stats = {
                'segment': segment,
                'user_count': len(segment_df),
                'user_percentage': round(len(segment_df) * 100.0 / len(df), 2),
                'avg_meituan_orders': segment_df['meituan_order_count'].mean().round(2),
                'avg_silk_meituan_orders': segment_df['silk_meituan_orders'].mean().round(2),
                'avg_same_user_orders': segment_df['same_user_meituan_orders'].mean().round(2),
                'avg_different_user_orders': segment_df['different_user_meituan_orders'].mean().round(2),
                'avg_order_gap': segment_df['订单差异'].mean().round(2),
                'avg_gap_percentage': segment_df['差异率'].mean().round(2),
                'match_type_distribution': segment_df['匹配类型'].value_counts().to_dict(),
            }
            segment_stats.append(stats)

            print(f"\n{segment}:")
            print(f"  用户数: {stats['user_count']:,} ({stats['user_percentage']}%)")
            print(f"  平均订单差异: {stats['avg_order_gap']}单")
            print(f"  匹配类型分布: {stats['match_type_distribution']}")

    return segment_stats

def analyze_by_order_volume(df):
    """按美团订单量分层分析"""
    print(f"\n=== 按美团订单量分层分析 ===")

    order_volume_stats = []
    volume_tiers = [
        ('美团1单', df['meituan_order_count'] == 1),
        ('美团2单', df['meituan_order_count'] == 2),
        ('美团3-5单', (df['meituan_order_count'] >= 3) & (df['meituan_order_count'] <= 5)),
        ('美团6-10单', (df['meituan_order_count'] >= 6) & (df['meituan_order_count'] <= 10)),
        ('美团10+单', df['meituan_order_count'] > 10),
    ]

    for tier_name, condition in volume_tiers:
        tier_df = df[condition]
        if len(tier_df) > 0:
            # 计算该层级的各项指标
            stats = {
                'tier': tier_name,
                'user_count': len(tier_df),
                'user_percentage': round(len(tier_df) * 100.0 / len(df), 2),
                'avg_meituan_orders': tier_df['meituan_order_count'].mean().round(2),
                'avg_silk_meituan_orders': tier_df['silk_meituan_orders'].mean().round(2),
                'avg_same_user_orders': tier_df['same_user_meituan_orders'].mean().round(2),
                'avg_different_user_orders': tier_df['different_user_meituan_orders'].mean().round(2),
                'avg_order_gap': tier_df['订单差异'].mean().round(2),
                'violation_rate': round((tier_df['silk_meituan_orders'] > tier_df['meituan_order_count']).sum() * 100.0 / len(tier_df), 2),
                'positive_gap_rate': round((tier_df['订单差异'] > 0).sum() * 100.0 / len(tier_df), 2),
            }
            order_volume_stats.append(stats)

            print(f"\n{tier_name}:")
            print(f"  用户数: {stats['user_count']:,} ({stats['user_percentage']}%)")
            print(f"  平均订单差异: {stats['avg_order_gap']}单")
            print(f"  正差异比例: {stats['positive_gap_rate']}%")
            print(f"  违反业务逻辑比例: {stats['violation_rate']}%")

    return order_volume_stats

def generate_comprehensive_report(overall_metrics, match_type_stats, segment_stats, order_volume_stats, output_report_path):
    """生成综合分析报告"""
    print(f"\n正在生成综合分析报告: {output_report_path}")

    # 获取当前日期
    current_date = datetime.now().strftime('%Y-%m-%d')

    # 从DataFrame中提取用户分层数据
    df = overall_metrics['df']

    # 异常数据分析
    anomalies = analyze_anomalies(df)

    # 准备用户分层详细数据
    segment_details = {}
    for segment in ['高潜力用户', '中潜力用户', '低潜力用户', '无差异用户', '负差异用户']:
        segment_df = df[df['用户分层'] == segment]
        if len(segment_df) > 0:
            segment_details[segment] = {
                'count': len(segment_df),
                'percentage': round(len(segment_df) * 100.0 / len(df), 2)
            }

    report = f"""# 小蚕用户美团频次差异分析报告V3

**分析周期**：2026-03-09至2026-03-15
**报告日期**：{current_date}
**分析用户数**：{overall_metrics['total_users']:,}（完整样本，未剔除异常数据）
**数据源**：`dwd.dwd_silkworm_fp_client_feature`与`dwd.dwd_sr_order_promotion_order`关联数据
**新增指标**：同用户美团下单量、非同用户美团下单量
**分析说明**：本次分析保留所有数据，包括违反业务逻辑的记录，以全面了解数据质量

---

## 一、核心结论

1. **样本规模**：共分析{overall_metrics['total_users']:,}用户数据，包含所有记录（含异常数据）。

2. **订单匹配情况**：
   - 整体匹配率：{overall_metrics['overall_match_rate']}%（匹配订单/美团订单）
   - 小蚕匹配率：{overall_metrics['silk_match_rate']}%（匹配订单/小蚕美团订单）
   - 同用户匹配占比：{overall_metrics['same_user_match_rate']}%

3. **数据质量问题**：
   - {overall_metrics['violation_count']:,}用户（{overall_metrics['violation_percentage']}%）违反业务逻辑（小蚕美团订单数 > 采集美团订单数）
   - 这表明数据采集或匹配环节存在显著问题

4. **用户潜力分析**：
   - {overall_metrics['positive_gap']:,}用户（{overall_metrics['positive_gap_rate']}%）美团频次高于小蚕频次
   - {segment_details.get('高潜力用户', {}).get('count', 0):,}高潜力用户（{segment_details.get('高潜力用户', {}).get('percentage', 0)}%）可作为优先运营对象

5. **匹配类型洞察（基于用户业务逻辑）**：
   - 用户自己下单：{[stat['user_count'] for stat in match_type_stats if stat['match_type'] == '用户自己下单'][0]:,}用户（平均美团下单空间：{[stat['avg_remaining_space'] for stat in match_type_stats if stat['match_type'] == '用户自己下单'][0]}单）
   - 订单完全由其他有关系用户下单：{[stat['user_count'] for stat in match_type_stats if stat['match_type'] == '订单完全由其他有关系用户下单'][0]:,}用户（平均美团下单空间：{[stat['avg_remaining_space'] for stat in match_type_stats if stat['match_type'] == '订单完全由其他有关系用户下单'][0]}单）
   - 订单部分由其他用户下单：{[stat['user_count'] for stat in match_type_stats if stat['match_type'] == '订单部分由其他用户下单'][0]:,}用户（平均美团下单空间：{[stat['avg_remaining_space'] for stat in match_type_stats if stat['match_type'] == '订单部分由其他用户下单'][0]}单）
   - 用户美团数据可能异常：{[stat['user_count'] for stat in match_type_stats if stat['match_type'] == '用户美团数据可能异常'][0]:,}用户（需检查数据采集问题）

---

## 二、数据质量评估

### 1. 业务逻辑违反情况
| 指标 | 数值 | 说明 |
|------|------|------|
| 违反业务逻辑用户数 | {overall_metrics['violation_count']:,} | `silk_meituan_orders > meituan_order_count` |
| 违反比例 | {overall_metrics['violation_percentage']}% | 占总体用户的比例 |
| 影响程度 | 高 | 数据质量存在严重问题 |
| **数据采集限制** | **仅第一页** | **美团数据仅采集第一页，可能导致数据不完整** |

### 2. 订单匹配质量
| 指标 | 数值 | 说明 |
|------|------|------|
| 美团总订单数 | {overall_metrics['total_meituan_orders']:,} | 采集的美团订单总数（仅第一页数据） |
| 小蚕美团总订单数 | {overall_metrics['total_silk_meituan_orders']:,} | 小蚕中的美团订单总数 |
| 匹配总订单数 | {overall_metrics['total_matched_orders']:,} | 同用户 + 非同用户匹配订单 |
| **整体匹配率** | **{overall_metrics['overall_match_rate']}%** | **匹配订单/美团订单** |
| **小蚕匹配率** | **{overall_metrics['silk_match_rate']}%** | **匹配订单/小蚕美团订单** |
| 同用户匹配占比 | {overall_metrics['same_user_match_rate']}% | 同用户匹配/总匹配订单 |

---

## 三、整体分析结果

### 1. 基础统计
| 指标 | 数值 | 说明 |
|------|------|------|
| 分析用户总数 | {overall_metrics['total_users']:,} | 完整用户规模 |
| 平均美团订单数 | {overall_metrics['avg_meituan_orders']}单 | 用户7天内在美团平均下单次数 |
| 平均小蚕美团订单数 | {overall_metrics['avg_silk_meituan_orders']}单 | 用户通过小蚕订美团平均次数 |
| 平均同用户订单数 | {overall_metrics['avg_same_user_orders']}单 | 同用户匹配平均订单数 |
| 平均非同用户订单数 | {overall_metrics['avg_different_user_orders']}单 | 非同用户匹配平均订单数 |

### 2. 订单差异分析
| 差异类型 | 用户数 | 占比 | 业务含义 |
|----------|--------|------|----------|
| **正差异（美团>小蚕）** | {overall_metrics['positive_gap']:,} | {overall_metrics['positive_gap_rate']}% | 美团频次高于小蚕，存在推广潜力 |
| **零差异（美团=小蚕）** | {overall_metrics['zero_gap']:,} | {overall_metrics['zero_gap_rate']}% | 两个平台使用平衡 |
| **负差异（美团<小蚕）** | {overall_metrics['negative_gap']:,} | {overall_metrics['negative_gap_rate']}% | 小蚕频次高于美团（数据异常或业务特殊情况） |

---

## 四、按匹配类型分析

### 1. 匹配类型分布（基于用户业务逻辑）
| 匹配类型（业务含义） | 用户数 | 占比 | 平均美团订单 | 平均小蚕美团订单 | 平均订单差异 | **平均美团下单空间** | 违反业务逻辑比例 |
|----------------------|--------|------|--------------|------------------|--------------|----------------------|------------------|
"""

    # 添加匹配类型表格行
    for stats in match_type_stats:
        report += f"""| **{stats['match_type']}** | {stats['user_count']:,} | {stats['user_percentage']}% | {stats['avg_meituan_orders']}单 | {stats['avg_silk_meituan_orders']}单 | {stats['avg_order_gap']}单 | **{stats['avg_remaining_space']}单** | {stats['violation_rate']}% |
"""

    report += f"""
### 2. 匹配类型业务解读（根据用户描述）
1. **用户自己下单**（同用户>0，非同用户=0）：用户本人在美团下单并通过小蚕匹配，数据质量最高，美团下单空间为{next((stat['avg_remaining_space'] for stat in match_type_stats if stat['match_type'] == '用户自己下单'), 0)}单

2. **订单完全由其他有关系用户下单**（同用户=0，非同用户>0）：订单完全由其他有关系用户（如同住人、家人）下单，用户本人可能未使用小蚕，美团下单空间为{next((stat['avg_remaining_space'] for stat in match_type_stats if stat['match_type'] == '订单完全由其他有关系用户下单'), 0)}单

3. **订单部分由其他用户下单**（同用户>0，非同用户>0）：部分订单由用户本人下单，部分由其他有关系用户下单，情况复杂，美团下单空间为{next((stat['avg_remaining_space'] for stat in match_type_stats if stat['match_type'] == '订单部分由其他用户下单'), 0)}单

4. **用户美团数据可能异常**（同用户=0，非同用户=0）：订单未能匹配，可能原因：1)用户美团数据采集异常；2)用户未在美团下单；3)数据匹配算法问题，需重点检查数据质量

---

## 五、按用户分层分析

### 1. 用户分层分布
| 用户分层 | 用户数 | 占比 | 平均美团订单 | 平均小蚕美团订单 | 平均订单差异 | 差异率 |
|----------|--------|------|--------------|------------------|--------------|--------|
"""

    # 添加用户分层表格行
    for stats in segment_stats:
        report += f"""| **{stats['segment']}** | {stats['user_count']:,} | {stats['user_percentage']}% | {stats['avg_meituan_orders']}单 | {stats['avg_silk_meituan_orders']}单 | {stats['avg_order_gap']}单 | {stats['avg_gap_percentage']}% |
"""

    report += f"""
### 2. 分层标准说明
| 用户分层 | 分层标准 | 运营优先级 |
|----------|----------|------------|
| **高潜力用户** | 差异≥3单 **且** 差异率≥50% | 最高 |
| **中潜力用户** | 差异≥2单 | 中等 |
| **低潜力用户** | 差异=1单 | 较低 |
| **无差异用户** | 差异=0单 | 维护即可 |
| **负差异用户** | 差异<0单 | 数据异常检查 |

---

## 六、按美团订单量分层分析

### 1. 订单量分层结果
| 消费层级 | 用户数 | 占比 | 平均美团订单 | 平均小蚕美团订单 | 平均订单差异 | 正差异比例 |
|----------|--------|------|--------------|------------------|--------------|------------|
"""

    # 添加订单量分层表格行
    for stats in order_volume_stats:
        report += f"""| **{stats['tier']}** | {stats['user_count']:,} | {stats['user_percentage']}% | {stats['avg_meituan_orders']}单 | {stats['avg_silk_meituan_orders']}单 | {stats['avg_order_gap']}单 | {stats['positive_gap_rate']}% |
"""

    report += f"""
### 2. 订单量分层业务解读
1. **美团1单**：低频用户，推广成本较高，转化难度大
2. **美团2单**：中低频用户，有一定消费习惯，可适度推广
3. **美团3-5单**：中频用户，消费活跃，推广价值较高
4. **美团6-10单**：高频用户，价值最高，应重点维护
5. **美团10+单**：超高频用户，需防止流失，提供专属服务

---

## 七、异常数据分析

### 1. 异常类型统计
| 异常类型 | 用户数 | 占比 | 可能原因 |
|----------|--------|------|----------|
| **违反业务逻辑（小蚕>美团）** | {anomalies['logic_violation']['count']:,} | {anomalies['logic_violation']['percentage']}% | 数据采集不完整、订单匹配错误、时间窗口不一致 |
| **无匹配异常（同用户=0且非同用户=0）** | {anomalies['no_match']['count']:,} | {anomalies['no_match']['percentage']}% | 用户未在美团下单、订单匹配算法失败、用户ID映射问题 |
| **美团订单为0但小蚕美团订单>0** | {anomalies['meituan_zero_silk_positive']['count']:,} | {anomalies['meituan_zero_silk_positive']['percentage']}% | 美团数据采集完全失败、用户通过小蚕下单但未采集到美团数据 |
| **小蚕美团订单为0但美团订单>0** | {anomalies['silk_zero_meituan_positive']['count']:,} | {anomalies['silk_zero_meituan_positive']['percentage']}% | 用户未使用小蚕进行美团下单、小蚕数据记录缺失 |
| **同用户匹配>美团订单（逻辑不可能）** | {anomalies['impossible_match']['count']:,} | {anomalies['impossible_match']['percentage']}% | 数据逻辑错误、计算错误 |

### 2. 违反业务逻辑异常按匹配类型分布
| 匹配类型 | 异常用户数 | 异常比例 | 影响程度 |
|----------|------------|----------|----------|
| **用户自己下单** | {anomalies['logic_violation']['by_type'].get('用户自己下单', {}).get('count', 0):,} | {anomalies['logic_violation']['by_type'].get('用户自己下单', {}).get('rate', 0)}% | 高（数据质量核心问题） |
| **订单完全由其他有关系用户下单** | {anomalies['logic_violation']['by_type'].get('订单完全由其他有关系用户下单', {}).get('count', 0):,} | {anomalies['logic_violation']['by_type'].get('订单完全由其他有关系用户下单', {}).get('rate', 0)}% | 中 |
| **订单部分由其他用户下单** | {anomalies['logic_violation']['by_type'].get('订单部分由其他用户下单', {}).get('count', 0):,} | {anomalies['logic_violation']['by_type'].get('订单部分由其他用户下单', {}).get('rate', 0)}% | 中 |
| **用户美团数据可能异常** | {anomalies['logic_violation']['by_type'].get('用户美团数据可能异常', {}).get('count', 0):,} | {anomalies['logic_violation']['by_type'].get('用户美团数据可能异常', {}).get('rate', 0)}% | 低（本身已是异常数据） |

### 3. 异常影响评估
1. **数据可信度**：{anomalies['logic_violation']['percentage']}%用户数据违反业务逻辑，**数据可信度低**
2. **匹配质量**：仅{overall_metrics['overall_match_rate']}%订单匹配成功，**匹配算法需要优化**
3. **异常用户重叠**：异常用户总数约{anomalies['total_anomaly_users']:,}（可能有重叠），占总体{round(anomalies['total_anomaly_users'] * 100.0 / overall_metrics['total_users'], 2)}%
4. **最严重问题**：违反业务逻辑异常影响最大，需**优先解决**

### 4. 异常处理建议
1. **立即行动**：检查数据采集流程，确保美团订单采集完整
2. **算法优化**：改进订单匹配算法，提高匹配准确率
3. **数据清洗**：建立异常数据识别和清洗机制
4. **监控预警**：设置数据质量监控指标，实时预警异常
5. **根本原因分析**：针对无匹配异常进行深度调查

---

## 八、关键发现与建议

### 1. 数据质量问题
- **严重问题**：{overall_metrics['violation_percentage']}%用户数据违反基本业务逻辑
- **建议**：立即检查数据采集和匹配流程，修复数据质量问题

### 2. 订单匹配率低
- **整体匹配率仅{overall_metrics['overall_match_rate']}%**，大量订单未能匹配
- **建议**：优化订单匹配算法，提高匹配准确率

### 3. 运营机会
- **高潜力用户**：{segment_details.get('高潜力用户', {}).get('count', 0):,}用户可作为优先推广对象
- **建议**：针对不同分层用户制定差异化运营策略

### 4. 匹配类型洞察
- **非同用户匹配占比高**：表明用户ID映射存在问题
- **建议**：统一用户标识体系，减少ID映射错误

---

## 九、局限性说明

1. **数据质量问题**：大量数据违反业务逻辑，结论需谨慎对待
2. **匹配率低**：仅{overall_metrics['overall_match_rate']}%订单匹配成功，分析存在偏差
3. **时间窗口**：仅分析7天数据，未能反映长期趋势
4. **建议**：优先解决数据质量问题，再进行深入分析

---

**报告生成时间**：{current_date}
**数据版本**：V3（含同用户/非同用户匹配指标）
**分析范围**：完整数据（未剔除异常记录）
"""

    # 保存报告
    with open(output_report_path, 'w', encoding='utf-8') as f:
        f.write(report)

    print(f"综合分析报告已保存至: {output_report_path}")
    return report

def analyze_anomalies(df):
    """异常数据分析"""
    print(f"\n=== 异常数据分析 ===")

    total_users = len(df)

    # 1. 违反业务逻辑的异常（小蚕美团订单 > 采集美团订单）
    logic_violation = (df['silk_meituan_orders'] > df['meituan_order_count'])
    logic_violation_count = logic_violation.sum()
    logic_violation_percentage = round(logic_violation_count * 100.0 / total_users, 2)

    # 分析违反业务逻辑的记录在不同匹配类型中的分布
    logic_violation_by_type = {}
    for match_type in ['用户自己下单', '订单完全由其他有关系用户下单', '订单部分由其他用户下单', '用户美团数据可能异常']:
        type_df = df[df['匹配类型'] == match_type]
        if len(type_df) > 0:
            violation_count = (type_df['silk_meituan_orders'] > type_df['meituan_order_count']).sum()
            violation_rate = round(violation_count * 100.0 / len(type_df), 2)
            logic_violation_by_type[match_type] = {
                'count': violation_count,
                'rate': violation_rate
            }

    # 2. 无匹配异常（同用户=0，非同用户=0）
    no_match = (df['same_user_meituan_orders'] == 0) & (df['different_user_meituan_orders'] == 0)
    no_match_count = no_match.sum()
    no_match_percentage = round(no_match_count * 100.0 / total_users, 2)

    # 3. 美团订单为0但小蚕美团订单>0的异常
    meituan_zero_silk_positive = (df['meituan_order_count'] == 0) & (df['silk_meituan_orders'] > 0)
    meituan_zero_silk_positive_count = meituan_zero_silk_positive.sum()
    meituan_zero_silk_positive_percentage = round(meituan_zero_silk_positive_count * 100.0 / total_users, 2)

    # 4. 小蚕美团订单为0但美团订单>0的异常
    silk_zero_meituan_positive = (df['silk_meituan_orders'] == 0) & (df['meituan_order_count'] > 0)
    silk_zero_meituan_positive_count = silk_zero_meituan_positive.sum()
    silk_zero_meituan_positive_percentage = round(silk_zero_meituan_positive_count * 100.0 / total_users, 2)

    # 5. 同用户匹配但非同用户匹配>美团订单的异常（逻辑上不可能）
    impossible_match = (df['same_user_meituan_orders'] > df['meituan_order_count'])
    impossible_match_count = impossible_match.sum()
    impossible_match_percentage = round(impossible_match_count * 100.0 / total_users, 2)

    print(f"1. 违反业务逻辑异常（小蚕>美团）: {logic_violation_count:,}用户 ({logic_violation_percentage}%)")
    print(f"2. 无匹配异常（同用户=0且非同用户=0）: {no_match_count:,}用户 ({no_match_percentage}%)")
    print(f"3. 美团订单为0但小蚕美团订单>0: {meituan_zero_silk_positive_count:,}用户 ({meituan_zero_silk_positive_percentage}%)")
    print(f"4. 小蚕美团订单为0但美团订单>0: {silk_zero_meituan_positive_count:,}用户 ({silk_zero_meituan_positive_percentage}%)")
    print(f"5. 同用户匹配>美团订单（逻辑不可能）: {impossible_match_count:,}用户 ({impossible_match_percentage}%)")

    # 异常原因分析
    print(f"\n=== 异常原因分析 ===")
    print(f"1. 违反业务逻辑的主要原因:")
    print(f"   - 数据采集问题：美团订单采集不完整（仅采集第一页）")
    print(f"   - 数据匹配问题：订单ID匹配算法错误")
    print(f"   - 时间窗口不一致：两个数据源的时间范围不一致")

    print(f"\n2. 无匹配异常的主要原因:")
    print(f"   - 用户未在美团下单：采集数据但实际未下单")
    print(f"   - 订单匹配算法失败：未能正确匹配订单")
    print(f"   - 用户ID映射问题：两个系统的用户ID不一致")

    print(f"\n3. 美团订单为0但小蚕美团订单>0:")
    print(f"   - 美团数据采集完全失败")
    print(f"   - 用户通过小蚕下单但未采集到美团数据")

    print(f"\n4. 小蚕美团订单为0但美团订单>0:")
    print(f"   - 用户未使用小蚕进行美团下单")
    print(f"   - 小蚕数据记录缺失")

    anomalies = {
        'logic_violation': {
            'count': logic_violation_count,
            'percentage': logic_violation_percentage,
            'by_type': logic_violation_by_type
        },
        'no_match': {
            'count': no_match_count,
            'percentage': no_match_percentage
        },
        'meituan_zero_silk_positive': {
            'count': meituan_zero_silk_positive_count,
            'percentage': meituan_zero_silk_positive_percentage
        },
        'silk_zero_meituan_positive': {
            'count': silk_zero_meituan_positive_count,
            'percentage': silk_zero_meituan_positive_percentage
        },
        'impossible_match': {
            'count': impossible_match_count,
            'percentage': impossible_match_percentage
        },
        'total_anomaly_users': logic_violation_count + no_match_count + meituan_zero_silk_positive_count + silk_zero_meituan_positive_count + impossible_match_count
    }

    # 注意：用户可能同时属于多种异常类别，所以total_anomaly_users可能有重叠
    anomaly_user_percentage = round(anomalies['total_anomaly_users'] * 100.0 / total_users, 2)
    print(f"\n异常用户总数（可能有重叠）: {anomalies['total_anomaly_users']:,} ({anomaly_user_percentage}%)")

    return anomalies

def save_processed_data(df, output_excel_path):
    """保存处理后的数据"""
    print(f"\n正在保存处理后的数据: {output_excel_path}")

    # 确保必要的列存在
    required_new_columns = ['订单差异', '差异率', '用户分层', '匹配类型']
    for col in required_new_columns:
        if col not in df.columns:
            print(f"警告: 缺少列 {col}")

    # 保存到Excel
    df.to_excel(output_excel_path, index=False)
    print(f"处理后的数据已保存至: {output_excel_path}")
    print(f"新增列: {required_new_columns}")

def main():
    """主函数"""
    input_excel_path = "data_storage/20260414_美团下单统计V3.xlsx"
    output_excel_path = "data_storage/20260414_美团下单统计V3_分析后.xlsx"
    output_report_path = "analysis_reports/小蚕用户美团频次差异分析V3_综合报告.md"

    if not os.path.exists(input_excel_path):
        print(f"错误: Excel文件不存在: {input_excel_path}")
        return

    print("=" * 70)
    print("小蚕用户美团频次差异分析V3 - 包含同用户/非同用户指标")
    print("=" * 70)

    try:
        # 1. 加载数据并进行列名映射
        df = load_and_prepare_data(input_excel_path)

        # 2. 整体分析
        overall_metrics = analyze_overall_metrics(df)

        # 3. 按匹配类型分析
        match_type_stats, df = analyze_by_match_type(df)

        # 4. 按用户分层分析
        segment_stats = analyze_by_user_segment(df)

        # 5. 按美团订单量分层分析
        order_volume_stats = analyze_by_order_volume(df)

        # 6. 生成综合分析报告
        generate_comprehensive_report(overall_metrics, match_type_stats, segment_stats, order_volume_stats, output_report_path)

        # 7. 保存处理后的数据
        save_processed_data(df, output_excel_path)

        print("\n" + "=" * 70)
        print("V3分析完成！")
        print(f"1. 原始数据文件: {input_excel_path}")
        print(f"2. 处理后数据文件: {output_excel_path}")
        print(f"3. 综合分析报告: {output_report_path}")
        print(f"4. 分析用户数: {overall_metrics['total_users']:,}")
        print(f"5. 整体匹配率: {overall_metrics['overall_match_rate']}%")
        print("=" * 70)

    except Exception as e:
        print(f"分析过程中出错: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()