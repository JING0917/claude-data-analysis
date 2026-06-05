#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
小蚕霸王餐魔法数字分析脚本
识别影响用户访问留存的关键行为阈值

功能：
1. 模拟用户行为数据生成（用于演示）
2. 分析行为频率与留存率关系
3. 探索魔法数字阈值
4. 可视化分析结果
5. 生成分析报告

使用方法：
python 小蚕魔法数字分析.py --mode simulate  # 模拟数据并分析
python 小蚕魔法数字分析.py --mode analyze --data_path real_data.csv  # 分析真实数据
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from datetime import datetime, timedelta
import argparse
import json
from typing import Dict, List, Tuple, Optional
import warnings
warnings.filterwarnings('ignore')

# 设置中文字体（如果系统支持）
try:
    plt.rcParams['font.sans-serif'] = ['SimHei', 'Arial Unicode MS', 'DejaVu Sans']
    plt.rcParams['axes.unicode_minus'] = False
except:
    pass

class MagicNumberAnalyzer:
    """魔法数字分析器"""

    def __init__(self, data_path: Optional[str] = None):
        """
        初始化分析器

        Parameters:
        -----------
        data_path : str, optional
            真实数据文件路径，如果为None则使用模拟数据
        """
        self.data_path = data_path
        self.behavior_data = None
        self.retention_data = None
        self.user_cohorts = None
        self.analysis_results = {}

        # 定义关键行为类型（基于小蚕业务）
        self.behavior_types = {
            # 首页营销活动点击
            'click_header_banner': '头图区活动点击',
            'click_golden_area': '金刚区入口点击',
            'join_challenge': '挑战赛报名',
            'get_platform_coupon': '平台红包领取',
            'join_community': '社群入口点击',

            # 筛选功能使用
            'filter_distance': '距离筛选',
            'filter_high_rebate': '高返利筛选',
            'filter_no_review': '无需评价筛选',
            'filter_brand': '大牌商家筛选',

            # 商品详情页查看
            'view_detail_page': '详情页查看',

            # 搜索行为
            'search_query': '搜索行为',

            # 综合行为
            'total_clicks': '总点击次数',
            'unique_modules': '访问模块数'
        }

    def generate_simulated_data(self, n_users: int = 10000, days: int = 30) -> None:
        """
        生成模拟用户行为数据

        Parameters:
        -----------
        n_users : int
            模拟用户数量
        days : int
            模拟天数
        """
        print(f"生成模拟数据: {n_users}用户, {days}天")

        # 生成用户ID
        user_ids = np.arange(1, n_users + 1)

        # 生成用户首次访问日期（最近30天内均匀分布）
        start_date = datetime.now() - timedelta(days=days)
        cohort_dates = [
            start_date + timedelta(days=np.random.randint(0, days))
            for _ in range(n_users)
        ]

        # 生成行为数据
        behavior_records = []
        retention_records = []

        for i, user_id in enumerate(user_ids):
            cohort_date = cohort_dates[i]

            # 用户基础留存概率（模拟真实分布）
            base_retention_prob = np.random.beta(2, 5)  # 大部分用户留存率较低

            # 生成每日行为
            for day_offset in range(min(7, days)):  # 只生成前7天行为（对留存影响最大）
                event_date = cohort_date + timedelta(days=day_offset)

                # 决定用户当天是否活跃（基于留存概率）
                if day_offset == 0:
                    is_active = True  # 首日100%活跃
                else:
                    is_active = np.random.random() < (base_retention_prob * (0.9 ** day_offset))

                if not is_active:
                    continue

                # 生成当日行为次数（泊松分布）
                n_events = np.random.poisson(lam=3) + 1  # 平均3次，至少1次

                for _ in range(n_events):
                    # 选择行为类型（加权概率）
                    behavior_weights = {
                        'click_header_banner': 0.15,
                        'click_golden_area': 0.20,
                        'view_detail_page': 0.25,
                        'filter_distance': 0.10,
                        'filter_high_rebate': 0.08,
                        'search_query': 0.12,
                        'join_challenge': 0.05,
                        'get_platform_coupon': 0.05
                    }

                    behavior_type = np.random.choice(
                        list(behavior_weights.keys()),
                        p=list(behavior_weights.values())
                    )

                    # 生成事件时间（在当天内随机）
                    event_time = event_date + timedelta(
                        hours=np.random.randint(10, 20),  # 10点-20点
                        minutes=np.random.randint(0, 60),
                        seconds=np.random.randint(0, 60)
                    )

                    # 生成停留时长（秒）
                    duration = np.random.exponential(scale=30) + 5  # 平均35秒

                    behavior_records.append({
                        'user_id': user_id,
                        'event_date': event_date.date(),
                        'event_time': event_time,
                        'event_type': behavior_type,
                        'event_name': self.behavior_types.get(behavior_type, behavior_type),
                        'duration_seconds': int(duration)
                    })

            # 生成留存状态（基于行为次数）
            # 计算前3天总行为次数
            first_3_days_events = [r for r in behavior_records
                                  if r['user_id'] == user_id
                                  and (r['event_date'] - cohort_date.date()).days < 3]

            total_events_first_3_days = len(first_3_days_events)

            # 留存概率与行为次数正相关
            retention_multiplier = 1 + (total_events_first_3_days / 20)  # 每20次行为增加100%留存概率

            # 生成留存状态
            for retention_day in [1, 2, 7, 30]:
                if retention_day > days:
                    continue

                retention_date = cohort_date + timedelta(days=retention_day)

                # 计算该日留存概率
                if retention_day == 1:
                    day_retention_prob = min(0.95, base_retention_prob * retention_multiplier * 1.5)
                elif retention_day == 2:
                    day_retention_prob = min(0.85, base_retention_prob * retention_multiplier * 1.2)
                elif retention_day == 7:
                    day_retention_prob = min(0.60, base_retention_prob * retention_multiplier * 0.8)
                else:  # 30天
                    day_retention_prob = min(0.30, base_retention_prob * retention_multiplier * 0.5)

                is_active = np.random.random() < day_retention_prob

                retention_records.append({
                    'user_id': user_id,
                    'cohort_date': cohort_date.date(),
                    'retention_day': retention_day,
                    'is_active': is_active,
                    'total_events_first_3_days': total_events_first_3_days
                })

        # 创建DataFrame
        self.behavior_data = pd.DataFrame(behavior_records)
        self.retention_data = pd.DataFrame(retention_records)

        # 创建用户队列数据
        self.user_cohorts = pd.DataFrame({
            'user_id': user_ids,
            'cohort_date': [d.date() for d in cohort_dates]
        })

        print(f"模拟数据生成完成:")
        print(f"  行为记录数: {len(self.behavior_data)}")
        print(f"  用户数: {n_users}")
        print(f"  留存记录数: {len(self.retention_data)}")

    def load_real_data(self) -> None:
        """
        加载真实数据
        """
        if not self.data_path:
            raise ValueError("请提供数据文件路径")

        print(f"加载真实数据: {self.data_path}")

        # 这里需要根据实际数据格式调整
        # 假设数据为CSV格式
        try:
            self.behavior_data = pd.read_csv(self.data_path)
            print(f"行为数据加载成功: {len(self.behavior_data)}条记录")
        except Exception as e:
            print(f"加载行为数据失败: {e}")
            raise

        # 这里需要根据实际情况加载留存数据或计算留存
        # 暂时使用模拟留存数据
        self.generate_retention_from_behavior()

    def generate_retention_from_behavior(self) -> None:
        """
        从行为数据生成留存数据（当没有留存数据时使用）
        """
        print("从行为数据生成留存状态...")

        if self.behavior_data is None or len(self.behavior_data) == 0:
            raise ValueError("行为数据为空")

        # 获取用户首次访问日期
        user_first_date = self.behavior_data.groupby('user_id')['event_date'].min()

        retention_records = []

        for user_id, first_date in user_first_date.items():
            # 获取用户的所有活跃日期
            user_dates = set(self.behavior_data[
                self.behavior_data['user_id'] == user_id
            ]['event_date'].unique())

            # 计算留存状态
            for retention_day in [1, 2, 7, 30]:
                retention_date = first_date + timedelta(days=retention_day)

                # 检查用户在该日期是否活跃
                is_active = retention_date in user_dates

                retention_records.append({
                    'user_id': user_id,
                    'cohort_date': first_date,
                    'retention_day': retention_day,
                    'is_active': is_active
                })

        self.retention_data = pd.DataFrame(retention_records)
        self.user_cohorts = pd.DataFrame({
            'user_id': user_first_date.index,
            'cohort_date': user_first_date.values
        })

        print(f"留存数据生成完成: {len(self.retention_data)}条记录")

    def calculate_behavior_frequencies(self) -> pd.DataFrame:
        """
        计算用户行为频率
        """
        print("计算用户行为频率...")

        if self.behavior_data is None:
            raise ValueError("行为数据未加载")

        # 按用户和行为类型分组计数
        behavior_counts = self.behavior_data.groupby(
            ['user_id', 'event_type']
        ).size().unstack(fill_value=0)

        # 添加总点击次数
        behavior_counts['total_clicks'] = behavior_counts.sum(axis=1)

        # 计算访问模块数（独特行为类型数）
        unique_behaviors = self.behavior_data.groupby('user_id')['event_type'].nunique()
        behavior_counts['unique_modules'] = behavior_counts.index.map(
            lambda x: unique_behaviors.get(x, 0)
        )

        # 填充缺失的行为类型为0
        for behavior in self.behavior_types.keys():
            if behavior not in behavior_counts.columns:
                behavior_counts[behavior] = 0

        return behavior_counts

    def analyze_single_behavior(self, behavior_type: str,
                               retention_day: int = 7) -> Dict:
        """
        分析单个行为对留存的影响

        Parameters:
        -----------
        behavior_type : str
            行为类型
        retention_day : int
            留存天数（如7表示7日留存）

        Returns:
        --------
        dict: 分析结果
        """
        print(f"分析行为: {behavior_type} -> {retention_day}日留存")

        # 获取行为频率
        behavior_counts = self.calculate_behavior_frequencies()

        # 获取留存状态
        retention_status = self.retention_data[
            self.retention_data['retention_day'] == retention_day
        ].set_index('user_id')['is_active']

        # 合并数据
        analysis_data = pd.DataFrame({
            'behavior_count': behavior_counts.get(behavior_type, 0),
            'is_retained': retention_status
        }).fillna(0)

        # 移除从未展示该行为的用户（如果没有该行为列）
        if behavior_type not in behavior_counts.columns:
            print(f"警告: 行为类型 {behavior_type} 在数据中不存在")
            return {}

        # 分析不同行为次数分组的留存率
        thresholds = [0, 1, 2, 3, 4, 5, 7, 10, 15, 20]
        results = []

        for i in range(len(thresholds) - 1):
            low_thresh = thresholds[i]
            high_thresh = thresholds[i + 1]

            if i == len(thresholds) - 2:  # 最后一组
                mask = analysis_data['behavior_count'] >= low_thresh
                group_name = f'≥{low_thresh}'
            else:
                mask = (analysis_data['behavior_count'] >= low_thresh) & \
                       (analysis_data['behavior_count'] < high_thresh)
                group_name = f'{low_thresh}-{high_thresh-1}'

            group_data = analysis_data[mask]

            if len(group_data) > 0:
                retention_rate = group_data['is_retained'].mean()
                user_count = len(group_data)

                results.append({
                    'threshold': group_name,
                    'user_count': user_count,
                    'retention_rate': retention_rate,
                    'avg_behavior_count': group_data['behavior_count'].mean()
                })

        # 寻找魔法数字（留存率显著提升的点）
        magic_numbers = []
        if len(results) > 1:
            for i in range(1, len(results)):
                prev_retention = results[i-1]['retention_rate']
                curr_retention = results[i]['retention_rate']
                retention_increase = curr_retention - prev_retention

                # 如果留存率提升超过5个百分点，且用户数足够
                if retention_increase > 0.05 and results[i]['user_count'] > 50:
                    magic_numbers.append({
                        'threshold': results[i]['threshold'],
                        'retention_increase': retention_increase,
                        'baseline_retention': prev_retention,
                        'target_retention': curr_retention,
                        'user_count': results[i]['user_count']
                    })

        # 计算相关性
        correlation = analysis_data['behavior_count'].corr(analysis_data['is_retained'])

        return {
            'behavior_type': behavior_type,
            'behavior_name': self.behavior_types.get(behavior_type, behavior_type),
            'retention_day': retention_day,
            'total_users': len(analysis_data),
            'correlation': correlation,
            'threshold_analysis': results,
            'magic_numbers': magic_numbers,
            'summary_stats': {
                'mean': analysis_data['behavior_count'].mean(),
                'median': analysis_data['behavior_count'].median(),
                'std': analysis_data['behavior_count'].std(),
                'max': analysis_data['behavior_count'].max()
            }
        }

    def analyze_all_behaviors(self, retention_days: List[int] = [1, 2, 7]) -> None:
        """
        分析所有行为

        Parameters:
        -----------
        retention_days : List[int]
            要分析的留存天数列表
        """
        print("开始分析所有行为...")

        self.analysis_results = {}

        # 关键行为列表（基于业务优先级）
        key_behaviors = [
            'click_header_banner',      # 头图区点击
            'click_golden_area',        # 金刚区点击
            'view_detail_page',         # 详情页查看
            'filter_distance',          # 距离筛选
            'filter_high_rebate',       # 高返利筛选
            'search_query',             # 搜索行为
            'total_clicks',             # 总点击次数
            'unique_modules'            # 访问模块数
        ]

        for behavior in key_behaviors:
            for retention_day in retention_days:
                key = f"{behavior}_day{retention_day}"

                try:
                    result = self.analyze_single_behavior(behavior, retention_day)
                    self.analysis_results[key] = result

                    # 打印简要结果
                    if result.get('magic_numbers'):
                        print(f"  {behavior} -> 发现{len(result['magic_numbers'])}个魔法数字")

                except Exception as e:
                    print(f"  分析 {behavior} 失败: {e}")

        print(f"分析完成，共分析 {len(self.analysis_results)} 个行为-留存组合")

    def find_top_magic_numbers(self, min_retention_increase: float = 0.05,
                              min_user_count: int = 100) -> List[Dict]:
        """
        找出最重要的魔法数字

        Parameters:
        -----------
        min_retention_increase : float
            最小留存提升要求（如0.05表示5个百分点）
        min_user_count : int
            最小用户数要求

        Returns:
        --------
        List[Dict]: 重要魔法数字列表
        """
        top_magic_numbers = []

        for key, result in self.analysis_results.items():
            for magic in result.get('magic_numbers', []):
                if (magic['retention_increase'] >= min_retention_increase and
                    magic['user_count'] >= min_user_count):

                    top_magic_numbers.append({
                        'behavior_type': result['behavior_type'],
                        'behavior_name': result['behavior_name'],
                        'retention_day': result['retention_day'],
                        'threshold': magic['threshold'],
                        'retention_increase': magic['retention_increase'],
                        'baseline_retention': magic['baseline_retention'],
                        'target_retention': magic['target_retention'],
                        'user_count': magic['user_count'],
                        'correlation': result['correlation']
                    })

        # 按留存提升排序
        top_magic_numbers.sort(key=lambda x: x['retention_increase'], reverse=True)

        return top_magic_numbers

    def visualize_behavior_retention(self, behavior_type: str,
                                    retention_day: int = 7,
                                    save_path: Optional[str] = None) -> None:
        """
        可视化行为与留存的关系

        Parameters:
        -----------
        behavior_type : str
            行为类型
        retention_day : int
            留存天数
        save_path : str, optional
            保存图片的路径
        """
        # 获取分析结果
        key = f"{behavior_type}_day{retention_day}"
        result = self.analysis_results.get(key)

        if not result:
            print(f"没有找到 {key} 的分析结果")
            return

        # 创建图表
        fig, axes = plt.subplots(2, 2, figsize=(14, 10))
        fig.suptitle(f'{result["behavior_name"]} - {retention_day}日留存分析',
                    fontsize=16, fontweight='bold')

        # 1. 行为频率分布
        behavior_counts = self.calculate_behavior_frequencies()
        counts_data = behavior_counts[behavior_type]

        axes[0, 0].hist(counts_data[counts_data <= 20], bins=20, alpha=0.7, color='skyblue')
        axes[0, 0].axvline(x=counts_data.median(), color='red', linestyle='--',
                          label=f'中位数: {counts_data.median():.1f}')
        axes[0, 0].set_xlabel('行为次数')
        axes[0, 0].set_ylabel('用户数')
        axes[0, 0].set_title('行为频率分布')
        axes[0, 0].legend()
        axes[0, 0].grid(True, alpha=0.3)

        # 2. 留存率 vs 行为次数
        thresholds = result['threshold_analysis']
        threshold_labels = [t['threshold'] for t in thresholds]
        retention_rates = [t['retention_rate'] for t in thresholds]
        user_counts = [t['user_count'] for t in thresholds]

        ax2 = axes[0, 1]
        bars = ax2.bar(range(len(thresholds)), retention_rates, color='lightgreen', alpha=0.7)

        # 标记魔法数字
        for i, magic in enumerate(result.get('magic_numbers', [])):
            for j, label in enumerate(threshold_labels):
                if magic['threshold'] == label:
                    bars[j].set_color('orange')
                    ax2.text(j, retention_rates[j] + 0.02,
                            f'+{magic["retention_increase"]:.1%}',
                            ha='center', fontweight='bold')

        ax2.set_xlabel('行为次数分组')
        ax2.set_ylabel('留存率')
        ax2.set_title(f'留存率 vs 行为次数 (相关性: {result["correlation"]:.3f})')
        ax2.set_xticks(range(len(thresholds)))
        ax2.set_xticklabels(threshold_labels, rotation=45)
        ax2.grid(True, alpha=0.3)

        # 3. 用户数分布
        axes[1, 0].bar(range(len(thresholds)), user_counts, color='lightcoral', alpha=0.7)
        axes[1, 0].set_xlabel('行为次数分组')
        axes[1, 0].set_ylabel('用户数')
        axes[1, 0].set_title('各分组用户数分布')
        axes[1, 0].set_xticks(range(len(thresholds)))
        axes[1, 0].set_xticklabels(threshold_labels, rotation=45)
        axes[1, 0].grid(True, alpha=0.3)

        # 4. 行为次数统计
        stats = result['summary_stats']
        stats_labels = ['均值', '中位数', '标准差', '最大值']
        stats_values = [stats['mean'], stats['median'], stats['std'], stats['max']]

        axes[1, 1].bar(stats_labels, stats_values, color='gold', alpha=0.7)
        axes[1, 1].set_ylabel('行为次数')
        axes[1, 1].set_title('行为次数统计摘要')

        for i, v in enumerate(stats_values):
            axes[1, 1].text(i, v + max(stats_values)*0.02, f'{v:.1f}',
                           ha='center', fontweight='bold')

        axes[1, 1].grid(True, alpha=0.3)

        plt.tight_layout()

        if save_path:
            plt.savefig(save_path, dpi=150, bbox_inches='tight')
            print(f"图表已保存: {save_path}")

        plt.show()

    def visualize_top_magic_numbers(self, top_n: int = 10,
                                   save_path: Optional[str] = None) -> None:
        """
        可视化最重要的魔法数字

        Parameters:
        -----------
        top_n : int
            显示前N个魔法数字
        save_path : str, optional
            保存图片的路径
        """
        top_magic = self.find_top_magic_numbers()

        if not top_magic:
            print("没有找到显著的魔法数字")
            return

        # 取前N个
        display_magic = top_magic[:min(top_n, len(top_magic))]

        # 创建图表
        fig, ax = plt.subplots(figsize=(12, 8))

        # 准备数据
        labels = []
        baseline_retention = []
        target_retention = []
        retention_increase = []

        for magic in display_magic:
            label = (f"{magic['behavior_name']}\n"
                    f"阈值: {magic['threshold']}\n"
                    f"用户: {magic['user_count']:,}")
            labels.append(label)
            baseline_retention.append(magic['baseline_retention'])
            target_retention.append(magic['target_retention'])
            retention_increase.append(magic['retention_increase'])

        # 绘制分组条形图
        x = np.arange(len(labels))
        width = 0.35

        bars1 = ax.bar(x - width/2, baseline_retention, width,
                      label='阈值前留存', color='lightgray', alpha=0.7)
        bars2 = ax.bar(x + width/2, target_retention, width,
                      label='阈值后留存', color='lightgreen', alpha=0.7)

        # 添加留存提升标注
        for i, increase in enumerate(retention_increase):
            ax.text(i, max(baseline_retention[i], target_retention[i]) + 0.02,
                   f'+{increase:.1%}', ha='center', fontweight='bold')

        ax.set_xlabel('魔法数字')
        ax.set_ylabel('留存率')
        ax.set_title(f'Top {len(display_magic)} 魔法数字 - 留存提升效果')
        ax.set_xticks(x)
        ax.set_xticklabels(labels, rotation=45, ha='right')
        ax.legend()
        ax.grid(True, alpha=0.3)

        plt.tight_layout()

        if save_path:
            plt.savefig(save_path, dpi=150, bbox_inches='tight')
            print(f"图表已保存: {save_path}")

        plt.show()

    def generate_report(self, output_path: Optional[str] = None) -> str:
        """
        生成分析报告

        Parameters:
        -----------
        output_path : str, optional
            报告保存路径

        Returns:
        --------
        str: 报告内容
        """
        print("生成分析报告...")

        # 获取最重要的魔法数字
        top_magic = self.find_top_magic_numbers()

        # 报告头部
        report = "# 小蚕霸王餐魔法数字分析报告\n\n"
        report += f"**报告生成时间**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n"
        report += f"**分析用户数**: {len(self.user_cohorts) if self.user_cohorts is not None else 'N/A'}\n"
        report += f"**行为记录数**: {len(self.behavior_data) if self.behavior_data is not None else 'N/A'}\n\n"

        # 执行摘要
        report += "## 执行摘要\n\n"

        if top_magic:
            report += f"发现 **{len(top_magic)}** 个显著的魔法数字（留存提升≥5个百分点）\n\n"

            # 最重要的3个魔法数字
            if len(top_magic) >= 3:
                report += "### 最重要的3个魔法数字\n\n"
                for i, magic in enumerate(top_magic[:3], 1):
                    report += (f"{i}. **{magic['behavior_name']}** "
                              f"(阈值: {magic['threshold']})\n")
                    report += (f"   - {magic['retention_day']}日留存提升: "
                              f"**{magic['retention_increase']:.1%}** "
                              f"({magic['baseline_retention']:.1%} → "
                              f"{magic['target_retention']:.1%})\n")
                    report += f"   - 影响用户数: {magic['user_count']:,}\n\n")
        else:
            report += "未发现显著的魔法数字（留存提升≥5个百分点）\n\n"

        # 详细分析结果
        report += "## 详细分析结果\n\n"

        for key, result in self.analysis_results.items():
            if not result.get('magic_numbers'):
                continue

            report += f"### {result['behavior_name']} ({result['retention_day']}日留存)\n\n"
            report += f"- **相关性**: {result['correlation']:.3f}\n"
            report += f"- **分析用户数**: {result['total_users']:,}\n"
            report += f"- **平均行为次数**: {result['summary_stats']['mean']:.1f}\n"
            report += f"- **中位数行为次数**: {result['summary_stats']['median']:.1f}\n\n"

            report += "#### 魔法数字发现\n\n"
            for magic in result['magic_numbers']:
                report += (f"- **阈值 {magic['threshold']}**: "
                          f"留存提升 {magic['retention_increase']:.1%} "
                          f"({magic['baseline_retention']:.1%} → "
                          f"{magic['target_retention']:.1%}), "
                          f"用户数: {magic['user_count']:,}\n")

            report += "\n"

        # 行为统计摘要
        report += "## 行为统计摘要\n\n"

        behavior_counts = self.calculate_behavior_frequencies()
        if behavior_counts is not None:
            summary_stats = behavior_counts.describe().T
            summary_stats = summary_stats[['mean', '50%', 'std', 'max']]
            summary_stats.columns = ['均值', '中位数', '标准差', '最大值']

            # 只显示关键行为
            key_behaviors = [b for b in self.behavior_types.keys()
                            if b in summary_stats.index]

            if key_behaviors:
                report += summary_stats.loc[key_behaviors].to_markdown()
                report += "\n\n"

        # 建议和行动计划
        report += "## 建议和行动计划\n\n"

        if top_magic:
            report += "### 立即行动项（P0）\n\n"

            # 按影响排序
            high_impact_magic = sorted(top_magic,
                                      key=lambda x: x['retention_increase'],
                                      reverse=True)[:3]

            for i, magic in enumerate(high_impact_magic, 1):
                report += f"{i}. **优化{magic['behavior_name']}引导**\n"
                report += f"   - 目标: 让更多用户达到阈值 {magic['threshold']}\n"
                report += f"   - 预期效果: 提升留存率 {magic['retention_increase']:.1%}\n"
                report += f"   - 影响用户: {magic['user_count']:,}\n"

                # 具体建议
                if 'click' in magic['behavior_type']:
                    report += f"   - 具体措施: 优化{magic['behavior_name']}的可见性和吸引力\n"
                elif 'filter' in magic['behavior_type']:
                    report += f"   - 具体措施: 教育用户使用{magic['behavior_name']}找到更合适的商品\n"
                elif 'view_detail' in magic['behavior_type']:
                    report += f"   - 具体措施: 优化详情页设计，提高用户查看多个详情页的意愿\n"
                elif 'search' in magic['behavior_type']:
                    report += f"   - 具体措施: 优化搜索体验和结果相关性\n"

                report += "\n"

            report += "### 监控指标\n\n"
            report += "1. **魔法数字达成率**: 达到各魔法数字阈值的用户比例\n"
            report += "2. **留存率变化**: 监控魔法数字相关行为的留存率变化\n"
            report += "3. **用户行为分布**: 监控各行为次数的用户分布变化\n"
            report += "4. **干预效果**: A/B测试不同引导策略的效果\n\n"

            report += "### 后续分析建议\n\n"
            report += "1. **因果验证**: 通过A/B测试验证魔法数字的因果效应\n"
            report += "2. **细分分析**: 对不同用户群体（新用户、活跃用户、沉默用户）进行细分分析\n"
            report += "3. **时间趋势**: 分析魔法数字的稳定性随时间的变化\n"
            report += "4. **组合分析**: 分析多个魔法数字组合的叠加效应\n"

        else:
            report += "### 后续步骤建议\n\n"
            report += "1. **扩大分析范围**: 尝试更多行为类型和细分维度\n"
            report += "2. **调整阈值**: 尝试不同的留存提升阈值（如3个百分点）\n"
            report += "3. **用户细分**: 对不同用户群体进行独立分析\n"
            report += "4. **时间窗口**: 调整分析的时间窗口（如前3天、前7天行为）\n"

        # 技术备注
        report += "## 技术备注\n\n"
        report += "- **分析方法**: 行为频率与留存率相关性分析 + 阈值探索\n"
        report += "- **留存定义**: 在指定日期有任意行为的用户视为留存\n"
        report += "- **数据周期**: 最近30天用户行为数据\n"
        report += "- **显著性标准**: 留存提升≥5个百分点且用户数≥100\n"
        report += "- **局限性**: 相关性不等于因果关系，建议通过A/B测试验证\n"

        # 保存报告
        if output_path:
            with open(output_path, 'w', encoding='utf-8') as f:
                f.write(report)
            print(f"报告已保存: {output_path}")

        return report

    def save_results(self, output_dir: str = './output') -> None:
        """
        保存分析结果

        Parameters:
        -----------
        output_dir : str
            输出目录
        """
        import os

        # 创建输出目录
        os.makedirs(output_dir, exist_ok=True)

        # 保存分析结果
        results_file = os.path.join(output_dir, 'magic_number_results.json')

        # 简化结果以便保存
        simplified_results = {}
        for key, result in self.analysis_results.items():
            simplified_results[key] = {
                'behavior_name': result['behavior_name'],
                'retention_day': result['retention_day'],
                'correlation': result['correlation'],
                'magic_numbers': result.get('magic_numbers', []),
                'summary_stats': result['summary_stats']
            }

        with open(results_file, 'w', encoding='utf-8') as f:
            json.dump(simplified_results, f, ensure_ascii=False, indent=2)

        print(f"分析结果已保存: {results_file}")

        # 生成报告
        report_file = os.path.join(output_dir, 'magic_number_report.md')
        self.generate_report(report_file)

        # 保存可视化
        if self.analysis_results:
            # 保存最重要的魔法数字可视化
            viz_file = os.path.join(output_dir, 'top_magic_numbers.png')
            self.visualize_top_magic_numbers(save_path=viz_file)

            # 保存关键行为的可视化
            key_behaviors = ['click_header_banner', 'view_detail_page', 'total_clicks']
            for i, behavior in enumerate(key_behaviors):
                if f"{behavior}_day7" in self.analysis_results:
                    viz_file = os.path.join(output_dir, f'{behavior}_analysis.png')
                    self.visualize_behavior_retention(
                        behavior, retention_day=7, save_path=viz_file
                    )

def main():
    """主函数"""
    parser = argparse.ArgumentParser(description='小蚕霸王餐魔法数字分析')
    parser.add_argument('--mode', type=str, default='simulate',
                       choices=['simulate', 'analyze'],
                       help='运行模式: simulate(模拟数据) 或 analyze(分析真实数据)')
    parser.add_argument('--data_path', type=str, default=None,
                       help='真实数据文件路径（CSV格式）')
    parser.add_argument('--output_dir', type=str, default='./magic_number_output',
                       help='输出目录')
    parser.add_argument('--n_users', type=int, default=10000,
                       help='模拟用户数量（仅模拟模式有效）')
    parser.add_argument('--days', type=int, default=30,
                       help='模拟天数（仅模拟模式有效）')

    args = parser.parse_args()

    # 创建分析器
    analyzer = MagicNumberAnalyzer(data_path=args.data_path)

    # 加载数据
    if args.mode == 'simulate':
        analyzer.generate_simulated_data(n_users=args.n_users, days=args.days)
    else:
        if not args.data_path:
            print("错误: analyze模式需要指定--data_path参数")
            return
        analyzer.load_real_data()

    # 分析所有行为
    analyzer.analyze_all_behaviors(retention_days=[1, 2, 7])

    # 找出最重要的魔法数字
    top_magic = analyzer.find_top_magic_numbers()

    if top_magic:
        print(f"\n发现 {len(top_magic)} 个显著的魔法数字:")
        print("=" * 80)
        for i, magic in enumerate(top_magic[:5], 1):
            print(f"{i}. {magic['behavior_name']} (阈值: {magic['threshold']})")
            print(f"   {magic['retention_day']}日留存提升: {magic['retention_increase']:.1%}")
            print(f"   用户数: {magic['user_count']:,}")
            print()
    else:
        print("\n未发现显著的魔法数字（留存提升≥5个百分点）")

    # 保存结果
    analyzer.save_results(output_dir=args.output_dir)

    print(f"\n分析完成！结果已保存到: {args.output_dir}")
    print("包含:")
    print("  1. magic_number_results.json - 分析结果数据")
    print("  2. magic_number_report.md - 分析报告")
    print("  3. *.png - 可视化图表")

if __name__ == '__main__':
    main()