#!/usr/bin/env python3
"""
修复平均差异计算问题：计算每个匹配类型+用户分层组合的实际平均差异
"""
import pandas as pd
import numpy as np
import sys

def calculate_correct_average_gaps():
    """计算正确的平均差异"""
    input_path = "data_storage/20260414_美团下单统计V3_分析后.xlsx"
    print(f"正在读取数据: {input_path}")

    df = pd.read_excel(input_path)
    print(f"数据形状: {df.shape}")
    print(f"列名: {list(df.columns)}")

    # 确保必要的列存在
    required_cols = ['采集美团订单量', '小蚕美团订单量', '匹配类型']
    for col in required_cols:
        if col not in df.columns:
            print(f"错误: 缺少列 {col}")
            return

    # 计算订单差异（如果不存在）
    if '订单差异' not in df.columns:
        df['订单差异'] = df['采集美团订单量'] - df['小蚕美团订单量']

    if '差异率' not in df.columns:
        df['差异率'] = np.where(
            df['采集美团订单量'] > 0,
            (df['订单差异'] * 100.0 / df['采集美团订单量']).round(2),
            0
        )

    # 重新计算用户分层
    conditions = [
        (df['订单差异'] >= 3) & (df['差异率'] >= 50),
        (df['订单差异'] >= 2),
        (df['订单差异'] == 1),
        (df['订单差异'] == 0),
        (df['订单差异'] < 0),
    ]
    choices = ['高潜力用户', '中潜力用户', '低潜力用户', '无差异用户', '负差异用户']
    df['用户分层'] = np.select(conditions, choices, default='其他')

    # 1. 计算每个匹配类型+用户分层组合的平均差异
    print(f"\n=== 计算每个匹配类型+用户分层组合的平均差异 ===")

    # 获取所有匹配类型
    match_types = df['匹配类型'].unique()
    print(f"匹配类型: {match_types}")

    # 获取所有用户分层
    user_layers = ['高潜力用户', '中潜力用户', '低潜力用户', '无差异用户', '负差异用户']

    # 计算每个组合的平均差异
    gap_stats = []
    for match_type in match_types:
        for layer in user_layers:
            subset = df[(df['匹配类型'] == match_type) & (df['用户分层'] == layer)]
            if len(subset) > 0:
                avg_gap = subset['订单差异'].mean().round(2)
                gap_stats.append({
                    '匹配类型': match_type,
                    '用户分层': layer,
                    '用户数': len(subset),
                    '平均差异': avg_gap,
                    '平均美团订单量': subset['采集美团订单量'].mean().round(2),
                    '平均小蚕美团订单量': subset['小蚕美团订单量'].mean().round(2),
                    '差异率': subset['差异率'].mean().round(2) if len(subset) > 0 else 0
                })

    # 创建DataFrame
    gap_df = pd.DataFrame(gap_stats)

    # 2. 按匹配类型分组显示
    print(f"\n=== 按匹配类型分组的平均差异 ===")
    for match_type in match_types:
        print(f"\n{match_type}:")
        type_df = gap_df[gap_df['匹配类型'] == match_type]
        for _, row in type_df.iterrows():
            print(f"  {row['用户分层']}: {row['平均差异']}单 (用户数: {row['用户数']:,})")

    # 3. 对比不同匹配类型的高潜力用户平均差异
    print(f"\n=== 不同匹配类型的高潜力用户对比 ===")
    high_potential = gap_df[gap_df['用户分层'] == '高潜力用户']
    for _, row in high_potential.iterrows():
        print(f"{row['匹配类型']}: {row['平均差异']}单 (用户数: {row['用户数']:,})")

    # 4. 对比不同匹配类型的中潜力用户平均差异
    print(f"\n=== 不同匹配类型的中潜力用户对比 ===")
    medium_potential = gap_df[gap_df['用户分层'] == '中潜力用户']
    for _, row in medium_potential.iterrows():
        print(f"{row['匹配类型']}: {row['平均差异']}单 (用户数: {row['用户数']:,})")

    # 5. 对比不同匹配类型的低潜力用户平均差异
    print(f"\n=== 不同匹配类型的低潜力用户对比 ===")
    low_potential = gap_df[gap_df['用户分层'] == '低潜力用户']
    for _, row in low_potential.iterrows():
        print(f"{row['匹配类型']}: {row['平均差异']}单 (用户数: {row['用户数']:,})")

    # 6. 保存结果
    output_path = "analysis_reports/平均差异_正确计算结果.csv"
    gap_df.to_csv(output_path, index=False, encoding='utf-8-sig')
    print(f"\n结果已保存到: {output_path}")

    return gap_df

def update_report_with_correct_gaps(gap_df):
    """使用正确的平均差异更新报告"""
    # 读取钉钉文档
    report_path = "analysis_reports/钉钉文档_小蚕用户美团下单频次分析_匹配类型分层版.md"
    print(f"\n正在更新报告: {report_path}")

    with open(report_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 提取关键数据
    high_potential_gaps = {}
    medium_potential_gaps = {}
    low_potential_gaps = {}

    for _, row in gap_df.iterrows():
        if row['用户分层'] == '高潜力用户':
            high_potential_gaps[row['匹配类型']] = row['平均差异']
        elif row['用户分层'] == '中潜力用户':
            medium_potential_gaps[row['匹配类型']] = row['平均差异']
        elif row['用户分层'] == '低潜力用户':
            low_potential_gaps[row['匹配类型']] = row['平均差异']

    print(f"\n高潜力用户平均差异:")
    for match_type, avg_gap in high_potential_gaps.items():
        print(f"  {match_type}: {avg_gap}单")

    print(f"\n中潜力用户平均差异:")
    for match_type, avg_gap in medium_potential_gaps.items():
        print(f"  {match_type}: {avg_gap}单")

    print(f"\n低潜力用户平均差异:")
    for match_type, avg_gap in low_potential_gaps.items():
        print(f"  {match_type}: {avg_gap}单")

    # 更新结论部分的核心发现
    # 由于报告结构复杂，我们先输出建议的更新内容
    print(f"\n=== 建议更新报告中的平均差异数据 ===")

    print(f"\n高潜力用户平均差异（应更新为）:")
    for match_type in ['用户自己下单', '用户美团数据可能异常', '订单部分由其他用户下单', '订单完全由其他有关系用户下单']:
        avg_gap = high_potential_gaps.get(match_type, 'N/A')
        print(f"  {match_type}: {avg_gap}单")

    print(f"\n中潜力用户平均差异（应更新为）:")
    for match_type in ['用户自己下单', '用户美团数据可能异常', '订单部分由其他用户下单', '订单完全由其他有关系用户下单']:
        avg_gap = medium_potential_gaps.get(match_type, 'N/A')
        print(f"  {match_type}: {avg_gap}单")

    print(f"\n低潜力用户平均差异（应更新为）:")
    for match_type in ['用户自己下单', '用户美团数据可能异常', '订单部分由其他用户下单', '订单完全由其他有关系用户下单']:
        avg_gap = low_potential_gaps.get(match_type, 'N/A')
        print(f"  {match_type}: {avg_gap}单")

    # 创建更新后的钉钉文档
    updated_report_path = "analysis_reports/钉钉文档_小蚕用户美团下单频次分析_匹配类型分层版_修正平均差异.md"

    # 这里需要实际更新报告内容，但为了简单起见，我们先输出更新建议
    # 实际更新需要更复杂的文本处理

if __name__ == "__main__":
    gap_df = calculate_correct_average_gaps()
    update_report_with_correct_gaps(gap_df)