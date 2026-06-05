#!/usr/bin/env python3
"""
生成最终钉钉文档格式报告
整合所有分析结果
"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import os
import sys
import json

# 添加路径以便导入其他模块
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from scripts.analyze_feed_conversion import (
    load_and_prepare_data, calculate_conversion_metrics,
    analyze_platform_distribution, analyze_version_distribution,
    analyze_geo_distribution, analyze_funnel_conversion
)
from scripts.analyze_user_overlap import analyze_user_overlap, analyze_user_segmentation
from scripts.utils import save_analysis_results, create_summary_table

def collect_all_analyses(data_path):
    """
    收集所有分析结果

    参数:
    data_path: 数据文件路径

    返回:
    all_results: 所有分析结果的字典
    """
    print("=" * 60)
    print("开始综合分析")
    print("=" * 60)

    all_results = {
        'timestamp': datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        'data_source': data_path
    }

    # 1. 加载数据
    print("\n1. 加载数据...")
    df = load_and_prepare_data(data_path)
    df = calculate_conversion_metrics(df)

    all_results['data_shape'] = df.shape
    all_results['data_columns'] = list(df.columns)

    # 2. 基础统计
    print("\n2. 计算基础统计...")
    basic_stats = {
        '总行数': len(df),
        '活动类型分布': df['activity_type'].value_counts().to_dict(),
        '总点击量': df['clc_num'].sum(),
        '总订单量': df['order_num'].sum(),
        '整体转化率': df['order_num'].sum() * 100.0 / df['clc_num'].sum() if df['clc_num'].sum() > 0 else 0
    }

    # 按活动类型统计
    for activity_type in df['activity_type'].unique():
        subset = df[df['activity_type'] == activity_type]
        basic_stats[f'{activity_type}_点击量'] = subset['clc_num'].sum()
        basic_stats[f'{activity_type}_订单量'] = subset['order_num'].sum()
        basic_stats[f'{activity_type}_转化率'] = subset['order_num'].sum() * 100.0 / subset['clc_num'].sum() if subset['clc_num'].sum() > 0 else 0

    all_results['basic_stats'] = basic_stats

    # 3. 平台分布分析
    print("\n3. 平台分布分析...")
    platform_analysis = analyze_platform_distribution(df)
    if platform_analysis is not None:
        all_results['platform_analysis'] = platform_analysis

    # 4. 版本分布分析
    print("\n4. 版本分布分析...")
    version_analysis = analyze_version_distribution(df)
    if version_analysis is not None:
        all_results['version_analysis'] = version_analysis

    # 5. 地域分布分析
    print("\n5. 地域分布分析...")
    geo_analysis = analyze_geo_distribution(df)
    if geo_analysis is not None:
        all_results['geo_analysis'] = geo_analysis

    # 6. 行为漏斗分析
    print("\n6. 行为漏斗分析...")
    funnel_analysis = analyze_funnel_conversion(df)
    if funnel_analysis is not None:
        all_results['funnel_analysis'] = funnel_analysis

    # 7. 用户重合度分析（需要用户级别数据）
    print("\n7. 用户重合度分析...")
    # 注意：用户重合度分析需要单独的用户级别数据
    # 这里先跳过，后续可以单独处理

    return all_results

def generate_comprehensive_report(results, output_dir=None):
    """
    生成综合分析报告

    参数:
    results: 分析结果字典
    output_dir: 输出目录
    """
    if output_dir is None:
        output_dir = "../reports"

    os.makedirs(output_dir, exist_ok=True)

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    report_path = os.path.join(output_dir, f"comprehensive_analysis_report_{timestamp}.md")

    # 提取关键指标
    basic_stats = results.get('basic_stats', {})
    platform_data = results.get('platform_analysis', pd.DataFrame())
    version_data = results.get('version_analysis', pd.DataFrame())
    geo_data = results.get('geo_analysis', pd.DataFrame())
    funnel_data = results.get('funnel_analysis', pd.DataFrame())

    # 计算核心差异
    xiaoxiao_rate = basic_stats.get('晓晓_转化率', 0)
    xiaocan_rate = basic_stats.get('小蚕活动_转化率', 0)
    rate_diff = xiaoxiao_rate - xiaocan_rate

    # 生成报告内容
    report_content = f"""# 小蚕首页feed流转化率综合分析报告

**分析周期**: 最近30天
**报告日期**: {results.get('timestamp', datetime.now().strftime("%Y-%m-%d"))}
**核心发现**: 晓晓商品卡片转化率比小蚕高 **{rate_diff:.2f}** 个百分点

---

## 1. 核心结论

### 1.1 主要发现
通过分析最近30天首页feed流数据 ({basic_stats.get('总行数', 0):,} 条记录):

1. **整体转化率差异**:
   - 晓晓转化率: **{xiaoxiao_rate:.2f}%** (点击量: {basic_stats.get('晓晓_点击量', 0):,})
   - 小蚕转化率: **{xiaocan_rate:.2f}%** (点击量: {basic_stats.get('小蚕活动_点击量', 0):,})
   - 差异: **{rate_diff:.2f}%** (晓晓高 {abs(rate_diff):.2f} 个百分点)

2. **关键驱动因素**:
   - [基于平台分析的结果]
   - [基于版本分析的结果]
   - [基于地域分析的结果]

3. **业务影响**:
   - [对业务的意义和建议]

### 1.2 立即行动建议
1. **最高优先级**: [针对最显著差异的具体措施]
2. **测试验证**: [建议的AB测试方案]
3. **监控优化**: [建立监控指标]

---

## 2. 详细分析结果

### 2.1 平台分布分析
{platform_data.to_markdown(index=False) if not platform_data.empty else "无平台分析数据"}

**平台差异洞察**:
- iOS: 晓晓转化率比小蚕高 [X]%
- Android: 晓晓转化率比小蚕高 [X]%
- H5: 晓晓转化率比小蚕高 [X]%

### 2.2 版本分布分析
{version_data.to_markdown(index=False) if not version_data.empty else "无版本分析数据"}

**版本差异洞察**:
- 高版本 ([版本号]): 差异最显著
- 低版本 ([版本号]): 差异较小

### 2.3 地域分布分析
{geo_data.head(10).to_markdown(index=False) if not geo_data.empty else "无地域分析数据"}

**地域差异洞察**:
- **高差异区县TOP3**:
  1. [区县ID]: 晓晓[X]% vs 小蚕[Y]% (差异+[Z]%)
  2. [区县ID]: 晓晓[X]% vs 小蚕[Y]% (差异+[Z]%)
  3. [区县ID]: 晓晓[X]% vs 小蚕[Y]% (差异+[Z]%)

### 2.4 行为漏斗分析
{funnel_data.to_markdown(index=False) if not funnel_data.empty else "无漏斗分析数据"}

**漏斗环节差异**:
| 转化环节 | 晓晓转化率 | 小蚕转化率 | 差异 | 关键发现 |
|----------|------------|------------|------|----------|
| 点击→详情页 | [X]% | [Y]% | +[Z]% | [发现] |
| 详情页→报名 | [X]% | [Y]% | +[Z]% | [发现] |
| 整体转化率 | [X]% | [Y]% | +[Z]% | [发现] |

---

## 3. 假设验证总结

### 3.1 假设A: 流量质量差异 ✅/❌
**验证结果**: [验证结果说明]

**证据支持**:
1. [证据1]
2. [证据2]
3. [证据3]

### 3.2 假设B: 商品属性差异 ✅/❌
**验证结果**: [验证结果说明]

**证据支持**:
1. [证据1]
2. [证据2]

### 3.3 假设C: 展示位置效应 ✅/❌
**验证结果**: [验证结果说明]

**证据支持**:
1. [证据1]
2. [证据2]

### 3.4 假设D: 用户群体差异 ✅/❌
**验证结果**: [验证结果说明]

**证据支持**:
1. [证据1]
2. [证据2]

---

## 4. 业务建议

### 4.1 短期优化措施 (1-2周)
1. **流量分配优化**:
   - [具体措施]
   - 预期效果: [预期提升]

2. **商品卡片优化**:
   - [具体措施]
   - 预期效果: [预期提升]

3. **用户体验优化**:
   - [具体措施]
   - 预期效果: [预期提升]

### 4.2 中期策略调整 (1-3个月)
1. **算法策略优化**:
   - [具体措施]
   - 实施计划: [时间安排]

2. **用户分层运营**:
   - [具体措施]
   - 实施计划: [时间安排]

### 4.3 长期战略建议 (3-6个月)
1. **数据体系建设**:
   - [具体措施]
   - 目标: [建设目标]

2. **实验文化建立**:
   - [具体措施]
   - 目标: [建设目标]

---

## 5. 数据质量与限制

### 5.1 数据质量评估
- **数据完整性**: [评估结果]
- **数据准确性**: [评估结果]
- **数据时效性**: [评估结果]

### 5.2 分析限制说明
1. **数据限制**: [具体限制说明]
2. **方法限制**: [具体限制说明]
3. **因果推断限制**: [具体限制说明]

### 5.3 建议的数据优化
1. [优化建议1]
2. [优化建议2]
3. [优化建议3]

---

## 6. 下一步计划

### 6.1 立即执行 (本周内)
1. [任务1]
2. [任务2]

### 6.2 短期跟进 (1个月内)
1. [任务1]
2. [任务2]

### 6.3 长期规划 (季度内)
1. [任务1]
2. [任务2]

---

**数据来源**: dws.dws_sr_traffic_homepage_mix_ascribe_d
**分析周期**: 最近30天 (截止{datetime.now().strftime("%Y-%m-%d")})
**分析方法**: 描述性统计、对比分析、漏斗分析、假设验证
**报告生成**: {results.get('timestamp', datetime.now().strftime("%Y-%m-%d %H:%M:%S"))}

---

## 附录

### A. 关键指标定义
1. **转化率**: 订单量 / 点击量 × 100%
2. **点击量**: 用户点击商品卡片的次数
3. **订单量**: 用户在点击后15分钟内报名的订单数量

### B. 数据提取SQL
```sql
-- 基础数据提取
SELECT statistics_date, county_id, platform_name, app_version, activity_type,
       clc_num, detailpage_pv,
       CASE WHEN activity_type = '小蚕活动' THEN baoming_order_num
            WHEN activity_type = '晓晓' THEN xx_baoming_order_num
            ELSE 0 END AS order_num
FROM dws.dws_sr_traffic_homepage_mix_ascribe_d
WHERE statistics_date >= DATE_SUB(CURRENT_DATE, 30)
  AND activity_type IN ('小蚕活动', '晓晓');
```

### C. 技术实现说明
- **分析工具**: Python + pandas + matplotlib
- **数据处理**: 数据清洗、指标计算、统计分析
- **可视化**: 转化率对比图、地域热力图、漏斗图
- **报告生成**: Markdown格式，适配钉钉文档

**备注**: 本报告基于现有数据分析，实际业务决策请结合更多业务上下文。
"""

    # 保存报告
    with open(report_path, 'w', encoding='utf-8') as f:
        f.write(report_content)

    print(f"\n综合分析报告已生成: {report_path}")

    # 保存分析结果
    data_dir = os.path.join(output_dir, "analysis_data")
    save_analysis_results(results, data_dir, prefix="comprehensive_analysis")

    return report_path

def generate_executive_summary(results, output_dir=None):
    """
    生成管理层摘要报告（更简洁）

    参数:
    results: 分析结果字典
    output_dir: 输出目录
    """
    if output_dir is None:
        output_dir = "../reports"

    os.makedirs(output_dir, exist_ok=True)

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    summary_path = os.path.join(output_dir, f"executive_summary_{timestamp}.md")

    # 提取最关键指标
    basic_stats = results.get('basic_stats', {})

    xiaoxiao_rate = basic_stats.get('晓晓_转化率', 0)
    xiaocan_rate = basic_stats.get('小蚕活动_转化率', 0)
    rate_diff = xiaoxiao_rate - xiaocan_rate

    summary_content = f"""# 晓晓转化率分析 - 管理层摘要

## 核心结论
**晓晓转化率比小蚕高 {rate_diff:.2f}个百分点** ({xiaoxiao_rate:.2f}% vs {xiaocan_rate:.2f}%)

## 关键发现
1. **整体差异**: {rate_diff:.2f}个百分点
2. **主要驱动因素**:
   - 平台差异: [iOS/Android差异]
   - 地域差异: [高差异区县]
   - 用户差异: [用户质量差异]

## 立即行动建议
1. **优先优化**: [最重要的一项措施]
2. **测试验证**: [建议的测试方案]
3. **监控指标**: [需要监控的关键指标]

## 预期收益
- **短期** (1个月): 预计提升转化率 [X]%
- **中期** (3个月): 预计提升转化率 [Y]%
- **长期** (6个月): 建立优化机制

## 风险与应对
- **主要风险**: [风险描述]
- **应对措施**: [应对方案]

---

**分析周期**: 最近30天
**数据样本**: {basic_stats.get('总行数', 0):,} 条记录
**报告日期**: {datetime.now().strftime("%Y-%m-%d")}
**建议跟进**: [建议跟进人/团队]
"""

    with open(summary_path, 'w', encoding='utf-8') as f:
        f.write(summary_content)

    print(f"管理层摘要已生成: {summary_path}")
    return summary_path

def main():
    """主函数"""
    print("=" * 60)
    print("综合分析报告生成工具")
    print("=" * 60)

    # 获取数据路径
    data_path = input("请输入聚合数据文件路径: ").strip()
    if not data_path:
        print("错误: 请输入数据文件路径")
        return

    if not os.path.exists(data_path):
        print(f"错误: 文件不存在 {data_path}")
        return

    # 执行分析
    try:
        results = collect_all_analyses(data_path)
    except Exception as e:
        print(f"分析过程出错: {e}")
        import traceback
        traceback.print_exc()
        return

    # 生成报告
    print("\n" + "=" * 60)
    print("生成报告中...")

    comprehensive_report = generate_comprehensive_report(results)
    executive_summary = generate_executive_summary(results)

    print("\n" + "=" * 60)
    print("报告生成完成!")
    print(f"详细报告: {comprehensive_report}")
    print(f"管理层摘要: {executive_summary}")
    print("=" * 60)

if __name__ == "__main__":
    main()