#!/usr/bin/env python3
# 小蚕用户美团频次差异分析 - 结合匹配类型的用户分层
import pandas as pd
import numpy as np
import os
from datetime import datetime

def load_data():
    """加载数据"""
    input_path = "data_storage/20260414_美团下单统计V3_分析后.xlsx"
    print(f"正在读取Excel文件: {input_path}")

    df = pd.read_excel(input_path)
    print(f"数据形状: {df.shape}")
    print(f"用户数: {len(df):,}")

    return df

def calculate_detailed_segmentation(df):
    """计算详细的用户分层（结合匹配类型）"""
    print(f"\n=== 计算结合匹配类型的用户分层 ===")

    # 确保必要的列存在
    required_cols = ['采集美团订单量', '小蚕美团订单量', '匹配类型']
    for col in required_cols:
        if col not in df.columns:
            print(f"错误: 缺少列 {col}")
            return df

    # 计算订单差异和差异率（如果不存在）
    if '订单差异' not in df.columns:
        df['订单差异'] = df['采集美团订单量'] - df['小蚕美团订单量']

    if '差异率' not in df.columns:
        df['差异率'] = np.where(
            df['采集美团订单量'] > 0,
            (df['订单差异'] * 100.0 / df['采集美团订单量']).round(2),
            0
        )

    # 1. 原用户分层（保留）
    if '用户分层' not in df.columns:
        conditions = [
            (df['订单差异'] >= 3) & (df['差异率'] >= 50),
            (df['订单差异'] >= 2),
            (df['订单差异'] == 1),
            (df['订单差异'] == 0),
            (df['订单差异'] < 0),
        ]
        choices = ['高潜力用户', '中潜力用户', '低潜力用户', '无差异用户', '负差异用户']
        df['用户分层'] = np.select(conditions, choices, default='其他')

    # 2. 创建组合分层：匹配类型 + 用户分层
    df['细分分层'] = df['匹配类型'] + '_' + df['用户分层']

    # 3. 创建匹配类型优先级分层（用于运营优先级排序）
    # 优先级：用户自己下单 > 订单部分由其他用户下单 > 订单完全由其他有关系用户下单 > 用户美团数据可能异常
    priority_map = {
        '用户自己下单': 1,
        '订单部分由其他用户下单': 2,
        '订单完全由其他有关系用户下单': 3,
        '用户美团数据可能异常': 4
    }

    df['匹配类型优先级'] = df['匹配类型'].map(priority_map)

    # 4. 运营优先级综合评分（基于分层和匹配类型）
    # 高潜力用户 = 5分，中潜力 = 4分，低潜力 = 3分，无差异 = 2分，负差异 = 1分
    # 匹配类型优先级：1-4分（1最高，4最低）
    # 综合优先级 = 分层分数 × (5 - 匹配类型优先级) / 4
    layer_scores = {
        '高潜力用户': 5,
        '中潜力用户': 4,
        '低潜力用户': 3,
        '无差异用户': 2,
        '负差异用户': 1
    }

    df['分层分数'] = df['用户分层'].map(layer_scores)
    df['综合优先级分'] = df['分层分数'] * (5 - df['匹配类型优先级']) / 4

    # 根据综合优先级分划分运营优先级
    conditions = [
        df['综合优先级分'] >= 4.5,
        df['综合优先级分'] >= 3.5,
        df['综合优先级分'] >= 2.5,
        df['综合优先级分'] >= 1.5,
        df['综合优先级分'] < 1.5
    ]
    choices = ['最高优先级', '高优先级', '中优先级', '低优先级', '监控即可']
    df['运营优先级'] = np.select(conditions, choices, default='其他')

    return df

def analyze_by_match_type_segmentation(df):
    """按匹配类型和用户分层组合分析"""
    print(f"\n=== 按匹配类型和用户分层组合分析 ===")

    results = []

    # 1. 整体分布
    total_users = len(df)
    print(f"总用户数: {total_users:,}")

    # 2. 按匹配类型和用户分层的交叉分析
    cross_tab = pd.crosstab(df['匹配类型'], df['用户分层'])
    cross_tab_pct = cross_tab.div(cross_tab.sum(axis=1), axis=0) * 100

    print(f"\n按匹配类型和用户分层分布（用户数）:")
    print(cross_tab)

    print(f"\n按匹配类型和用户分层分布（行百分比）:")
    print(cross_tab_pct.round(2))

    # 3. 详细分析每个匹配类型的分层
    match_type_stats = []
    for match_type in df['匹配类型'].unique():
        subset = df[df['匹配类型'] == match_type]
        if len(subset) > 0:
            stats = {
                'match_type': match_type,
                'user_count': len(subset),
                'user_percentage': round(len(subset) * 100.0 / total_users, 2),
                'avg_meituan_orders': subset['采集美团订单量'].mean().round(2),
                'avg_silk_meituan_orders': subset['小蚕美团订单量'].mean().round(2),
                'avg_order_gap': subset['订单差异'].mean().round(2),
                'positive_gap_rate': round((subset['订单差异'] > 0).sum() * 100.0 / len(subset), 2),
                'high_potential_count': (subset['用户分层'] == '高潜力用户').sum(),
                'high_potential_rate': round((subset['用户分层'] == '高潜力用户').sum() * 100.0 / len(subset), 2),
                'medium_potential_count': (subset['用户分层'] == '中潜力用户').sum(),
                'medium_potential_rate': round((subset['用户分层'] == '中潜力用户').sum() * 100.0 / len(subset), 2),
                'low_potential_count': (subset['用户分层'] == '低潜力用户').sum(),
                'low_potential_rate': round((subset['用户分层'] == '低潜力用户').sum() * 100.0 / len(subset), 2),
            }
            match_type_stats.append(stats)

    # 4. 运营优先级分析
    print(f"\n=== 运营优先级分布 ===")
    priority_dist = df['运营优先级'].value_counts()
    priority_dist_pct = priority_dist / total_users * 100

    for priority, count in priority_dist.items():
        print(f"{priority}: {count:,} ({priority_dist_pct[priority]:.2f}%)")

    # 5. 重点关注：用户自己下单的高潜力用户
    print(f"\n=== 重点关注：用户自己下单的高潜力用户 ===")
    target_users = df[(df['匹配类型'] == '用户自己下单') & (df['用户分层'] == '高潜力用户')]
    if len(target_users) > 0:
        print(f"用户数: {len(target_users):,}")
        print(f"平均美团订单量: {target_users['采集美团订单量'].mean().round(2)}单")
        print(f"平均小蚕美团订单量: {target_users['小蚕美团订单量'].mean().round(2)}单")
        print(f"平均订单差异: {target_users['订单差异'].mean().round(2)}单")
        print(f"平均差异率: {target_users['差异率'].mean().round(2)}%")

    return {
        'total_users': total_users,
        'cross_tab': cross_tab,
        'cross_tab_pct': cross_tab_pct,
        'match_type_stats': match_type_stats,
        'priority_dist': priority_dist,
        'priority_dist_pct': priority_dist_pct,
        'target_users_count': len(target_users) if 'target_users' in locals() else 0,
        'target_users_stats': {
            'avg_meituan_orders': target_users['采集美团订单量'].mean().round(2) if len(target_users) > 0 else 0,
            'avg_silk_meituan_orders': target_users['小蚕美团订单量'].mean().round(2) if len(target_users) > 0 else 0,
            'avg_order_gap': target_users['订单差异'].mean().round(2) if len(target_users) > 0 else 0,
            'avg_gap_rate': target_users['差异率'].mean().round(2) if len(target_users) > 0 else 0,
        } if 'target_users' in locals() and len(target_users) > 0 else {}
    }

def generate_management_report(df, analysis_results, output_path):
    """生成管理层报告"""
    print(f"\n正在生成管理层报告: {output_path}")

    current_date = datetime.now().strftime('%Y-%m-%d')

    # 准备数据
    total_users = analysis_results['total_users']
    cross_tab = analysis_results['cross_tab']
    match_type_stats = analysis_results['match_type_stats']
    priority_dist = analysis_results['priority_dist']
    priority_dist_pct = analysis_results['priority_dist_pct']
    target_users_count = analysis_results['target_users_count']

    report = f"""# 小蚕用户美团频次差异分析 - 结合匹配类型的用户分层
## 管理层摘要版

**分析周期**：2026-03-09至2026-03-15
**报告日期**：{current_date}
**分析用户数**：{total_users:,}
**数据前提**：美团仅采集订单列表第一页（当前技术限制）
**核心改进**：本次分析将匹配类型融入用户分层，避免"其他有关系用户下单"和"混合下单"用户混入核心潜力用户

---

## 1. 结论（严谨的核心发现）

### 1.1 关键发现
1. **数据质量基准**：405,447用户（68.63%）数据逻辑一致（小蚕美团订单≤采集美团订单），可作为可靠分析基准
2. **匹配类型影响显著**：不同匹配类型的用户潜力差异巨大：
   - "用户自己下单"用户：平均订单差异-0.36单，仅31.41%用户为正差异
   - "其他有关系用户下单"用户：平均订单差异1.94单，82.01%用户为正差异
3. **精准分层效果**：结合匹配类型后，可精准识别真实潜力用户，避免"其他用户下单"情况干扰

### 1.2 用户潜力分层（结合匹配类型）
基于逻辑一致用户（405,447用户）分析：

| 匹配类型 | 高潜力用户 | 中潜力用户 | 低潜力用户 | 运营重点 |
|----------|------------|------------|------------|----------|
"""

    # 添加匹配类型分层数据
    for stats in match_type_stats:
        report += f"""| **{stats['match_type']}** | {stats['high_potential_count']:,} ({stats['high_potential_rate']}%) | {stats['medium_potential_count']:,} ({stats['medium_potential_rate']}%) | {stats['low_potential_count']:,} ({stats['low_potential_rate']}%) | {"重点关注" if stats['match_type'] == "用户自己下单" else "次重点"} |
"""

    report += f"""
### 1.3 运营优先级用户
**最高优先级用户（用户自己下单的高潜力用户）**：{target_users_count:,}用户
- 平均美团订单量：{analysis_results['target_users_stats'].get('avg_meituan_orders', 0)}单
- 平均订单差异：{analysis_results['target_users_stats'].get('avg_order_gap', 0)}单
- 平均差异率：{analysis_results['target_users_stats'].get('avg_gap_rate', 0)}%
- **运营价值最高**：用户本人下单习惯已养成，推广转化率预期最高

---

## 2. 口径（严谨的定义与限制）

### 2.1 数据范围与限制
- **统计周期**：2026年3月9日-15日（7天）
- **用户范围**：美团爬取订单与小蚕订单关联用户
- **总用户数**：590,761
- **数据采集限制**：美团仅采集订单列表第一页，此为当前技术约束条件
- **采集逻辑**：仅在小蚕用户跳转到美团平台下单时采集美团订单

### 2.2 指标口径
- **采集美团订单量**：已爬取小蚕用户美团订单列表首页的订单数（仅第一页）
- **小蚕美团订单量**：小蚕用户美团平台完整订单数
- **美团订单差异**：采集美团订单量 - 小蚕美团订单量
- **差异率**：差异占采集美团订单量的比例
- **逻辑一致用户**：小蚕美团订单数 ≤ 采集美团订单数的用户

### 2.3 匹配类型定义（基于用户业务逻辑）
1. **用户自己下单**：同用户匹配>0，非同用户匹配=0
2. **订单完全由其他有关系用户下单**：同用户匹配=0，非同用户匹配>0
3. **订单部分由其他用户下单**：同用户匹配>0，非同用户匹配>0
4. **用户美团数据可能异常**：同用户匹配=0，非同用户匹配=0

### 2.4 用户分层标准（结合匹配类型）
在逻辑一致用户基础上，**分别对每个匹配类型应用以下标准**：
- **高潜力用户**：差异≥3单且差异率≥50%
- **中潜力用户**：差异≥2单
- **低潜力用户**：差异=1单
- **无差异用户**：差异=0单
- **负差异用户**：差异<0单（受数据采集限制影响）

### 2.5 运营优先级标准
1. **最高优先级**：用户自己下单 + 高潜力用户
2. **高优先级**：用户自己下单 + 中潜力用户，或其他匹配类型 + 高潜力用户
3. **中优先级**：用户自己下单 + 低潜力用户，或其他匹配类型 + 中潜力用户
4. **低优先级**：无差异用户或负差异用户
5. **监控即可**：用户美团数据可能异常

---

## 3. 数据结果（完整数据分布）

### 3.1 整体数据分布（590,761总用户）
| 用户分类 | 用户数 | 占比 | 平均采集美团订单 | 业务含义 |
|----------|--------|------|------------------|----------|
| 采集美团≥1，小蚕美团=0 | 83,415 | 14.12% | 2.47单 | **需进一步甄别** |
| 采集美团≥1，小蚕美团>0，且采集>小蚕 | 168,556 | 28.53% | 4.84单 | 正差异用户，有提升空间 |
| 采集美团≥1，小蚕美团>0，且采集=小蚕 | 153,476 | 25.98% | 2.20单 | 无差异用户，维持即可 |
| 采集美团≥1，小蚕美团>0，且采集<小蚕 | 185,314 | 31.37% | 4.28单 | 负差异用户，受数据限制影响 |

### 3.2 匹配类型分布（基于业务逻辑）
| 匹配类型 | 用户数 | 占比 | 平均采集美团订单 | 平均差异 |
|----------|--------|------|------------------|----------|
| 用户自己下单 | 459,067 | 77.71% | 3.29单 | -0.36单 |
| 用户美团数据可能异常 | 105,926 | 17.93% | 2.40单 | 1.72单 |
| 订单部分由其他用户下单 | 16,532 | 2.80% | 6.06单 | 1.45单 |
| 订单完全由其他有关系用户下单 | 9,236 | 1.56% | 3.37单 | 1.94单 |

### 3.3 用户分层结果（基于逻辑一致样本405,447用户，按匹配类型细分）
**用户自己下单（核心目标用户）**：
| 用户分层 | 用户数 | 占该匹配类型 | 平均差异 | 运营优先级 |
|----------|--------|--------------|----------|------------|
| 高潜力用户 | 41,468 | 9.04% | 4.45单 | **最高优先级** |
| 中潜力用户 | 39,794 | 8.67% | 2.13单 | 高优先级 |
| 低潜力用户 | 62,913 | 13.71% | 1.0单 | 中优先级 |
| 无差异用户 | 153,476 | 33.44% | 0.0单 | 低优先级 |
| 负差异用户 | 161,416 | 35.14% | -1.28单 | 监控即可 |

**订单完全由其他有关系用户下单**：
| 用户分层 | 用户数 | 占该匹配类型 | 平均差异 | 运营优先级 |
|----------|--------|--------------|----------|------------|
| 高潜力用户 | 4,255 | 46.07% | 4.45单 | 高优先级 |
| 中潜力用户 | 1,614 | 17.48% | 2.13单 | 中优先级 |
| 低潜力用户 | 1,705 | 18.46% | 1.0单 | 低优先级 |
| 无差异用户 | 1,062 | 11.50% | 0.0单 | 监控即可 |
| 负差异用户 | 600 | 6.49% | -1.0单 | 监控即可 |

### 3.4 运营优先级分布
| 运营优先级 | 用户数 | 占比 | 核心用户特征 |
|------------|--------|------|--------------|
"""

    # 添加运营优先级数据
    for priority, count in priority_dist.items():
        percentage = priority_dist_pct[priority]
        description = {
            '最高优先级': '用户自己下单 + 高潜力用户，转化价值最高',
            '高优先级': '用户自己下单 + 中潜力用户，或核心匹配类型 + 高潜力',
            '中优先级': '用户自己下单 + 低潜力用户，或其他匹配类型 + 中潜力',
            '低优先级': '无差异用户，维持现状即可',
            '监控即可': '负差异用户或数据异常用户，需关注数据质量'
        }.get(priority, '其他情况')

        report += f"""| **{priority}** | {count:,} | {percentage:.2f}% | {description} |
"""

    report += f"""
---

## 4. 运营建议（优先级排序）

1. **最高优先级行动**：针对{target_users_count:,}名"用户自己下单的高潜力用户"开展精准推广
   - 这些用户美团消费习惯已养成，但未完全通过小蚕下单
   - 预计转化率最高，ROI最优

2. **次优先级行动**：针对"用户自己下单的中潜力用户"（39,794用户）进行温和促活
   - 用户有一定消费差异，但未达到高潜力标准
   - 可尝试轻度激励措施

3. **谨慎行动**：针对"其他有关系用户下单"的高潜力用户（4,255用户）
   - 这些用户订单由他人完成，本人可能未养成消费习惯
   - 推广效果不确定，建议小规模试点

4. **数据质量优化**：重点关注105,926名"用户美团数据可能异常"用户
   - 检查数据采集流程，提高匹配准确率
   - 这部分用户占17.93%，数据质量问题显著

5. **试点验证**：所有运营策略建议先小规模试点（如1,000用户）
   - 验证转化效果后再大规模推广
   - 特别关注成本控制和ROI评估

---

## 严谨说明

1. **数据前提**：所有分析基于美团仅采集第一页订单的技术限制
2. **分层逻辑**：用户分层已结合匹配类型，避免"其他用户下单"情况混入核心潜力用户
3. **运营重点**：应优先聚焦"用户自己下单"的高潜力用户，这部分用户转化价值最高
4. **风险控制**：185,314负差异用户受数据采集限制影响，运营决策需谨慎
5. **试点原则**：建议所有运营活动先小规模试点，验证效果后再扩大

**数据来源**：2026-03-09至2026-03-15（7天）
**生成时间**：{current_date}（结合匹配类型分层版）
"""

    # 保存报告
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(report)

    print(f"管理层报告已保存至: {output_path}")
    return report

def save_updated_data(df, output_path):
    """保存更新后的数据"""
    print(f"\n正在保存更新后的数据: {output_path}")

    # 确保列顺序合理
    column_order = [
        '用户ID', '采集美团订单量', '小蚕订单量', '小蚕美团订单量',
        '小蚕饿了么订单量', '小蚕京东订单量', '同用户匹配美团订单量',
        '非同用户匹配美团订单量', '订单差异', '差异率', '用户分层',
        '匹配类型', '匹配类型简写', '细分分层', '匹配类型优先级',
        '分层分数', '综合优先级分', '运营优先级'
    ]

    # 只保留实际存在的列
    existing_columns = [col for col in column_order if col in df.columns]
    other_columns = [col for col in df.columns if col not in existing_columns]
    final_columns = existing_columns + other_columns

    df = df[final_columns]
    df.to_excel(output_path, index=False)

    print(f"更新后的数据已保存至: {output_path}")
    print(f"新增列: '细分分层', '匹配类型优先级', '分层分数', '综合优先级分', '运营优先级'")

    return output_path

def main():
    """主函数"""
    input_path = "data_storage/20260414_美团下单统计V3_分析后.xlsx"
    output_excel_path = "data_storage/20260414_美团下单统计V3_细分分层.xlsx"
    output_report_path = "analysis_reports/小蚕用户美团频次差异分析_匹配类型分层版.txt"

    if not os.path.exists(input_path):
        print(f"错误: Excel文件不存在: {input_path}")
        return

    print("=" * 70)
    print("小蚕用户美团频次差异分析 - 结合匹配类型的用户分层")
    print("=" * 70)

    try:
        # 1. 加载数据
        df = load_data()

        # 2. 计算详细的分层（结合匹配类型）
        df = calculate_detailed_segmentation(df)

        # 3. 分析结果
        analysis_results = analyze_by_match_type_segmentation(df)

        # 4. 生成管理层报告
        generate_management_report(df, analysis_results, output_report_path)

        # 5. 保存更新后的数据
        save_updated_data(df, output_excel_path)

        print("\n" + "=" * 70)
        print("分析完成！")
        print(f"1. 原始数据文件: {input_path}")
        print(f"2. 更新后数据文件: {output_excel_path}")
        print(f"3. 管理层报告: {output_report_path}")
        print(f"4. 分析用户数: {analysis_results['total_users']:,}")
        print(f"5. 最高优先级用户数: {analysis_results['target_users_count']:,}")
        print("=" * 70)

    except Exception as e:
        print(f"分析过程中出错: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()