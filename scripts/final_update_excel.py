#!/usr/bin/env python3
# 最终更新Excel文件
import pandas as pd
import numpy as np

def main():
    # 读取现有数据
    df = pd.read_excel('data_storage/20260414_美团下单统计V3_分析后.xlsx')
    print(f"读取 {len(df)} 行数据")

    # 计算逻辑一致用户
    logic_consistent = df['小蚕美团订单量'] <= df['采集美团订单量']
    print(f"逻辑一致用户: {logic_consistent.sum():,} ({logic_consistent.sum()/len(df)*100:.1f}%)")

    # 创建组合分层
    df['细分分层'] = df['匹配类型'] + '_' + df['用户分层']

    # 创建匹配类型优先级
    priority_map = {
        '用户自己下单': 1,
        '订单部分由其他用户下单': 2,
        '订单完全由其他有关系用户下单': 3,
        '用户美团数据可能异常': 4
    }
    df['匹配类型优先级'] = df['匹配类型'].map(priority_map)

    # 分层分数
    layer_scores = {
        '高潜力用户': 5,
        '中潜力用户': 4,
        '低潜力用户': 3,
        '无差异用户': 2,
        '负差异用户': 1
    }
    df['分层分数'] = df['用户分层'].map(layer_scores)

    # 综合优先级分
    df['综合优先级分'] = df['分层分数'] * (5 - df['匹配类型优先级']) / 4

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

    # 保存结果
    output_path = 'data_storage/20260414_美团下单统计V3_最终版.xlsx'
    df.to_excel(output_path, index=False)
    print(f"保存到: {output_path}")
    print(f"新增列: 细分分层, 匹配类型优先级, 分层分数, 综合优先级分, 运营优先级")

    # 验证
    import os
    print(f"文件大小: {os.path.getsize(output_path) / 1024 / 1024:.2f} MB")

    # 关键数据验证
    print(f"\n关键数据验证:")
    print(f"最高优先级用户数: {(df['运营优先级'] == '最高优先级').sum():,}")
    print(f"用户自己下单的高潜力用户: {((df['匹配类型'] == '用户自己下单') & (df['用户分层'] == '高潜力用户')).sum():,}")
    print(f"运营优先级分布:")
    print(df['运营优先级'].value_counts())

if __name__ == "__main__":
    main()