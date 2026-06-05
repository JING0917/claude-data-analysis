#!/usr/bin/env python3
import pandas as pd
import numpy as np
import os

def main():
    print("开始更新Excel文件...")

    # 1. 读取原始数据
    input_path = "data_storage/20260414_美团下单统计V3_分析后.xlsx"
    output_path = "data_storage/20260414_美团下单统计V3_最终版_正确.xlsx"

    print(f"读取: {input_path}")
    df = pd.read_excel(input_path)
    print(f"读取成功: {len(df)}行, {len(df.columns)}列")

    # 2. 添加新列
    print("\n添加新列...")

    # 组合分层
    df['细分分层'] = df['匹配类型'] + '_' + df['用户分层']

    # 匹配类型优先级
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

    print("✓ 所有新列添加完成")

    # 3. 验证数据
    print("\n数据验证:")
    print(f"- 总行数: {len(df):,}")
    print(f"- 总列数: {len(df.columns)}")
    print(f"- 最高优先级用户数: {(df['运营优先级'] == '最高优先级').sum():,}")
    print(f"- 用户自己下单的高潜力用户: {((df['匹配类型'] == '用户自己下单') & (df['用户分层'] == '高潜力用户')).sum():,}")

    # 4. 保存 - 使用不同的引擎
    print(f"\n保存到: {output_path}")
    try:
        # 尝试使用openpyxl引擎
        df.to_excel(output_path, index=False, engine='openpyxl')
        print("✓ 使用openpyxl引擎保存成功")
    except Exception as e1:
        print(f"openpyxl引擎失败: {e1}")
        try:
            # 尝试默认引擎
            df.to_excel(output_path, index=False)
            print("✓ 使用默认引擎保存成功")
        except Exception as e2:
            print(f"默认引擎也失败: {e2}")
            # 最后尝试：分批保存
            print("尝试分批保存...")
            try:
                # 分5批保存
                chunk_size = len(df) // 5
                with pd.ExcelWriter(output_path, engine='openpyxl') as writer:
                    for i in range(5):
                        start_idx = i * chunk_size
                        end_idx = start_idx + chunk_size if i < 4 else len(df)
                        chunk_df = df.iloc[start_idx:end_idx]
                        chunk_df.to_excel(writer, sheet_name=f'Chunk_{i+1}', index=False)
                print("✓ 分批保存成功")
            except Exception as e3:
                print(f"所有保存方法都失败: {e3}")
                return

    # 5. 验证保存的文件
    print(f"\n验证保存的文件...")
    try:
        # 只读取前几行验证
        df_check = pd.read_excel(output_path, nrows=5, engine='openpyxl')
        print(f"✓ 文件可读: {len(df_check)}行样本")
        print(f"✓ 列数: {len(df_check.columns)}")
        print(f"✓ 最后5列: {list(df_check.columns)[-5:]}")

        # 检查文件大小
        file_size = os.path.getsize(output_path) / 1024 / 1024
        print(f"✓ 文件大小: {file_size:.2f} MB")

        if file_size < 1:
            print("警告: 文件大小异常小，可能没有保存所有数据")
            # 检查实际行数
            df_full = pd.read_excel(output_path, engine='openpyxl')
            print(f"实际行数: {len(df_full):,}")

    except Exception as e:
        print(f"验证失败: {e}")

    print(f"\n完成!")
    print(f"输入文件: {input_path}")
    print(f"输出文件: {output_path}")
    print(f"新增列: 细分分层, 匹配类型优先级, 分层分数, 综合优先级分, 运营优先级")

if __name__ == "__main__":
    main()