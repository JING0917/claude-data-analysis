#!/usr/bin/env python3
import pandas as pd
import numpy as np
import sys

# 加载数据
df = pd.read_excel('data_storage/20260414_美团下单统计V3_分析后.xlsx')
print(f"原始数据形状: {df.shape}")
print(f"列名: {list(df.columns)}")

# 检查必要的列
required_cols = ['采集美团订单量', '小蚕美团订单量', '匹配类型', '用户分层']
for col in required_cols:
    if col in df.columns:
        print(f"✓ 列 '{col}' 存在")
    else:
        print(f"✗ 列 '{col}' 不存在")

# 计算订单差异和差异率（如果不存在）
if '订单差异' not in df.columns:
    df['订单差异'] = df['采集美团订单量'] - df['小蚕美团订单量']
    print("计算了订单差异列")

if '差异率' not in df.columns:
    df['差异率'] = np.where(
        df['采集美团订单量'] > 0,
        (df['订单差异'] * 100.0 / df['采集美团订单量']).round(2),
        0
    )
    print("计算了差异率列")

# 创建组合分层
df['细分分层'] = df['匹配类型'] + '_' + df['用户分层']
print(f"创建了细分分层列，示例值: {df['细分分层'].iloc[0]}")

# 创建匹配类型优先级
priority_map = {
    '用户自己下单': 1,
    '订单部分由其他用户下单': 2,
    '订单完全由其他有关系用户下单': 3,
    '用户美团数据可能异常': 4
}

df['匹配类型优先级'] = df['匹配类型'].map(priority_map)
print(f"创建了匹配类型优先级列，唯一值: {df['匹配类型优先级'].unique()}")

# 分层分数
layer_scores = {
    '高潜力用户': 5,
    '中潜力用户': 4,
    '低潜力用户': 3,
    '无差异用户': 2,
    '负差异用户': 1
}

df['分层分数'] = df['用户分层'].map(layer_scores)
print(f"创建了分层分数列，唯一值: {df['分层分数'].unique()}")

# 综合优先级分
df['综合优先级分'] = df['分层分数'] * (5 - df['匹配类型优先级']) / 4
print(f"创建了综合优先级分列，范围: [{df['综合优先级分'].min():.2f}, {df['综合优先级分'].max():.2f}]")

# 运营优先级
conditions = [
    df['综合优先级分'] >= 4.5,
    df['综合优先级分'] >= 3.5,
    df['综合优先级分'] >= 2.5,
    df['综合优先级分'] >= 1.5,
    df['综合优先级分'] < 1.5
]
choices = ['最高优先级', '高优先级', '中优先级', '低优先级', '监控即可']
df['运营优先级'] = np.select(conditions, choices, default='其他')
print(f"创建了运营优先级列，分布: {df['运营优先级'].value_counts().to_dict()}")

# 保存测试文件
output_path = 'data_storage/test_output.xlsx'
df.to_excel(output_path, index=False)
print(f"测试文件已保存至: {output_path}")
print(f"最终数据形状: {df.shape}")
print(f"最终列名: {list(df.columns)}")

# 验证文件可读
df_check = pd.read_excel(output_path)
print(f"验证读取: {df_check.shape} 行 x {df_check.shape[1]} 列")