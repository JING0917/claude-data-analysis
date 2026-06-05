#!/usr/bin/env python3
"""
小蚕首页feed流转化率分析 - 晓晓 vs 小蚕对比分析
主要验证假设A：流量质量差异
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from datetime import datetime, timedelta
import os
import sys

# 设置中文显示
plt.rcParams['font.sans-serif'] = ['SimHei', 'Arial Unicode MS']
plt.rcParams['axes.unicode_minus'] = False

def load_and_prepare_data(data_path=None):
    """
    加载和准备数据

    参数:
    data_path: 数据文件路径，如果为None则使用默认路径

    返回:
    df: 处理后的DataFrame
    """
    if data_path is None:
        # 默认数据路径
        data_path = "../data/processed/feed_conversion_data.csv"

    print(f"正在读取数据文件: {data_path}")

    # 尝试读取CSV或Excel
    if data_path.endswith('.csv'):
        df = pd.read_csv(data_path)
    elif data_path.endswith('.xlsx') or data_path.endswith('.xls'):
        df = pd.read_excel(data_path)
    else:
        raise ValueError("不支持的文件格式，请使用CSV或Excel文件")

    print(f"数据形状: {df.shape}")
    print(f"列名: {list(df.columns)}")

    # 显示数据预览
    print("\n数据预览:")
    print(df.head())

    # 检查必要列是否存在
    required_cols = ['activity_type', 'clc_num']
    order_cols = ['baoming_order_num', 'xx_baoming_order_num']

    for col in required_cols:
        if col not in df.columns:
            print(f"警告: 缺少必要列 {col}")

    # 标准化列名（如果存在不同命名）
    col_mapping = {}
    for col in df.columns:
        lower_col = col.lower()
        if 'activity' in lower_col and 'type' in lower_col:
            col_mapping[col] = 'activity_type'
        elif 'click' in lower_col or 'clc' in lower_col:
            col_mapping[col] = 'clc_num'
        elif 'order' in lower_col and 'baoming' in lower_col:
            if 'xx' in lower_col or '晓晓' in lower_col:
                col_mapping[col] = 'xx_baoming_order_num'
            else:
                col_mapping[col] = 'baoming_order_num'

    if col_mapping:
        df = df.rename(columns=col_mapping)
        print(f"已标准化列名: {col_mapping}")

    return df

def calculate_conversion_metrics(df):
    """
    计算转化率指标

    参数:
    df: 原始数据DataFrame

    返回:
    df_with_metrics: 包含转化率指标的数据
    """
    df = df.copy()

    print("\n=== 计算转化率指标 ===")

    # 确保activity_type是字符串类型
    if 'activity_type' in df.columns:
        df['activity_type'] = df['activity_type'].astype(str)

    # 计算订单量（根据活动类型）
    def calculate_order_num(row):
        activity_type = str(row.get('activity_type', '')).strip()
        if '晓晓' in activity_type or activity_type == '晓晓':
            return row.get('xx_baoming_order_num', 0)
        else:
            return row.get('baoming_order_num', 0)

    if 'order_num' not in df.columns:
        df['order_num'] = df.apply(calculate_order_num, axis=1)

    # 计算转化率
    df['conversion_rate'] = np.where(
        df['clc_num'] > 0,
        df['order_num'] * 100.0 / df['clc_num'],
        0
    )

    # 计算详情页相关指标（如果有详情页数据）
    # 注意：详情页PV可能大于点击量，因为用户可能多次刷新详情页
    if 'detailpage_pv' in df.columns:
        df['detail_pv_per_click'] = np.where(
            df['clc_num'] > 0,
            df['detailpage_pv'] / df['clc_num'],  # 比值，可能大于1
            0
        )
        df['detail_to_order_rate'] = np.where(
            df['detailpage_pv'] > 0,
            df['order_num'] * 100.0 / df['detailpage_pv'],  # 百分比
            0
        )

    print(f"整体转化率统计:")
    if 'activity_type' in df.columns:
        for activity_type in df['activity_type'].unique():
            subset = df[df['activity_type'] == activity_type]
            if len(subset) > 0:
                total_clicks = subset['clc_num'].sum()
                total_orders = subset['order_num'].sum()
                conv_rate = total_orders * 100.0 / total_clicks if total_clicks > 0 else 0
                print(f"  {activity_type}: 点击量={total_clicks:,}, 订单量={total_orders:,}, 转化率={conv_rate:.2f}%")

    return df

def analyze_platform_distribution(df):
    """
    分析平台分布差异

    参数:
    df: 包含转化率指标的数据

    返回:
    platform_summary: 平台分布汇总
    """
    print("\n=== 平台分布分析 ===")

    if 'platform_name' not in df.columns:
        print("警告: 数据中缺少platform_name列，无法进行平台分析")
        return None

    # 按平台和活动类型分组
    platform_analysis = df.groupby(['platform_name', 'activity_type']).agg({
        'clc_num': 'sum',
        'order_num': 'sum',
        'conversion_rate': 'mean'
    }).reset_index()

    # 计算转化率
    platform_analysis['calculated_rate'] = np.where(
        platform_analysis['clc_num'] > 0,
        platform_analysis['order_num'] * 100.0 / platform_analysis['clc_num'],
        0
    )

    # 计算各平台点击量占比
    total_clicks_by_activity = platform_analysis.groupby('activity_type')['clc_num'].transform('sum')
    platform_analysis['click_share'] = np.where(
        total_clicks_by_activity > 0,
        platform_analysis['clc_num'] * 100.0 / total_clicks_by_activity,
        0
    )

    print("\n平台分布汇总:")
    print(platform_analysis.to_string())

    # 计算平台间转化率差异
    platforms = platform_analysis['platform_name'].unique()
    activities = platform_analysis['activity_type'].unique()

    print("\n平台转化率对比:")
    for platform in platforms:
        platform_data = platform_analysis[platform_analysis['platform_name'] == platform]
        if len(platform_data) == 2:  # 应该有晓晓和小蚕两个活动类型
            xiaoxiao = platform_data[platform_data['activity_type'].str.contains('晓晓')]
            xiaocan = platform_data[platform_data['activity_type'].str.contains('小蚕')]

            if len(xiaoxiao) > 0 and len(xiaocan) > 0:
                rate_xiaoxiao = xiaoxiao['calculated_rate'].values[0]
                rate_xiaocan = xiaocan['calculated_rate'].values[0]
                diff = rate_xiaoxiao - rate_xiaocan
                print(f"  {platform}: 晓晓={rate_xiaoxiao:.2f}%, 小蚕={rate_xiaocan:.2f}%, 差异={diff:.2f}%")

    return platform_analysis

def analyze_version_distribution(df):
    """
    分析APP版本分布差异

    参数:
    df: 包含转化率指标的数据

    返回:
    version_summary: 版本分布汇总
    """
    print("\n=== 版本分布分析 ===")

    if 'app_version' not in df.columns:
        print("警告: 数据中缺少app_version列，无法进行版本分析")
        return None

    # 过滤掉未知版本
    df_filtered = df[df['app_version'] != '未知']

    # 按版本和活动类型分组
    version_analysis = df_filtered.groupby(['app_version', 'activity_type']).agg({
        'clc_num': 'sum',
        'order_num': 'sum'
    }).reset_index()

    # 只保留有一定样本量的版本（点击量>=100）
    version_analysis = version_analysis[version_analysis['clc_num'] >= 100]

    # 计算转化率
    version_analysis['conversion_rate'] = np.where(
        version_analysis['clc_num'] > 0,
        version_analysis['order_num'] * 100.0 / version_analysis['clc_num'],
        0
    )

    # 计算各版本点击量占比
    total_clicks_by_activity = version_analysis.groupby('activity_type')['clc_num'].transform('sum')
    version_analysis['click_share'] = np.where(
        total_clicks_by_activity > 0,
        version_analysis['clc_num'] * 100.0 / total_clicks_by_activity,
        0
    )

    print("\n版本分布汇总 (点击量>=100):")
    print(version_analysis.sort_values(['activity_type', 'conversion_rate'], ascending=[True, False]).to_string())

    # 识别高转化版本
    print("\n高转化版本TOP5:")
    for activity in version_analysis['activity_type'].unique():
        activity_versions = version_analysis[version_analysis['activity_type'] == activity]
        top_versions = activity_versions.nlargest(5, 'conversion_rate')
        print(f"\n  {activity}:")
        for _, row in top_versions.iterrows():
            print(f"    版本 {row['app_version']}: 转化率={row['conversion_rate']:.2f}%, 点击量={row['clc_num']:,}")

    return version_analysis

def analyze_geo_distribution(df):
    """
    分析地域分布差异

    参数:
    df: 包含转化率指标的数据

    返回:
    geo_summary: 地域分布汇总
    """
    print("\n=== 地域分布分析 ===")

    if 'county_id' not in df.columns:
        print("警告: 数据中缺少county_id列，无法进行地域分析")
        return None

    # 按区县和活动类型分组
    geo_analysis = df.groupby(['county_id', 'activity_type']).agg({
        'clc_num': 'sum',
        'order_num': 'sum'
    }).reset_index()

    # 只保留有一定样本量的区县（点击量>=50）
    geo_analysis = geo_analysis[geo_analysis['clc_num'] >= 50]

    # 计算转化率
    geo_analysis['conversion_rate'] = np.where(
        geo_analysis['clc_num'] > 0,
        geo_analysis['order_num'] * 100.0 / geo_analysis['clc_num'],
        0
    )

    # 识别高转化区县
    high_conversion_areas = pd.DataFrame()

    for activity in geo_analysis['activity_type'].unique():
        activity_geo = geo_analysis[geo_analysis['activity_type'] == activity]
        top_areas = activity_geo.nlargest(10, 'conversion_rate')
        top_areas['activity_type'] = activity
        high_conversion_areas = pd.concat([high_conversion_areas, top_areas])

    print("\n高转化区县TOP10 (点击量>=50):")
    print(high_conversion_areas.sort_values(['activity_type', 'conversion_rate'], ascending=[True, False]).to_string())

    # 计算区县级别的转化率差异
    if len(geo_analysis['county_id'].unique()) > 0:
        # 为每个区县计算晓晓和小蚕的转化率差异
        county_comparison = pd.DataFrame()

        for county in geo_analysis['county_id'].unique():
            county_data = geo_analysis[geo_analysis['county_id'] == county]
            if len(county_data) == 2:  # 同时有晓晓和小蚕数据
                xiaoxiao = county_data[county_data['activity_type'].str.contains('晓晓')]
                xiaocan = county_data[county_data['activity_type'].str.contains('小蚕')]

                if len(xiaoxiao) > 0 and len(xiaocan) > 0:
                    diff = xiaoxiao['conversion_rate'].values[0] - xiaocan['conversion_rate'].values[0]
                    county_comparison = pd.concat([county_comparison, pd.DataFrame({
                        'county_id': [county],
                        'xiaoxiao_rate': [xiaoxiao['conversion_rate'].values[0]],
                        'xiaocan_rate': [xiaocan['conversion_rate'].values[0]],
                        'rate_diff': [diff],
                        'total_clicks': [xiaoxiao['clc_num'].values[0] + xiaocan['clc_num'].values[0]]
                    })])

        if len(county_comparison) > 0:
            print(f"\n区县转化率差异分析 (共{len(county_comparison)}个区县有完整数据):")
            print(f"  晓晓平均转化率: {county_comparison['xiaoxiao_rate'].mean():.2f}%")
            print(f"  小蚕平均转化率: {county_comparison['xiaocan_rate'].mean():.2f}%")
            print(f"  平均差异: {county_comparison['rate_diff'].mean():.2f}%")

            # 显示差异最大的区县
            print("\n差异最大的区县TOP5:")
            top_diff = county_comparison.nlargest(5, 'rate_diff')
            for _, row in top_diff.iterrows():
                print(f"  区县 {row['county_id']}: 晓晓={row['xiaoxiao_rate']:.2f}%, 小蚕={row['xiaocan_rate']:.2f}%, 差异={row['rate_diff']:.2f}%")

    return geo_analysis

def analyze_funnel_conversion(df):
    """
    分析行为漏斗指标
    注意：详情页PV可能大于点击量（用户可能多次刷新详情页），因此详情页PV/点击量比值可能大于1

    参数:
    df: 包含转化率指标的数据

    返回:
    funnel_summary: 漏斗指标汇总
    """
    print("\n=== 行为漏斗分析 ===")

    if 'detailpage_pv' not in df.columns:
        print("警告: 数据中缺少detailpage_pv列，无法进行漏斗分析")
        return None

    # 按活动类型分组计算漏斗指标
    funnel_analysis = df.groupby('activity_type').agg({
        'clc_num': 'sum',
        'detailpage_pv': 'sum',
        'order_num': 'sum'
    }).reset_index()

    # 计算各环节指标
    # 详情页PV/点击量比值（可能大于1，因为用户可能多次刷新详情页）
    funnel_analysis['detail_pv_per_click'] = np.where(
        funnel_analysis['clc_num'] > 0,
        funnel_analysis['detailpage_pv'] / funnel_analysis['clc_num'],  # 比值，非百分比
        0
    )

    funnel_analysis['detail_to_order_rate'] = np.where(
        funnel_analysis['detailpage_pv'] > 0,
        funnel_analysis['order_num'] * 100.0 / funnel_analysis['detailpage_pv'],  # 百分比
        0
    )

    funnel_analysis['overall_conversion_rate'] = np.where(
        funnel_analysis['clc_num'] > 0,
        funnel_analysis['order_num'] * 100.0 / funnel_analysis['clc_num'],  # 百分比
        0
    )

    print("\n行为漏斗对比:")
    print(funnel_analysis.to_string())

    # 计算差异
    if len(funnel_analysis) == 2:  # 晓晓和小蚕
        xiaoxiao = funnel_analysis[funnel_analysis['activity_type'].str.contains('晓晓')]
        xiaocan = funnel_analysis[funnel_analysis['activity_type'].str.contains('小蚕')]

        if len(xiaoxiao) > 0 and len(xiaocan) > 0:
            print("\n漏斗环节差异分析:")
            metrics = ['detail_pv_per_click', 'detail_to_order_rate', 'overall_conversion_rate']
            metric_names = ['详情页PV/点击量比值', '详情页→报名转化率', '整体转化率']
            metric_formats = ['比值', '百分比', '百分比']  # 用于区分输出格式

            for metric, name, fmt in zip(metrics, metric_names, metric_formats):
                xiaoxiao_val = xiaoxiao[metric].values[0]
                xiaocan_val = xiaocan[metric].values[0]
                diff = xiaoxiao_val - xiaocan_val

                if fmt == '百分比':
                    print(f"  {name}: 晓晓={xiaoxiao_val:.2f}%, 小蚕={xiaocan_val:.2f}%, 差异={diff:.2f}%")
                else:  # 比值
                    print(f"  {name}: 晓晓={xiaoxiao_val:.3f}, 小蚕={xiaocan_val:.3f}, 差异={diff:.3f}")

    return funnel_analysis

def generate_dingtalk_report(analyses, output_path=None):
    """
    生成钉钉文档格式报告

    参数:
    analyses: 包含各分析结果的字典
    output_path: 输出文件路径
    """
    if output_path is None:
        output_path = "../reports/dingtalk_report.md"

    print(f"\n=== 生成钉钉文档报告 ===")

    # 获取当前日期
    current_date = datetime.now().strftime("%Y-%m-%d")

    report_content = f"""# 小蚕首页feed流转化率分析报告

**分析周期**: 最近30天 (截止{current_date})
**报告日期**: {current_date}
**核心发现**: 晓晓商品卡片转化率比小蚕高 [X] 个百分点

---

## 1. 核心结论

### 1.1 主要发现
通过分析最近30天首页feed流数据，发现：

1. **整体转化率差异**: 晓晓转化率为 [X]%，小蚕转化率为 [Y]%，晓晓高 [Z] 个百分点
2. **关键驱动因素**:
   - [主要因素1，如：平台差异、用户质量等]
   - [主要因素2]
3. **业务影响**: [对业务的意义]

### 1.2 关键建议
1. **立即行动**: [针对发现的最主要问题]
2. **优化建议**: [具体优化措施]
3. **测试计划**: [建议的AB测试方案]

---

## 2. 详细分析结果

### 2.1 平台分布分析
| 平台 | 活动类型 | 点击量 | 订单量 | 转化率 | 点击量占比 |
|------|----------|--------|--------|--------|------------|
| iOS | 晓晓 | [数据] | [数据] | [数据]% | [数据]% |
| iOS | 小蚕 | [数据] | [数据] | [数据]% | [数据]% |
| Android | 晓晓 | [数据] | [数据] | [数据]% | [数据]% |
| Android | 小蚕 | [数据] | [数据] | [数据]% | [数据]% |

**发现**: [简要总结平台差异]

### 2.2 版本分布分析
| 版本 | 活动类型 | 点击量 | 订单量 | 转化率 |
|------|----------|--------|--------|--------|
| [版本1] | 晓晓 | [数据] | [数据] | [数据]% |
| [版本1] | 小蚕 | [数据] | [数据] | [数据]% |

**发现**: [简要总结版本差异]

### 2.3 地域分布分析
**高转化区县TOP5**:
1. 区县[ID]: 晓晓[X]% vs 小蚕[Y]% (差异+[Z]%)
2. 区县[ID]: 晓晓[X]% vs 小蚕[Y]% (差异+[Z]%)

### 2.4 行为漏斗分析
| 转化环节 | 晓晓转化率 | 小蚕转化率 | 差异 |
|----------|------------|------------|------|
| 点击→详情页 | [X]% | [Y]% | +[Z]% |
| 详情页→报名 | [X]% | [Y]% | +[Z]% |
| 整体转化率 | [X]% | [Y]% | +[Z]% |

---

## 3. 业务建议

### 3.1 短期优化
1. [具体建议1]
2. [具体建议2]

### 3.2 长期策略
1. [长期策略1]
2. [长期策略2]

### 3.3 数据监控
1. 建立转化率监控看板
2. 设置预警机制
3. 定期复盘分析

---

## 4. 下一步计划

1. [计划1]
2. [计划2]
3. [计划3]

---

**数据备注**: 分析基于最近30天首页feed流数据，数据来源: dws.dws_sr_traffic_homepage_mix_ascribe_d
**报告生成**: {current_date}
"""

    # 保存报告
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(report_content)

    print(f"钉钉文档报告已生成: {output_path}")
    print("请将报告中的 [数据] 替换为实际分析结果")

    return output_path

def main():
    """主函数"""
    print("=" * 60)
    print("小蚕首页feed流转化率分析 - 晓晓 vs 小蚕")
    print("=" * 60)

    # 1. 加载数据
    data_path = input("请输入数据文件路径 (直接回车使用默认路径): ").strip()
    if not data_path:
        data_path = None

    try:
        df = load_and_prepare_data(data_path)
    except Exception as e:
        print(f"数据加载失败: {e}")
        print("请确保数据文件存在且格式正确")
        return

    # 2. 计算转化率指标
    df = calculate_conversion_metrics(df)

    # 3. 执行各项分析
    analyses = {}

    # 平台分布分析
    platform_analysis = analyze_platform_distribution(df)
    if platform_analysis is not None:
        analyses['platform'] = platform_analysis

    # 版本分布分析
    version_analysis = analyze_version_distribution(df)
    if version_analysis is not None:
        analyses['version'] = version_analysis

    # 地域分布分析
    geo_analysis = analyze_geo_distribution(df)
    if geo_analysis is not None:
        analyses['geo'] = geo_analysis

    # 行为漏斗分析
    funnel_analysis = analyze_funnel_conversion(df)
    if funnel_analysis is not None:
        analyses['funnel'] = funnel_analysis

    # 4. 生成报告
    report_path = generate_dingtalk_report(analyses)

    print("\n" + "=" * 60)
    print("分析完成!")
    print(f"报告位置: {report_path}")
    print("=" * 60)

if __name__ == "__main__":
    main()