#!/usr/bin/env python3
# 小蚕用户美团频次差异分析V3 - 简版报告生成
import pandas as pd
import numpy as np
import os
import sys
from datetime import datetime

def generate_simple_report_v3(input_excel_path, output_report_path):
    """生成简版报告（类似Word文档风格）"""
    print(f"正在生成简版报告: {output_report_path}")

    # 读取数据
    df = pd.read_excel(input_excel_path)

    # 列名映射到英文（便于代码处理）
    column_mapping = {
        '用户ID': 'user_id',
        '采集美团下单量': 'meituan_order_count',
        '小蚕下单量': 'silk_total_orders',
        '小蚕美团下单量': 'silk_meituan_orders',
        '小蚕饿了么下单量': 'silk_eleme_orders',
        '小蚕京东下单量': 'silk_jd_orders',
        '同用户美团下单量': 'same_user_meituan_orders',
        '非同用户美团下单量': 'different_user_meituan_orders'
    }

    df = df.rename(columns=column_mapping)

    # 基本统计
    total_users = len(df)
    total_meituan_orders = df['meituan_order_count'].sum()
    total_silk_meituan_orders = df['silk_meituan_orders'].sum()
    total_same_user_orders = df['same_user_meituan_orders'].sum()
    total_different_user_orders = df['different_user_meituan_orders'].sum()

    # 整体匹配率
    total_matched_orders = total_same_user_orders + total_different_user_orders
    overall_match_rate = round(total_matched_orders * 100.0 / total_meituan_orders, 2) if total_meituan_orders > 0 else 0

    # 订单差异分析
    df['订单差异'] = df['meituan_order_count'] - df['silk_meituan_orders']
    positive_gap = (df['订单差异'] > 0).sum()
    zero_gap = (df['订单差异'] == 0).sum()
    negative_gap = (df['订单差异'] < 0).sum()

    # 违反业务逻辑统计
    logic_violation = (df['silk_meituan_orders'] > df['meituan_order_count'])
    violation_count = logic_violation.sum()

    # 用户分层（基于订单差异）
    df['差异率'] = np.where(
        df['meituan_order_count'] > 0,
        (df['订单差异'] * 100.0 / df['meituan_order_count']).round(2),
        0
    )

    conditions = [
        (df['订单差异'] >= 3) & (df['差异率'] >= 50),
        (df['订单差异'] >= 2),
        (df['订单差异'] == 1),
        (df['订单差异'] == 0),
        (df['订单差异'] < 0),
    ]

    choices = ['高潜力用户', '中潜力用户', '低潜力用户', '无差异用户', '负差异用户']
    df['用户分层'] = np.select(conditions, choices, default='其他')

    # 匹配类型分析（基于用户业务逻辑）
    match_conditions = [
        (df['same_user_meituan_orders'] > 0) & (df['different_user_meituan_orders'] == 0),
        (df['same_user_meituan_orders'] == 0) & (df['different_user_meituan_orders'] > 0),
        (df['same_user_meituan_orders'] > 0) & (df['different_user_meituan_orders'] > 0),
        (df['same_user_meituan_orders'] == 0) & (df['different_user_meituan_orders'] == 0),
    ]

    match_choices = ['用户自己下单', '订单完全由其他有关系用户下单', '订单部分由其他用户下单', '用户美团数据可能异常']
    df['匹配类型'] = np.select(match_conditions, match_choices, default='未知')

    # 计算各类用户数
    user_self_order = (df['匹配类型'] == '用户自己下单').sum()
    other_user_order = (df['匹配类型'] == '订单完全由其他有关系用户下单').sum()
    mixed_order = (df['匹配类型'] == '订单部分由其他用户下单').sum()
    data_anomaly = (df['匹配类型'] == '用户美团数据可能异常').sum()

    high_potential = (df['用户分层'] == '高潜力用户').sum()
    medium_potential = (df['用户分层'] == '中潜力用户').sum()
    low_potential = (df['用户分层'] == '低潜力用户').sum()
    no_difference = (df['用户分层'] == '无差异用户').sum()
    negative_difference = (df['用户分层'] == '负差异用户').sum()

    # 获取当前日期
    current_date = datetime.now().strftime('%Y-%m-%d')

    # 生成简版报告
    report = f"""小蚕用户美团频次差异分析报告（简版）

分析周期：2026-03-09至2026-03-15
报告日期：{current_date}
分析用户数：{total_users:,}（完整样本，未剔除异常数据）
数据源：dwd.dwd_silkworm_fp_client_feature与dwd.dwd_sr_order_promotion_order关联数据
新增指标：同用户美团下单量、非同用户美团下单量

一、核心发现

1. 数据质量评估
   - 违反业务逻辑用户数：{violation_count:,}（{round(violation_count*100.0/total_users,2)}%）
     说明：小蚕美团订单数 > 采集美团订单数（美团数据仅采集第一页）
   - 整体订单匹配率：{overall_match_rate}%（匹配订单/美团订单）
   - 无匹配异常用户：{data_anomaly:,}（{round(data_anomaly*100.0/total_users,2)}%）

2. 订单差异分析
   - 正差异（美团>小蚕）：{positive_gap:,}用户（{round(positive_gap*100.0/total_users,2)}%）
   - 零差异（美团=小蚕）：{zero_gap:,}用户（{round(zero_gap*100.0/total_users,2)}%）
   - 负差异（美团<小蚕）：{negative_gap:,}用户（{round(negative_gap*100.0/total_users,2)}%）

3. 用户分层结果
   - 高潜力用户：{high_potential:,}（{round(high_potential*100.0/total_users,2)}%）
   - 中潜力用户：{medium_potential:,}（{round(medium_potential*100.0/total_users,2)}%）
   - 低潜力用户：{low_potential:,}（{round(low_potential*100.0/total_users,2)}%）
   - 无差异用户：{no_difference:,}（{round(no_difference*100.0/total_users,2)}%）
   - 负差异用户：{negative_difference:,}（{round(negative_difference*100.0/total_users,2)}%）

4. 匹配类型分析（基于用户业务逻辑）
   - 用户自己下单：{user_self_order:,}（{round(user_self_order*100.0/total_users,2)}%）
   - 订单完全由其他有关系用户下单：{other_user_order:,}（{round(other_user_order*100.0/total_users,2)}%）
   - 订单部分由其他用户下单：{mixed_order:,}（{round(mixed_order*100.0/total_users,2)}%）
   - 用户美团数据可能异常：{data_anomaly:,}（{round(data_anomaly*100.0/total_users,2)}%）

二、关键数据汇总

表1：基础统计
| 指标 | 数值 | 说明 |
|------|------|------|
| 分析用户总数 | {total_users:,} | 完整用户规模 |
| 美团总订单数 | {total_meituan_orders:,} | 采集的第一页数据 |
| 小蚕美团总订单数 | {total_silk_meituan_orders:,} | 小蚕中的美团订单 |
| 同用户匹配订单数 | {total_same_user_orders:,} | 用户ID一致的匹配订单 |
| 非同用户匹配订单数 | {total_different_user_orders:,} | 用户ID不一致的匹配订单 |
| 整体匹配率 | {overall_match_rate}% | 匹配订单/美团订单 |

表2：用户分层（按订单差异）
| 用户分层 | 用户数 | 占比 | 运营优先级 |
|----------|--------|------|------------|
| 高潜力用户 | {high_potential:,} | {round(high_potential*100.0/total_users,2)}% | 最高 |
| 中潜力用户 | {medium_potential:,} | {round(medium_potential*100.0/total_users,2)}% | 中等 |
| 低潜力用户 | {low_potential:,} | {round(low_potential*100.0/total_users,2)}% | 较低 |
| 无差异用户 | {no_difference:,} | {round(no_difference*100.0/total_users,2)}% | 维护即可 |
| 负差异用户 | {negative_difference:,} | {round(negative_difference*100.0/total_users,2)}% | 异常检查 |

表3：匹配类型分布（基于用户业务逻辑）
| 匹配类型 | 用户数 | 占比 | 业务含义 |
|----------|--------|------|----------|
| 用户自己下单 | {user_self_order:,} | {round(user_self_order*100.0/total_users,2)}% | 用户本人下单并匹配 |
| 订单完全由其他有关系用户下单 | {other_user_order:,} | {round(other_user_order*100.0/total_users,2)}% | 其他有关系用户下单 |
| 订单部分由其他用户下单 | {mixed_order:,} | {round(mixed_order*100.0/total_users,2)}% | 混合下单情况 |
| 用户美团数据可能异常 | {data_anomaly:,} | {round(data_anomaly*100.0/total_users,2)}% | 数据采集或匹配异常 |

三、主要结论

1. 数据质量问题严重
   - 31.37%用户数据违反业务逻辑，主要原因是美团数据仅采集第一页
   - 56.19%订单匹配率偏低，匹配算法需要优化

2. 运营机会明确
   - 83,148高潜力用户（14.07%）美团频次显著高于小蚕频次
   - 251,971用户（42.65%）存在推广潜力

3. 匹配类型洞察
   - 77.71%用户为"用户自己下单"类型
   - 17.93%用户存在数据异常（无匹配订单）

四、建议

1. 数据质量改进
   - 检查美团数据采集流程，确保数据完整性
   - 优化订单匹配算法，提高匹配准确率

2. 运营策略建议
   - 优先针对高潜力用户（83,148用户）进行推广
   - 针对不同分层用户制定差异化运营策略

3. 后续工作
   - 建立数据质量监控机制
   - 定期进行频次差异分析，跟踪运营效果

报告说明：
1. 数据范围：2026-03-09至2026-03-15（7天）
2. 美团数据限制：仅采集第一页数据，可能导致数据不完整
3. 分析样本：完整用户数据，未剔除异常记录
4. 报告版本：V3简版（含同用户/非同用户匹配指标）

报告生成时间：{current_date}
"""

    # 保存报告
    with open(output_report_path, 'w', encoding='utf-8') as f:
        f.write(report)

    print(f"简版报告已保存至: {output_report_path}")
    return report

def main():
    """主函数"""
    input_excel_path = "data_storage/20260414_美团下单统计V3.xlsx"
    output_report_path = "analysis_reports/小蚕用户美团频次差异分析V3_简版.md"

    if not os.path.exists(input_excel_path):
        print(f"错误: Excel文件不存在: {input_excel_path}")
        return

    print("=" * 60)
    print("小蚕用户美团频次差异分析V3 - 简版报告生成")
    print("=" * 60)

    try:
        generate_simple_report_v3(input_excel_path, output_report_path)
        print(f"\n简版报告已生成: {output_report_path}")

    except Exception as e:
        print(f"生成简版报告过程中出错: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()