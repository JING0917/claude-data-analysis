#!/usr/bin/env python3
"""
检查feed转换数据Excel文件
"""

import pandas as pd
import numpy as np
import sys
import os

# 文件路径
data_path = "./feed_conversion_analysis/data/20260421_feed_conversion_data.xlsx"

print("=" * 60)
print("检查数据文件:", data_path)
print("=" * 60)

# 检查文件是否存在
if not os.path.exists(data_path):
    print(f"错误: 文件不存在 {data_path}")
    sys.exit(1)

# 读取Excel文件的所有sheet名称
try:
    excel_file = pd.ExcelFile(data_path)
    sheet_names = excel_file.sheet_names
    print(f"Sheet名称: {sheet_names}")

    # 读取第一个sheet
    df = pd.read_excel(data_path, sheet_name=sheet_names[0])

    print(f"\n数据形状: {df.shape}")
    print(f"行数: {df.shape[0]}, 列数: {df.shape[1]}")

    print("\n列名:")
    for i, col in enumerate(df.columns):
        print(f"  {i+1:2d}. {col}")

    print("\n前5行数据:")
    print(df.head())

    print("\n数据类型:")
    print(df.dtypes)

    print("\n缺失值统计:")
    missing = df.isnull().sum()
    missing_pct = df.isnull().sum() * 100 / len(df)
    missing_df = pd.DataFrame({
        '缺失数量': missing,
        '缺失比例%': missing_pct.round(2)
    })
    print(missing_df[missing_df['缺失数量'] > 0])

    print("\n基础统计信息:")
    print(df.describe())

    # 检查关键列是否存在
    required_cols = ['statistics_date', 'county_id', 'platform_name', 'app_version',
                     'activity_type', 'clc_num', 'detailpage_pv']

    missing_req = [col for col in required_cols if col not in df.columns]
    if missing_req:
        print(f"\n警告: 缺少必需列: {missing_req}")
    else:
        print("\n所有必需列都存在")

    # 检查活动类型分布
    if 'activity_type' in df.columns:
        print("\n活动类型分布:")
        print(df['activity_type'].value_counts())

    # 检查平台分布
    if 'platform_name' in df.columns:
        print("\n平台分布:")
        print(df['platform_name'].value_counts())

except Exception as e:
    print(f"读取文件时出错: {e}")
    import traceback
    traceback.print_exc()