#!/usr/bin/env python3
# 验证无匹配用户中的潜力用户分布
import pandas as pd
import numpy as np
import os
import sys

def validate_no_match_users():
    """验证无匹配用户中的潜力用户分布"""
    input_excel_path = "data_storage/20260414_美团下单统计V3_分析后.xlsx"

    print("=== 验证无匹配用户中的潜力用户分布 ===")
    print(f"读取Excel文件: {input_excel_path}")

    try:
        # 读取Excel文件
        df = pd.read_excel(input_excel_path)
        print(f"数据形状: {df.shape}")
        print(f"总用户数: {len(df):,}")

        # 获取列名
        print(f"\n列名: {list(df.columns)}")

        # 查看实际列名
        print(f"前10个列名: {list(df.columns)[:10]}")

        # 检查列名，根据实际列名调整
        if '同用户匹配美团订单量' in df.columns:
            # 使用中文列名（根据实际列名）
            meituan_col = '采集美团订单量'
            silk_col = '小蚕美团订单量'
            same_user_col = '同用户匹配美团订单量'
            diff_user_col = '非同用户匹配美团订单量'
            match_type_col = '匹配类型'
        elif '同用户美团下单量' in df.columns:
            # 使用中文列名
            meituan_col = '采集美团下单量'
            silk_col = '小蚕美团下单量'
            same_user_col = '同用户美团下单量'
            diff_user_col = '非同用户美团下单量'
            match_type_col = '匹配类型'
        else:
            # 使用英文列名
            meituan_col = 'meituan_order_count'
            silk_col = 'silk_meituan_orders'
            same_user_col = 'same_user_meituan_orders'
            diff_user_col = 'different_user_meituan_orders'
            match_type_col = '匹配类型'

        # 1. 定义无匹配用户（同用户=0，非同用户=0）
        no_match_mask = (df[same_user_col] == 0) & (df[diff_user_col] == 0)
        no_match_users = df[no_match_mask]
        print(f"\n1. 无匹配用户总数: {len(no_match_users):,} ({len(no_match_users)*100/len(df):.2f}%)")

        # 2. 细分无匹配用户
        # a) 美团下单量=0，小蚕下单量=0
        case1 = no_match_mask & (df[meituan_col] == 0) & (df[silk_col] == 0)
        case1_count = case1.sum()

        # b) 美团下单量=0，小蚕下单量>0
        case2 = no_match_mask & (df[meituan_col] == 0) & (df[silk_col] > 0)
        case2_count = case2.sum()

        # c) 美团下单量>0，小蚕下单量=0 (潜力用户)
        case3 = no_match_mask & (df[meituan_col] > 0) & (df[silk_col] == 0)
        case3_count = case3.sum()

        # d) 美团下单量>0，小蚕下单量>0
        case4 = no_match_mask & (df[meituan_col] > 0) & (df[silk_col] > 0)
        case4_count = case4.sum()

        print(f"\n2. 无匹配用户细分:")
        print(f"  a) 美团=0，小蚕=0: {case1_count:,} ({case1_count*100/len(no_match_users):.2f}%) - 无活动用户")
        print(f"  b) 美团=0，小蚕>0: {case2_count:,} ({case2_count*100/len(no_match_users):.2f}%) - 数据异常")
        print(f"  c) 美团>0，小蚕=0: {case3_count:,} ({case3_count*100/len(no_match_users):.2f}%) - **潜力用户**")
        print(f"  d) 美团>0，小蚕>0: {case4_count:,} ({case4_count*100/len(no_match_users):.2f}%) - 数据匹配问题")

        # 3. 查看潜力用户（美团>0，小蚕=0）的详细情况
        potential_users = df[case3]
        if len(potential_users) > 0:
            print(f"\n3. 潜力用户（美团>0，小蚕=0）详细分析:")
            print(f"  - 平均美团订单量: {potential_users[meituan_col].mean():.2f}单")
            print(f"  - 美团订单量分布:")
            for i in range(1, 11):
                count = (potential_users[meituan_col] == i).sum()
                if count > 0:
                    print(f"    - {i}单: {count:,}用户 ({count*100/len(potential_users):.2f}%)")
            if (potential_users[meituan_col] > 10).sum() > 0:
                count = (potential_users[meituan_col] > 10).sum()
                print(f"    - >10单: {count:,}用户 ({count*100/len(potential_users):.2f}%)")

        # 4. 查看整体数据中的美团>0且小蚕=0的用户（无论是否有匹配）
        all_potential_mask = (df[meituan_col] > 0) & (df[silk_col] == 0)
        all_potential_users = df[all_potential_mask]
        print(f"\n4. 整体数据中所有美团>0且小蚕=0的用户:")
        print(f"  - 总用户数: {len(all_potential_users):,} ({len(all_potential_users)*100/len(df):.2f}%)")
        print(f"  - 其中无匹配的用户: {case3_count:,} ({case3_count*100/len(all_potential_users):.2f}%)")
        print(f"  - 其中有匹配的用户: {len(all_potential_users)-case3_count:,} ({(len(all_potential_users)-case3_count)*100/len(all_potential_users):.2f}%)")

        # 5. 计算整体数据中的各种情况
        print(f"\n5. 整体数据分布（所有590,761用户）:")

        # 计算逻辑一致用户
        logical_consistent = (df[silk_col] <= df[meituan_col])
        logical_consistent_count = logical_consistent.sum()
        print(f"  - 逻辑一致用户: {logical_consistent_count:,} ({logical_consistent_count*100/len(df):.2f}%)")

        # 计算正差异用户
        positive_gap = (df[meituan_col] > df[silk_col])
        positive_gap_count = positive_gap.sum()
        print(f"  - 正差异用户: {positive_gap_count:,} ({positive_gap_count*100/len(df):.2f}%)")

        # 计算负差异用户
        negative_gap = (df[meituan_col] < df[silk_col])
        negative_gap_count = negative_gap.sum()
        print(f"  - 负差异用户: {negative_gap_count:,} ({negative_gap_count*100/len(df):.2f}%)")

        # 计算零差异用户
        zero_gap = (df[meituan_col] == df[silk_col])
        zero_gap_count = zero_gap.sum()
        print(f"  - 零差异用户: {zero_gap_count:,} ({zero_gap_count*100/len(df):.2f}%)")

        return {
            'total_users': len(df),
            'no_match_users': len(no_match_users),
            'potential_users': case3_count,
            'logical_consistent': logical_consistent_count,
            'positive_gap': positive_gap_count,
            'negative_gap': negative_gap_count,
            'zero_gap': zero_gap_count
        }

    except Exception as e:
        print(f"读取文件时出错: {e}")
        return None

if __name__ == "__main__":
    validate_no_match_users()