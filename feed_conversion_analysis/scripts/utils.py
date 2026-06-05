#!/usr/bin/env python3
"""
工具函数库 - feed流分析专用
"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import os
import json

def validate_data_columns(df, required_cols):
    """
    验证数据列是否存在

    参数:
    df: DataFrame
    required_cols: 必需列列表

    返回:
    bool: 是否通过验证
    """
    missing_cols = [col for col in required_cols if col not in df.columns]
    if missing_cols:
        print(f"错误: 缺少以下必需列: {missing_cols}")
        print(f"可用列: {list(df.columns)}")
        return False
    return True

def calculate_conversion_rate(df, clicks_col='clc_num', orders_col='order_num'):
    """
    计算转化率

    参数:
    df: DataFrame
    clicks_col: 点击量列名
    orders_col: 订单量列名

    返回:
    conversion_rate: 转化率Series
    """
    if clicks_col not in df.columns or orders_col not in df.columns:
        print(f"警告: 缺少转化率计算所需列")
        return pd.Series([0] * len(df), index=df.index)

    return np.where(
        df[clicks_col] > 0,
        df[orders_col] * 100.0 / df[clicks_col],
        0
    )

def summarize_by_group(df, group_cols, metric_cols):
    """
    按分组汇总数据

    参数:
    df: DataFrame
    group_cols: 分组列列表
    metric_cols: 需要汇总的指标列列表

    返回:
    summary_df: 汇总DataFrame
    """
    if not validate_data_columns(df, group_cols + metric_cols):
        return pd.DataFrame()

    # 创建汇总字典
    agg_dict = {}
    for col in metric_cols:
        if pd.api.types.is_numeric_dtype(df[col]):
            agg_dict[col] = 'sum'
        else:
            agg_dict[col] = 'count'

    summary = df.groupby(group_cols).agg(agg_dict).reset_index()

    return summary

def detect_anomalies(df, metric_col, threshold=3):
    """
    检测异常值（基于标准差）

    参数:
    df: DataFrame
    metric_col: 指标列名
    threshold: 标准差阈值

    返回:
    anomalies: 异常值DataFrame
    """
    if metric_col not in df.columns or not pd.api.types.is_numeric_dtype(df[metric_col]):
        print(f"警告: 无法检测 {metric_col} 的异常值")
        return pd.DataFrame()

    mean = df[metric_col].mean()
    std = df[metric_col].std()

    if std == 0:
        return pd.DataFrame()

    # 计算Z-score
    df['z_score'] = (df[metric_col] - mean) / std

    # 检测异常值
    anomalies = df[np.abs(df['z_score']) > threshold].copy()

    if len(anomalies) > 0:
        print(f"检测到 {len(anomalies)} 个异常值 (|Z-score| > {threshold}):")
        print(anomalies[[metric_col, 'z_score']].head())

    return anomalies

def calculate_statistical_significance(df, group_col, metric_col, group_a, group_b):
    """
    计算两组数据的统计显著性（简化版）

    参数:
    df: DataFrame
    group_col: 分组列名
    metric_col: 指标列名
    group_a: 第一组名称
    group_b: 第二组名称

    返回:
    result_dict: 包含统计检验结果的字典
    """
    if not validate_data_columns(df, [group_col, metric_col]):
        return None

    group_a_data = df[df[group_col] == group_a][metric_col].dropna()
    group_b_data = df[df[group_col] == group_b][metric_col].dropna()

    if len(group_a_data) < 2 or len(group_b_data) < 2:
        print(f"警告: 样本量不足，无法计算统计显著性")
        return None

    # 计算基本统计量
    result = {
        'group_a': group_a,
        'group_b': group_b,
        'n_a': len(group_a_data),
        'n_b': len(group_b_data),
        'mean_a': group_a_data.mean(),
        'mean_b': group_b_data.mean(),
        'std_a': group_a_data.std(),
        'std_b': group_b_data.std(),
        'mean_diff': group_a_data.mean() - group_b_data.mean(),
        'relative_diff': (group_a_data.mean() - group_b_data.mean()) * 100.0 / group_b_data.mean() if group_b_data.mean() != 0 else 0
    }

    # 简化显著性判断（基于均值差异和标准差）
    pooled_std = np.sqrt((result['std_a']**2 + result['std_b']**2) / 2)
    if pooled_std > 0:
        result['effect_size'] = result['mean_diff'] / pooled_std
    else:
        result['effect_size'] = 0

    # 经验规则判断显著性
    if result['effect_size'] > 0.5:
        result['significance'] = '可能显著'
    elif result['effect_size'] > 0.2:
        result['significance'] = '中等效应'
    else:
        result['significance'] = '效应较小'

    return result

def save_analysis_results(results_dict, output_dir, prefix='analysis'):
    """
    保存分析结果到文件

    参数:
    results_dict: 结果字典
    output_dir: 输出目录
    prefix: 文件名前缀
    """
    os.makedirs(output_dir, exist_ok=True)

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

    # 保存为JSON
    json_path = os.path.join(output_dir, f"{prefix}_{timestamp}.json")
    with open(json_path, 'w', encoding='utf-8') as f:
        # 转换非序列化对象
        serializable_dict = {}
        for key, value in results_dict.items():
            if isinstance(value, (pd.DataFrame, pd.Series)):
                serializable_dict[key] = value.to_dict()
            elif isinstance(value, (np.int64, np.float64)):
                serializable_dict[key] = float(value)
            elif isinstance(value, np.ndarray):
                serializable_dict[key] = value.tolist()
            else:
                serializable_dict[key] = value

        json.dump(serializable_dict, f, ensure_ascii=False, indent=2)

    print(f"分析结果已保存: {json_path}")

    # 保存DataFrame为CSV
    for key, value in results_dict.items():
        if isinstance(value, pd.DataFrame):
            csv_path = os.path.join(output_dir, f"{prefix}_{key}_{timestamp}.csv")
            value.to_csv(csv_path, index=False, encoding='utf-8-sig')
            print(f"  {key} 数据已保存: {csv_path}")

    return json_path

def load_analysis_results(json_path):
    """
    加载分析结果

    参数:
    json_path: JSON文件路径

    返回:
    results_dict: 结果字典
    """
    if not os.path.exists(json_path):
        print(f"错误: 文件不存在 {json_path}")
        return None

    with open(json_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    # 转换回DataFrame
    results_dict = {}
    for key, value in data.items():
        if isinstance(value, dict) and 'index' in value and 'data' in value:
            # 可能是DataFrame的字典表示
            try:
                df = pd.DataFrame.from_dict(value['data'])
                results_dict[key] = df
            except:
                results_dict[key] = value
        else:
            results_dict[key] = value

    print(f"已加载分析结果: {json_path}")
    return results_dict

def format_number(num, decimal_places=2):
    """
    格式化数字显示

    参数:
    num: 数字
    decimal_places: 小数位数

    返回:
    formatted_str: 格式化字符串
    """
    if pd.isna(num):
        return "N/A"

    if isinstance(num, (int, np.integer)):
        return f"{num:,}"

    if isinstance(num, (float, np.floating)):
        if abs(num) >= 1000:
            return f"{num:,.{decimal_places}f}"
        else:
            return f"{num:.{decimal_places}f}"

    return str(num)

def create_summary_table(data_dict, title="数据汇总"):
    """
    创建汇总表格字符串

    参数:
    data_dict: 数据字典 {指标名: 值}
    title: 表格标题

    返回:
    table_str: 表格字符串
    """
    if not data_dict:
        return "无数据"

    # 确定最大长度
    max_key_len = max(len(str(key)) for key in data_dict.keys())
    max_value_len = max(len(format_number(value)) for value in data_dict.values())

    # 创建表格
    table_width = max_key_len + max_value_len + 7
    table_str = f"\n{title}\n"
    table_str += "=" * table_width + "\n"

    for key, value in data_dict.items():
        key_str = str(key).ljust(max_key_len)
        value_str = format_number(value).rjust(max_value_len)
        table_str += f"| {key_str} | {value_str} |\n"

    table_str += "=" * table_width

    return table_str