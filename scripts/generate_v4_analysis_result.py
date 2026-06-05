#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
基于V4数据生成完整分析结果Excel文件
包含关联美团订单量调整和新的订单差异计算
"""

import pandas as pd
import numpy as np
from pathlib import Path

def generate_v4_analysis_result():
    """生成V4版本的分析结果Excel文件"""

    # 读取V4数据
    data_path = Path("data_storage/20260414_美团下单统计V4.xlsx")
    print(f"读取V4数据文件: {data_path}")

    df = pd.read_excel(data_path)
    print(f"数据形状: {df.shape}")
    print(f"总用户数: {len(df):,}")

    # 重命名列以便使用（保持与V3分析结果一致的命名）
    df = df.rename(columns={
        '采集美团下单量': '采集美团订单量',
        '小蚕下单量': '小蚕订单量',
        '小蚕美团下单量': '小蚕美团订单量',
        '小蚕饿了么下单量': '小蚕饿了么订单量',
        '小蚕京东下单量': '小蚕京东订单量',
        '采集同小蚕用户美团下单量': '同用户匹配美团订单量',
        '采集非同小蚕用户美团下单量': '非同用户匹配美团订单量',
        '关联美团下单量': '关联美团订单量'
    })

    # 计算两种美团订单差异：
    # 1. 订单差异_分布：采集美团订单量 - 小蚕美团订单量（用于整体分类）
    # 2. 订单差异_详细：采集美团订单量 - 关联美团订单量（用于详细表格，保持原名'订单差异'）
    df['订单差异_分布'] = df['采集美团订单量'] - df['小蚕美团订单量']
    df['订单差异'] = df['采集美团订单量'] - df['关联美团订单量']

    # 计算差异率：差异占采集美团订单量的比例（基于订单差异_详细）
    df['差异率'] = df['订单差异'] / df['采集美团订单量'].replace(0, np.nan)

    # 定义匹配类型
    def get_match_type(row):
        if row['同用户匹配美团订单量'] > 0 and row['非同用户匹配美团订单量'] == 0:
            return '用户自己下单'
        elif row['同用户匹配美团订单量'] == 0 and row['非同用户匹配美团订单量'] > 0:
            return '订单完全由其他有关系用户下单'
        elif row['同用户匹配美团订单量'] > 0 and row['非同用户匹配美团订单量'] > 0:
            return '订单部分由其他用户下单'
        elif row['同用户匹配美团订单量'] == 0 and row['非同用户匹配美团订单量'] == 0:
            return '用户美团数据可能异常'
        else:
            return '未知'

    df['匹配类型'] = df.apply(get_match_type, axis=1)

    # 定义匹配类型简写
    def get_match_type_short(row):
        if row['匹配类型'] == '用户自己下单':
            return '用户自己下单'
        elif row['匹配类型'] == '用户美团数据可能异常':
            return '数据异常'
        elif row['匹配类型'] == '订单部分由其他用户下单':
            return '混合下单'
        elif row['匹配类型'] == '订单完全由其他有关系用户下单':
            return '其他用户下单'
        else:
            return '未知'

    df['匹配类型简写'] = df.apply(get_match_type_short, axis=1)

    # 定义用户分层（基于美团订单差异）
    def get_user_tier(row):
        # 首先检查是否为逻辑一致用户（订单差异 >= 0）
        if row['订单差异'] >= 0:
            # 计算差异率：订单差异占采集美团订单量的比例
            collected = row['采集美团订单量']
            if collected > 0:
                diff_rate = row['订单差异'] / collected
            else:
                diff_rate = 0

            # 应用分层标准
            if row['订单差异'] >= 3 and diff_rate >= 0.5:
                return '高潜力用户'
            elif row['订单差异'] >= 2:
                return '中潜力用户'
            elif row['订单差异'] == 1:
                return '低潜力用户'
            elif row['订单差异'] == 0:
                return '无差异用户'
            else:
                return '负差异用户'  # 理论上不会进入这里，因为订单差异>=0
        else:
            # 订单差异 < 0，为负差异用户
            return '负差异用户'

    df['用户分层'] = df.apply(get_user_tier, axis=1)

    # 定义细分分层：匹配类型 + "_" + 用户分层
    df['细分分层'] = df['匹配类型'] + '_' + df['用户分层']

    # 重新排列列顺序，与V3分析结果保持一致，但添加关联美团订单量列
    # V3分析结果列顺序: ['用户ID', '采集美团订单量', '小蚕订单量', '小蚕美团订单量', '小蚕饿了么订单量', '小蚕京东订单量',
    #                   '同用户匹配美团订单量', '非同用户匹配美团订单量', '订单差异', '差异率', '用户分层',
    #                   '匹配类型', '匹配类型简写', '细分分层']

    # V4新增列: '关联美团订单量'，放在'小蚕京东订单量'之后
    output_columns = [
        '用户ID',
        '采集美团订单量',
        '小蚕订单量',
        '小蚕美团订单量',
        '小蚕饿了么订单量',
        '小蚕京东订单量',
        '关联美团订单量',  # 新增列
        '同用户匹配美团订单量',
        '非同用户匹配美团订单量',
        '订单差异',        # 采集-关联（用于详细表格）
        '订单差异_分布',   # 采集-小蚕（用于整体分类）
        '差异率',
        '用户分层',
        '匹配类型',
        '匹配类型简写',
        '细分分层'
    ]

    # 确保所有列都存在
    for col in output_columns:
        if col not in df.columns:
            print(f"警告: 列'{col}'不存在于DataFrame中")

    result_df = df[output_columns].copy()

    # 保存到Excel文件
    output_path = Path("data_storage/20260414_美团下单统计V4_分析结果.xlsx")
    print(f"\n正在保存分析结果到: {output_path}")

    result_df.to_excel(output_path, index=False)
    print(f"文件已保存，形状: {result_df.shape}")

    # 输出一些统计信息
    print(f"\n=== V4分析结果统计 ===")
    print(f"总用户数: {len(result_df):,}")

    # 订单差异分类统计
    print(f"\n订单差异分类统计:")
    diff_stats = result_df['用户分层'].value_counts()
    for tier, count in diff_stats.items():
        percentage = count / len(result_df) * 100
        print(f"  {tier}: {count:,}人 ({percentage:.2f}%)")

    # 匹配类型统计
    print(f"\n匹配类型统计:")
    match_stats = result_df['匹配类型'].value_counts()
    for match_type, count in match_stats.items():
        percentage = count / len(result_df) * 100
        print(f"  {match_type}: {count:,}人 ({percentage:.2f}%)")

    # 订单差异均值
    print(f"\n订单差异统计:")
    print(f"  平均订单差异: {result_df['订单差异'].mean():.2f}单")
    print(f"  平均采集美团订单量: {result_df['采集美团订单量'].mean():.2f}单")
    print(f"  平均关联美团订单量: {result_df['关联美团订单量'].mean():.2f}单")
    print(f"  平均小蚕美团订单量: {result_df['小蚕美团订单量'].mean():.2f}单")

    # 检查与钉钉文档数据的一致性
    print(f"\n=== 与钉钉文档数据一致性检查 ===")

    # 负差异用户
    negative_diff = result_df[result_df['用户分层'] == '负差异用户']
    print(f"负差异用户数: {len(negative_diff):,}人")

    # 正差异用户（订单差异 > 0 且不是负差异用户）
    positive_diff = result_df[result_df['订单差异'] > 0]
    print(f"正差异用户数（订单差异>0）: {len(positive_diff):,}人")

    # 未下单用户（小蚕美团订单量 = 0）
    no_order = result_df[result_df['小蚕美团订单量'] == 0]
    print(f"未下单用户数（小蚕美团=0）: {len(no_order):,}人")

    # 高潜力用户
    high_potential = result_df[result_df['用户分层'] == '高潜力用户']
    print(f"高潜力用户数: {len(high_potential):,}人")

    # 高潜力用户中"用户自己下单"类型
    high_self_order = high_potential[high_potential['匹配类型'] == '用户自己下单']
    print(f"高潜力用户中'用户自己下单'类型: {len(high_self_order):,}人")

    return result_df, output_path

if __name__ == "__main__":
    result_df, output_path = generate_v4_analysis_result()
    print(f"\n分析完成，结果已保存到: {output_path}")