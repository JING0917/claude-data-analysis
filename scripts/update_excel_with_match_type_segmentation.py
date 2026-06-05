#!/usr/bin/env python3
# 更新Excel文件 - 添加匹配类型分层列
import pandas as pd
import numpy as np
import os

def main():
    input_path = "data_storage/20260414_美团下单统计V3_分析后.xlsx"
    output_path = "data_storage/20260414_美团下单统计V3_匹配类型分层.xlsx"

    print("=" * 70)
    print("更新Excel文件 - 添加匹配类型分层列")
    print("=" * 70)

    if not os.path.exists(input_path):
        print(f"错误: 输入文件不存在: {input_path}")
        return

    try:
        # 1. 加载数据
        print(f"正在读取Excel文件: {input_path}")
        df = pd.read_excel(input_path)
        print(f"原始数据形状: {df.shape}")
        print(f"用户数: {len(df):,}")

        # 2. 确保必要的列存在
        required_cols = ['采集美团订单量', '小蚕美团订单量', '匹配类型', '用户分层', '订单差异', '差异率']
        missing_cols = [col for col in required_cols if col not in df.columns]
        if missing_cols:
            print(f"警告: 缺少列: {missing_cols}")
            # 计算缺失的列
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

        # 3. 创建组合分层：匹配类型 + 用户分层
        df['细分分层'] = df['匹配类型'] + '_' + df['用户分层']
        print("创建了'细分分层'列")

        # 4. 创建匹配类型优先级
        priority_map = {
            '用户自己下单': 1,
            '订单部分由其他用户下单': 2,
            '订单完全由其他有关系用户下单': 3,
            '用户美团数据可能异常': 4
        }
        df['匹配类型优先级'] = df['匹配类型'].map(priority_map)
        print("创建了'匹配类型优先级'列")

        # 5. 分层分数
        layer_scores = {
            '高潜力用户': 5,
            '中潜力用户': 4,
            '低潜力用户': 3,
            '无差异用户': 2,
            '负差异用户': 1
        }
        df['分层分数'] = df['用户分层'].map(layer_scores)
        print("创建了'分层分数'列")

        # 6. 综合优先级分
        df['综合优先级分'] = df['分层分数'] * (5 - df['匹配类型优先级']) / 4
        print("创建了'综合优先级分'列")

        # 7. 运营优先级
        conditions = [
            df['综合优先级分'] >= 4.5,
            df['综合优先级分'] >= 3.5,
            df['综合优先级分'] >= 2.5,
            df['综合优先级分'] >= 1.5,
            df['综合优先级分'] < 1.5
        ]
        choices = ['最高优先级', '高优先级', '中优先级', '低优先级', '监控即可']
        df['运营优先级'] = np.select(conditions, choices, default='其他')
        print("创建了'运营优先级'列")

        # 8. 验证数据
        print(f"\n数据验证:")
        print(f"- 总行数: {len(df):,}")
        print(f"- 新增列数: 6列")
        print(f"- 运营优先级分布: {df['运营优先级'].value_counts().to_dict()}")

        # 9. 保存数据
        print(f"\n正在保存到: {output_path}")
        df.to_excel(output_path, index=False)

        # 10. 验证保存的文件
        df_check = pd.read_excel(output_path)
        print(f"验证: 读取的文件有 {len(df_check):,} 行, {df_check.shape[1]} 列")
        print(f"文件大小: {os.path.getsize(output_path) / 1024 / 1024:.2f} MB")

        print(f"\n✓ 完成!")
        print(f"输入文件: {input_path}")
        print(f"输出文件: {output_path}")
        print(f"新增列: 细分分层, 匹配类型优先级, 分层分数, 综合优先级分, 运营优先级")

    except Exception as e:
        print(f"错误: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()