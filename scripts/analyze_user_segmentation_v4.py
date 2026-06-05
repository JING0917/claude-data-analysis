#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
分析小蚕用户美团下单频次数据（V4版本），按订单差异分类和匹配类型进行细分分析
包含关联美团订单量指标调整
"""

import pandas as pd
import numpy as np
from pathlib import Path

def analyze_user_segmentation_v4():
    """分析用户细分数据（V4版本，包含关联美团订单量调整）"""

    # 读取数据
    data_path = Path("data_storage/20260414_美团下单统计V4.xlsx")
    print(f"读取数据文件: {data_path}")

    df = pd.read_excel(data_path)
    print(f"数据形状: {df.shape}")
    print(f"列名: {df.columns.tolist()}")

    # 重命名列以便使用
    df = df.rename(columns={
        '采集美团下单量': '采集美团订单量',
        '小蚕美团下单量': '小蚕美团订单量',
        '采集同小蚕用户美团下单量': '同用户匹配',
        '采集非同小蚕用户美团下单量': '非同用户匹配',
        '关联美团下单量': '关联美团订单量'
    })

    # 计算调整后的订单差异：剔除已关联的美团订单
    # 美团订单差异 = (采集美团订单量 - 关联美团订单量) - 小蚕美团订单量
    df['美团订单差异'] = (df['采集美团订单量'] - df['关联美团订单量']) - df['小蚕美团订单量']

    # 定义订单差异分类
    def get_order_diff_category(row):
        if row['小蚕美团订单量'] == 0:
            return '未下单用户'
        elif row['美团订单差异'] > 0:
            return '正差异用户'
        elif row['美团订单差异'] == 0:
            return '无差异用户'
        else:  # row['美团订单差异'] < 0
            return '负差异用户'

    df['订单差异分类'] = df.apply(get_order_diff_category, axis=1)

    # 定义匹配类型
    def get_match_type(row):
        if row['同用户匹配'] > 0 and row['非同用户匹配'] == 0:
            return '用户自己下单'
        elif row['同用户匹配'] == 0 and row['非同用户匹配'] > 0:
            return '订单完全由其他有关系用户下单'
        elif row['同用户匹配'] > 0 and row['非同用户匹配'] > 0:
            return '订单部分由其他用户下单'
        elif row['同用户匹配'] == 0 and row['非同用户匹配'] == 0:
            return '用户美团数据可能异常'
        else:
            return '未知'

    df['匹配类型'] = df.apply(get_match_type, axis=1)

    # 总体统计
    total_users = len(df)
    print(f"\n=== 总体统计 ===")
    print(f"总用户数: {total_users:,}")

    # 订单差异分类统计
    print(f"\n=== 订单差异分类统计（调整后） ===")
    order_diff_stats = df.groupby('订单差异分类').agg({
        '用户ID': 'count',
        '采集美团订单量': 'mean',
        '关联美团订单量': 'mean',
        '小蚕美团订单量': 'mean',
        '美团订单差异': 'mean'
    }).round(2)

    order_diff_stats = order_diff_stats.rename(columns={'用户ID': '用户数'})
    order_diff_stats['占比'] = (order_diff_stats['用户数'] / total_users * 100).round(2)

    print(order_diff_stats)

    # 匹配类型整体统计
    print(f"\n=== 匹配类型整体统计 ===")
    match_type_stats = df.groupby('匹配类型').agg({
        '用户ID': 'count',
        '采集美团订单量': 'mean',
        '关联美团订单量': 'mean',
        '美团订单差异': 'mean'
    }).round(2)

    match_type_stats = match_type_stats.rename(columns={'用户ID': '用户数'})
    match_type_stats['占比'] = (match_type_stats['用户数'] / total_users * 100).round(2)

    print(match_type_stats)

    # 各订单差异分类下的匹配类型分布
    print(f"\n=== 各订单差异分类下的匹配类型分布 ===")

    # 获取所有订单差异分类
    order_categories = ['未下单用户', '正差异用户', '无差异用户', '负差异用户']
    match_types = ['用户自己下单', '用户美团数据可能异常', '订单部分由其他用户下单', '订单完全由其他有关系用户下单']

    results = {}

    for category in order_categories:
        category_df = df[df['订单差异分类'] == category]
        category_total = len(category_df)

        print(f"\n--- {category} ({category_total:,}人) ---")

        category_stats = []
        for match_type in match_types:
            match_df = category_df[category_df['匹配类型'] == match_type]
            match_count = len(match_df)

            if match_count > 0:
                avg_collected = match_df['采集美团订单量'].mean()
                avg_associated = match_df['关联美团订单量'].mean()
                avg_difference = match_df['美团订单差异'].mean() if '美团订单差异' in match_df.columns else 0
                avg_xiaocan = match_df['小蚕美团订单量'].mean() if '小蚕美团订单量' in match_df.columns else 0

                stats = {
                    '匹配类型': match_type,
                    '用户数': match_count,
                    '占分类比例': round(match_count / category_total * 100, 2),
                    '平均采集美团订单量': round(avg_collected, 2),
                    '平均关联美团订单量': round(avg_associated, 2),
                    '平均订单量差异': round(avg_difference, 2),
                    '平均小蚕美团订单量': round(avg_xiaocan, 2)
                }
                category_stats.append(stats)

                print(f"  {match_type}: {match_count:,}人 ({stats['占分类比例']}%)")

        results[category] = category_stats

    # 输出详细的表格数据（用于钉钉文档）
    print(f"\n=== 详细表格数据（用于钉钉文档，包含关联美团订单量） ===")

    for category in order_categories:
        print(f"\n### {category}匹配类型分布")
        print("| 匹配类型 | 用户数 | 占分类比例 | 平均采集美团订单量 | 平均关联美团订单量 | 平均订单量差异 | 平均小蚕美团订单量 |")
        print("|----------|--------|------------|------------------|------------------|----------------|----------------------|")

        if category in results:
            for stats in results[category]:
                print(f"| {stats['匹配类型']} | {stats['用户数']:,} | {stats['占分类比例']}% | {stats['平均采集美团订单量']}单 | {stats['平均关联美团订单量']}单 | {stats['平均订单量差异']}单 | {stats['平均小蚕美团订单量']}单 |")
        else:
            print("| 数据待分析 | - | - | - | - | - | - |")

    # 保存结果到文件
    output_path = Path("analysis_reports/用户细分分析结果_v4.md")
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write("# 用户细分分析结果（V4版本，包含关联美团订单量调整）\n\n")

        f.write("## 各订单差异分类的匹配类型分布\n\n")

        for category in order_categories:
            f.write(f"### {category}\n")
            f.write("| 匹配类型 | 用户数 | 占分类比例 | 平均采集美团订单量 | 平均关联美团订单量 | 平均订单量差异 | 平均小蚕美团订单量 |\n")
            f.write("|----------|--------|------------|------------------|------------------|----------------|----------------------|\n")

            if category in results:
                for stats in results[category]:
                    f.write(f"| {stats['匹配类型']} | {stats['用户数']:,} | {stats['占分类比例']}% | {stats['平均采集美团订单量']}单 | {stats['平均关联美团订单量']}单 | {stats['平均订单量差异']}单 | {stats['平均小蚕美团订单量']}单 |\n")
            else:
                f.write("| 数据待分析 | - | - | - | - | - | - |\n")

            f.write("\n")

    print(f"\n分析结果已保存到: {output_path}")

    # 计算高潜力、中潜力、低潜力用户（基于调整后的差异）
    # 先筛选逻辑一致用户：小蚕美团订单量 ≤ (采集美团订单量 - 关联美团订单量) 的用户
    # 即调整后的差异 >= 0
    logic_consistent_df = df[df['美团订单差异'] >= 0]
    print(f"\n=== 逻辑一致用户统计（调整后） ===")
    print(f"逻辑一致用户数: {len(logic_consistent_df):,} ({len(logic_consistent_df)/total_users*100:.2f}%)")

    # 计算差异率：差异占(采集美团订单量 - 关联美团订单量)的比例
    logic_consistent_df['调整采集量'] = logic_consistent_df['采集美团订单量'] - logic_consistent_df['关联美团订单量']
    logic_consistent_df['差异率'] = logic_consistent_df['美团订单差异'] / logic_consistent_df['调整采集量'].replace(0, np.nan)

    # 定义用户分层标准（在逻辑一致用户基础上，分别对每个匹配类型应用）
    def get_user_tier(row):
        if row['美团订单差异'] >= 3 and row['差异率'] >= 0.5:
            return '高潜力用户'
        elif row['美团订单差异'] >= 2:
            return '中潜力用户'
        elif row['美团订单差异'] == 1:
            return '低潜力用户'
        elif row['美团订单差异'] == 0:
            return '无差异用户'
        else:
            return '负差异用户'

    logic_consistent_df['用户分层'] = logic_consistent_df.apply(get_user_tier, axis=1)

    # 统计各用户分层的匹配类型分布
    user_tiers = ['高潜力用户', '中潜力用户', '低潜力用户', '无差异用户']

    tier_results = {}
    for tier in user_tiers:
        tier_df = logic_consistent_df[logic_consistent_df['用户分层'] == tier]
        tier_total = len(tier_df)

        if tier_total > 0:
            print(f"\n--- {tier} ({tier_total:,}人) ---")

            tier_stats = []
            for match_type in match_types:
                match_df = tier_df[tier_df['匹配类型'] == match_type]
                match_count = len(match_df)

                if match_count > 0:
                    avg_collected = match_df['采集美团订单量'].mean()
                    avg_associated = match_df['关联美团订单量'].mean()
                    avg_difference = match_df['美团订单差异'].mean()
                    avg_xiaocan = match_df['小蚕美团订单量'].mean()

                    stats = {
                        '匹配类型': match_type,
                        '用户数': match_count,
                        '占分层比例': round(match_count / tier_total * 100, 2),
                        '平均采集美团订单量': round(avg_collected, 2),
                        '平均关联美团订单量': round(avg_associated, 2),
                        '平均订单量差异': round(avg_difference, 2),
                        '平均小蚕美团订单量': round(avg_xiaocan, 2)
                    }
                    tier_stats.append(stats)

                    print(f"  {match_type}: {match_count:,}人 ({stats['占分层比例']}%)")

            tier_results[tier] = tier_stats

    # 输出用户分层表格
    print(f"\n=== 用户分层匹配类型分布（用于钉钉文档） ===")

    for tier in user_tiers:
        if tier in tier_results and tier_results[tier]:
            print(f"\n### {tier}")
            print("| 匹配类型 | 用户数 | 占分层比例 | 平均采集美团订单量 | 平均关联美团订单量 | 平均订单量差异 | 平均小蚕美团订单量 |")
            print("|----------|--------|------------|------------------|------------------|----------------|----------------------|")

            for stats in tier_results[tier]:
                print(f"| {stats['匹配类型']} | {stats['用户数']:,} | {stats['占分层比例']}% | {stats['平均采集美团订单量']}单 | {stats['平均关联美团订单量']}单 | {stats['平均订单量差异']}单 | {stats['平均小蚕美团订单量']}单 |")

    # 保存用户分层结果
    tier_output_path = Path("analysis_reports/用户分层分析结果_v4.md")
    with open(tier_output_path, 'w', encoding='utf-8') as f:
        f.write("# 用户分层分析结果（V4版本，包含关联美团订单量调整）\n\n")

        for tier in user_tiers:
            if tier in tier_results and tier_results[tier]:
                f.write(f"## {tier}\n")
                f.write("| 匹配类型 | 用户数 | 占分层比例 | 平均采集美团订单量 | 平均关联美团订单量 | 平均订单量差异 | 平均小蚕美团订单量 |\n")
                f.write("|----------|--------|------------|------------------|------------------|----------------|----------------------|\n")

                for stats in tier_results[tier]:
                    f.write(f"| {stats['匹配类型']} | {stats['用户数']:,} | {stats['占分层比例']}% | {stats['平均采集美团订单量']}单 | {stats['平均关联美团订单量']}单 | {stats['平均订单量差异']}单 | {stats['平均小蚕美团订单量']}单 |\n")

                f.write("\n")

    print(f"\n用户分层分析结果已保存到: {tier_output_path}")

    return df, results, tier_results

if __name__ == "__main__":
    df, results, tier_results = analyze_user_segmentation_v4()