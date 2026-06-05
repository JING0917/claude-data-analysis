#!/usr/bin/env python3
"""
用户重合度分析模块
分析首页feed流中点击晓晓和小蚕的用户行为差异
"""

import pandas as pd
import numpy as np
from datetime import datetime
import os
import sys

# 添加父目录到路径，以便导入utils
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from scripts.utils import validate_data_columns, calculate_conversion_rate, save_analysis_results

def analyze_user_overlap(user_data):
    """
    分析用户重合度

    参数:
    user_data: 用户级别数据DataFrame，应包含列:
        - user_id: 用户ID
        - activity_type: 活动类型 ('晓晓' 或 '小蚕活动')
        - clc_num: 点击次数
        - order_num: 订单数量 (根据活动类型)

    返回:
    overlap_analysis: 重合度分析结果字典
    """
    print("\n=== 用户重合度分析 ===")

    # 验证数据列
    required_cols = ['user_id', 'activity_type']
    if not validate_data_columns(user_data, required_cols):
        return None

    # 确保activity_type是字符串
    user_data['activity_type'] = user_data['activity_type'].astype(str)

    # 筛选有效用户（有点击行为）
    if 'clc_num' in user_data.columns:
        valid_users = user_data[user_data['clc_num'] > 0]
    else:
        valid_users = user_data.copy()
        print("警告: 数据中缺少clc_num列，无法筛选有点击行为的用户")

    # 统计用户点击行为
    user_activity_summary = valid_users.groupby('user_id').agg({
        'activity_type': lambda x: list(x.unique()),
        'clc_num': 'sum'
    }).reset_index()

    # 添加点击次数列（如果缺失）
    if 'clc_num' not in user_activity_summary.columns:
        user_activity_summary['clc_num'] = 1

    # 分类用户
    user_categories = []

    for _, row in user_activity_summary.iterrows():
        user_id = row['user_id']
        activity_types = row['activity_type']

        if isinstance(activity_types, list):
            has_xiaoxiao = any('晓晓' in str(at) for at in activity_types)
            has_xiaocan = any('小蚕' in str(at) for at in activity_types)
        else:
            has_xiaoxiao = '晓晓' in str(activity_types)
            has_xiaocan = '小蚕' in str(activity_types)

        if has_xiaoxiao and has_xiaocan:
            category = '两者都点击'
        elif has_xiaoxiao:
            category = '只点击晓晓'
        elif has_xiaocan:
            category = '只点击小蚕'
        else:
            category = '其他'

        user_categories.append({
            'user_id': user_id,
            'category': category,
            'has_xiaoxiao': has_xiaoxiao,
            'has_xiaocan': has_xiaocan,
            'click_count': row.get('clc_num', 1)
        })

    user_categories_df = pd.DataFrame(user_categories)

    # 统计各分类用户数量
    category_stats = user_categories_df.groupby('category').agg({
        'user_id': 'count',
        'click_count': 'sum'
    }).rename(columns={'user_id': '用户数'}).reset_index()

    total_users = len(user_categories_df)
    category_stats['用户占比'] = category_stats['用户数'] * 100.0 / total_users
    category_stats['人均点击次数'] = category_stats['click_count'] / category_stats['用户数']

    print("\n用户分类统计:")
    print(category_stats.to_string())

    # 分析各分类用户的转化率（如果有订单数据）
    conversion_analysis = None
    if 'order_num' in user_data.columns:
        # 合并用户分类和订单数据
        user_orders = user_data.groupby('user_id').agg({
            'order_num': 'sum'
        }).reset_index()

        user_categories_with_orders = pd.merge(
            user_categories_df, user_orders, on='user_id', how='left'
        )
        user_categories_with_orders['order_num'] = user_categories_with_orders['order_num'].fillna(0)

        # 按分类计算转化率
        conversion_by_category = user_categories_with_orders.groupby('category').agg({
            'user_id': 'count',
            'click_count': 'sum',
            'order_num': 'sum'
        }).rename(columns={'user_id': '用户数'}).reset_index()

        conversion_by_category['转化率'] = np.where(
            conversion_by_category['click_count'] > 0,
            conversion_by_category['order_num'] * 100.0 / conversion_by_category['click_count'],
            0
        )

        conversion_by_category['下单用户数'] = user_categories_with_orders[
            user_categories_with_orders['order_num'] > 0
        ].groupby('category')['user_id'].count().reindex(conversion_by_category['category']).fillna(0).values

        conversion_by_category['下单用户占比'] = np.where(
            conversion_by_category['用户数'] > 0,
            conversion_by_category['下单用户数'] * 100.0 / conversion_by_category['用户数'],
            0
        )

        print("\n各分类用户转化率分析:")
        print(conversion_by_category.to_string())

        conversion_analysis = conversion_by_category

    # 分析点击晓晓和点击小蚕的用户行为差异
    print("\n=== 用户行为深度分析 ===")

    # 1. 分析点击频次分布
    print("\n1. 点击频次分布:")
    click_distribution = user_categories_df.groupby('category')['click_count'].describe()
    print(click_distribution[['count', 'mean', 'std', 'min', '25%', '50%', '75%', 'max']])

    # 2. 分析用户重合度矩阵
    print("\n2. 用户重合度矩阵:")
    overlap_matrix = pd.crosstab(
        user_categories_df['has_xiaoxiao'],
        user_categories_df['has_xiaocan'],
        margins=True
    )
    print(overlap_matrix)

    # 3. 计算Jaccard相似系数
    xiaoxiao_users = set(user_categories_df[user_categories_df['has_xiaoxiao']]['user_id'])
    xiaocan_users = set(user_categories_df[user_categories_df['has_xiaocan']]['user_id'])

    intersection = len(xiaoxiao_users.intersection(xiaocan_users))
    union = len(xiaoxiao_users.union(xiaocan_users))

    if union > 0:
        jaccard_similarity = intersection / union
        print(f"\n3. Jaccard相似系数: {jaccard_similarity:.4f}")
        print(f"   交集用户数: {intersection:,}")
        print(f"   并集用户数: {union:,}")
        print(f"   晓晓用户数: {len(xiaoxiao_users):,}")
        print(f"   小蚕用户数: {len(xiaocan_users):,}")
    else:
        print("警告: 无法计算Jaccard相似系数")

    # 准备返回结果
    results = {
        'user_categories': user_categories_df,
        'category_stats': category_stats,
        'overlap_matrix': overlap_matrix,
        'jaccard_similarity': jaccard_similarity if union > 0 else 0,
        'intersection_count': intersection,
        'union_count': union,
        'xiaoxiao_user_count': len(xiaoxiao_users),
        'xiaocan_user_count': len(xiaocan_users)
    }

    if conversion_analysis is not None:
        results['conversion_by_category'] = conversion_analysis

    return results

def analyze_user_segmentation(user_data, segment_cols=None):
    """
    分析用户细分群体

    参数:
    user_data: 用户级别数据
    segment_cols: 细分维度列列表

    返回:
    segmentation_analysis: 细分分析结果
    """
    if segment_cols is None:
        segment_cols = ['platform_name', 'app_version']

    print(f"\n=== 用户细分分析 (维度: {segment_cols}) ===")

    results = {}
    available_segments = [col for col in segment_cols if col in user_data.columns]

    for segment_col in available_segments:
        print(f"\n按 {segment_col} 细分:")

        # 统计各细分群体的用户分布
        segment_distribution = user_data.groupby([segment_col, 'activity_type']).agg({
            'user_id': 'nunique'
        }).reset_index()

        # 透视表展示
        pivot_table = segment_distribution.pivot_table(
            index=segment_col,
            columns='activity_type',
            values='user_id',
            fill_value=0
        )

        print("用户分布:")
        print(pivot_table)

        # 计算各细分群体的重合度
        if len(user_data[segment_col].unique()) > 1:
            segment_overlap = pd.crosstab(
                user_data[segment_col],
                user_data['activity_type']
            )
            print(f"\n{segment_col} 与活动类型交叉表:")
            print(segment_overlap)

        results[segment_col] = {
            'distribution': segment_distribution,
            'pivot_table': pivot_table
        }

    return results

def generate_user_overlap_report(results, output_dir=None):
    """
    生成用户重合度分析报告

    参数:
    results: 分析结果字典
    output_dir: 输出目录
    """
    if output_dir is None:
        output_dir = "../reports"

    os.makedirs(output_dir, exist_ok=True)

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    report_path = os.path.join(output_dir, f"user_overlap_report_{timestamp}.md")

    # 提取关键指标
    category_stats = results.get('category_stats', pd.DataFrame())
    conversion_data = results.get('conversion_by_category', pd.DataFrame())

    report_content = f"""# 用户重合度分析报告

**分析时间**: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}
**分析样本**: 共 {results.get('union_count', 0):,} 个用户

---

## 1. 核心发现

### 1.1 用户分类分布
{category_stats.to_markdown(index=False) if not category_stats.empty else "无数据"}

### 1.2 用户重合度
- **Jaccard相似系数**: {results.get('jaccard_similarity', 0):.4f}
- **晓晓用户数**: {results.get('xiaoxiao_user_count', 0):,}
- **小蚕用户数**: {results.get('xiaocan_user_count', 0):,}
- **两者都点击用户数**: {results.get('intersection_count', 0):,}
- **重合用户占比**: {results.get('intersection_count', 0) * 100.0 / max(results.get('union_count', 1), 1):.1f}%

### 1.3 转化率分析
{conversion_data.to_markdown(index=False) if not conversion_data.empty else "无转化数据"}

---

## 2. 业务洞察

### 2.1 用户行为模式
1. **只点击晓晓的用户**: 占比 {category_stats.loc[category_stats['category'] == '只点击晓晓', '用户占比'].values[0] if not category_stats.empty and '只点击晓晓' in category_stats['category'].values else 0:.1f}%
   - [行为特征描述]

2. **只点击小蚕的用户**: 占比 {category_stats.loc[category_stats['category'] == '只点击小蚕', '用户占比'].values[0] if not category_stats.empty and '只点击小蚕' in category_stats['category'].values else 0:.1f}%
   - [行为特征描述]

3. **两者都点击的用户**: 占比 {category_stats.loc[category_stats['category'] == '两者都点击', '用户占比'].values[0] if not category_stats.empty and '两者都点击' in category_stats['category'].values else 0:.1f}%
   - [行为特征描述]

### 2.2 对转化率差异的解释
基于用户重合度分析，晓晓转化率高于小蚕的可能原因:

1. **用户质量差异**: [分析结论]
2. **用户偏好差异**: [分析结论]
3. **流量分配差异**: [分析结论]

---

## 3. 建议措施

### 3.1 针对不同用户群体的策略
1. **只点击晓晓的用户**:
   - [建议措施]

2. **只点击小蚕的用户**:
   - [建议措施]

3. **两者都点击的用户**:
   - [建议措施]

### 3.2 流量优化建议
1. [建议1]
2. [建议2]

### 3.3 进一步分析建议
1. [建议1]
2. [建议2]

---

## 4. 数据说明

- **数据来源**: dws.dws_sr_traffic_homepage_mix_ascribe_d
- **分析周期**: 最近30天
- **用户样本**: 基于点击行为的活跃用户
- **分析方法**: 用户重合度分析、Jaccard相似系数

---

**报告生成**: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}
"""

    # 保存报告
    with open(report_path, 'w', encoding='utf-8') as f:
        f.write(report_content)

    print(f"\n用户重合度分析报告已生成: {report_path}")

    # 保存详细数据
    data_dir = os.path.join(output_dir, "user_overlap_data")
    save_analysis_results(results, data_dir, prefix="user_overlap")

    return report_path

def load_sample_data():
    """
    加载示例数据（用于测试）
    """
    # 创建示例数据
    np.random.seed(42)
    n_users = 1000

    user_ids = np.arange(1, n_users + 1)

    # 模拟用户点击行为
    data = []
    for user_id in user_ids:
        # 决定用户点击哪些活动类型
        click_xiaoxiao = np.random.rand() < 0.3  # 30%用户点击晓晓
        click_xiaocan = np.random.rand() < 0.6   # 60%用户点击小蚕

        if click_xiaoxiao:
            clc_num = np.random.poisson(1.5) + 1
            order_num = np.random.binomial(clc_num, 0.15)  # 15%转化率
            data.append({
                'user_id': user_id,
                'activity_type': '晓晓',
                'clc_num': clc_num,
                'order_num': order_num
            })

        if click_xiaocan:
            clc_num = np.random.poisson(2.0) + 1
            order_num = np.random.binomial(clc_num, 0.10)  # 10%转化率
            data.append({
                'user_id': user_id,
                'activity_type': '小蚕活动',
                'clc_num': clc_num,
                'order_num': order_num
            })

    return pd.DataFrame(data)

def main():
    """主函数"""
    print("=" * 60)
    print("用户重合度分析模块")
    print("=" * 60)

    # 测试模式或实际数据模式
    use_sample = input("使用示例数据测试? (y/n): ").strip().lower() == 'y'

    if use_sample:
        print("使用示例数据进行分析...")
        user_data = load_sample_data()
    else:
        data_path = input("请输入用户数据文件路径: ").strip()
        if not data_path:
            print("错误: 请输入数据文件路径")
            return

        try:
            if data_path.endswith('.csv'):
                user_data = pd.read_csv(data_path)
            elif data_path.endswith(('.xlsx', '.xls')):
                user_data = pd.read_excel(data_path)
            else:
                print("错误: 不支持的文件格式")
                return
        except Exception as e:
            print(f"数据加载失败: {e}")
            return

    print(f"\n加载数据: {len(user_data):,} 行")
    print(f"用户数: {user_data['user_id'].nunique():,}")

    # 执行分析
    overlap_results = analyze_user_overlap(user_data)

    if overlap_results is None:
        print("用户重合度分析失败")
        return

    # 细分分析
    segment_results = analyze_user_segmentation(user_data)

    # 合并结果
    all_results = {**overlap_results, **segment_results}

    # 生成报告
    report_path = generate_user_overlap_report(all_results)

    print(f"\n分析完成!")
    print(f"报告位置: {report_path}")

if __name__ == "__main__":
    main()