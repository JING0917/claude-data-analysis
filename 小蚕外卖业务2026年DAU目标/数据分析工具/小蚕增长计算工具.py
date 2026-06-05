#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
小蚕业务增长计算工具
基于DAU增长目标和用户结构拆解，计算关键业务指标
"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import warnings
warnings.filterwarnings('ignore')

class XiaocanGrowthCalculator:
    """小蚕业务增长计算器"""

    def __init__(self, dau_peak_2025=1150000, growth_target_pct=0.5):
        """
        初始化计算器

        Parameters:
        -----------
        dau_peak_2025 : int
            2025年DAU峰值（默认115万）
        growth_target_pct : float
            2026年增长目标百分比（默认50%）
        """
        self.dau_peak_2025 = dau_peak_2025
        self.growth_target_pct = growth_target_pct
        self.dau_target_2026 = self._calculate_dau_target()

        # 季度权重（基于业务规律假设）
        self.quarter_weights = {
            'Q1': 0.25,  # 第1季度：25%
            'Q2': 0.40,  # 第2季度：40%
            'Q3': 0.65,  # 第3季度：65%
            'Q4': 1.00   # 第4季度：100%
        }

        # 用户结构基准假设
        self.user_structure_baseline = {
            'new_user_pct': 0.30,  # 新用户占比30%
            'recall_user_pct': 0.15,  # 召回用户占比15%
            'retained_user_pct': 0.55  # 留存用户占比55%
        }

        # 留存率基准
        self.retention_baseline = {
            'd2_retention': 0.35,  # 次2日留存率35%
            'd7_retention': 0.25,  # 7日留存率25%
            'd30_retention': 0.15   # 30日留存率15%
        }

    def _calculate_dau_target(self):
        """计算2026年DAU目标"""
        return int(self.dau_peak_2025 * (1 + self.growth_target_pct))

    def calculate_quarter_targets(self):
        """计算季度目标"""
        targets = {}
        for quarter, weight in self.quarter_weights.items():
            quarter_dau = int(self.dau_target_2026 * weight)
            targets[quarter] = {
                'dau_target': quarter_dau,
                'weight': weight,
                'growth_from_peak': quarter_dau - self.dau_peak_2025
            }
        return targets

    def decompose_dau_target(self, dau_value, structure_ratios=None):
        """
        分解DAU目标到各用户组成部分

        Parameters:
        -----------
        dau_value : int
            DAU数值
        structure_ratios : dict, optional
            用户结构比例，默认为基准比例

        Returns:
        --------
        dict: 各组成部分的用户数
        """
        if structure_ratios is None:
            structure_ratios = self.user_structure_baseline

        return {
            'new_users': int(dau_value * structure_ratios['new_user_pct']),
            'recall_users': int(dau_value * structure_ratios['recall_user_pct']),
            'retained_users': int(dau_value * structure_ratios['retained_user_pct'])
        }

    def calculate_acquisition_targets(self, quarter, new_user_ratio=None):
        """
        计算获客目标

        Parameters:
        -----------
        quarter : str
            季度标识，如'Q2'
        new_user_ratio : float, optional
            新用户占比，默认为基准比例

        Returns:
        --------
        dict: 获客相关目标
        """
        if quarter not in self.quarter_weights:
            raise ValueError(f"无效的季度标识: {quarter}")

        quarter_dau = self.dau_target_2026 * self.quarter_weights[quarter]

        if new_user_ratio is None:
            new_user_ratio = self.user_structure_baseline['new_user_pct']

        # 月度分解（假设季度内各月均匀分布）
        monthly_new_users = int(quarter_dau * new_user_ratio / 3)

        # 渠道分解（基于经验假设）
        channel_distribution = {
            'captain': 0.40,  # 团长拉新40%
            'channel': 0.35,  # 渠道投放35%
            'organic': 0.25   # 自然新增25%
        }

        channel_targets = {}
        for channel, ratio in channel_distribution.items():
            channel_targets[channel] = int(monthly_new_users * ratio)

        return {
            'quarter': quarter,
            'quarter_dau_target': int(quarter_dau),
            'monthly_new_user_target': monthly_new_users,
            'channel_targets': channel_targets,
            'total_new_users_quarter': monthly_new_users * 3
        }

    def calculate_recall_targets(self, quarter, recall_ratio=None, recall_efficiency=0.10):
        """
        计算召回目标

        Parameters:
        -----------
        quarter : str
            季度标识
        recall_ratio : float, optional
            召回用户占比
        recall_efficiency : float
            召回效率（召回用户数/触达用户数）

        Returns:
        --------
        dict: 召回相关目标
        """
        if quarter not in self.quarter_weights:
            raise ValueError(f"无效的季度标识: {quarter}")

        quarter_dau = self.dau_target_2026 * self.quarter_weights[quarter]

        if recall_ratio is None:
            recall_ratio = self.user_structure_baseline['recall_user_pct']

        monthly_recall_users = int(quarter_dau * recall_ratio / 3)

        # 计算需要触达的沉默用户数
        reach_users_needed = int(monthly_recall_users / recall_efficiency)

        # 召回成本估算（基于行业基准）
        cost_per_recall = 8.0  # 元/用户
        monthly_recall_cost = monthly_recall_users * cost_per_recall

        return {
            'quarter': quarter,
            'monthly_recall_target': monthly_recall_users,
            'reach_users_needed': reach_users_needed,
            'recall_efficiency': recall_efficiency,
            'monthly_recall_cost': monthly_recall_cost,
            'cost_per_recall': cost_per_recall,
            'total_recall_quarter': monthly_recall_users * 3
        }

    def calculate_retention_impact(self, base_users, retention_rate, improved_retention_rate, user_ltv=300):
        """
        计算留存率提升带来的业务价值

        Parameters:
        -----------
        base_users : int
            基准用户数
        retention_rate : float
            基准留存率
        improved_retention_rate : float
            提升后的留存率
        user_ltv : float
            用户生命周期价值（元）

        Returns:
        --------
        dict: 留存提升价值
        """
        retained_users_base = int(base_users * retention_rate)
        retained_users_improved = int(base_users * improved_retention_rate)

        additional_retained_users = retained_users_improved - retained_users_base

        value_impact = additional_retained_users * user_ltv

        return {
            'base_retained_users': retained_users_base,
            'improved_retained_users': retained_users_improved,
            'additional_retained_users': additional_retained_users,
            'retention_improvement_pct': (improved_retention_rate - retention_rate) * 100,
            'value_impact': value_impact,
            'user_ltv': user_ltv
        }

    def calculate_project_roi(self, project_cost, new_users_generated=0,
                            recall_users_generated=0, retention_improvement=0,
                            avg_user_value=300, project_duration_months=3):
        """
        计算项目ROI

        Parameters:
        -----------
        project_cost : float
            项目总成本（元）
        new_users_generated : int
            项目带来的新用户数
        recall_users_generated : int
            项目带来的召回用户数
        retention_improvement : float
            留存率提升百分比（小数）
        avg_user_value : float
            用户平均价值（元）
        project_duration_months : int
            项目持续时间（月）

        Returns:
        --------
        dict: ROI计算结果
        """
        # 计算用户价值
        new_user_value = new_users_generated * avg_user_value
        recall_user_value = recall_users_generated * avg_user_value * 0.7  # 召回用户价值折扣

        # 计算留存提升价值（假设影响用户基数为10万）
        base_users_affected = 100000
        retention_value = base_users_affected * retention_improvement * avg_user_value

        total_value = new_user_value + recall_user_value + retention_value

        # 计算月度价值（考虑项目持续时间）
        monthly_value = total_value / project_duration_months

        # 计算ROI
        roi = (total_value - project_cost) / project_cost if project_cost > 0 else float('inf')

        return {
            'project_cost': project_cost,
            'total_value_generated': total_value,
            'monthly_value': monthly_value,
            'roi': roi,
            'roi_percentage': roi * 100,
            'payback_period_months': project_cost / monthly_value if monthly_value > 0 else float('inf'),
            'value_breakdown': {
                'new_users': new_user_value,
                'recall_users': recall_user_value,
                'retention_improvement': retention_value
            }
        }

    def analyze_growth_scenario(self, quarter, scenario_name="基准场景"):
        """
        分析增长场景

        Parameters:
        -----------
        quarter : str
            季度标识
        scenario_name : str
            场景名称

        Returns:
        --------
        dict: 场景分析结果
        """
        # 计算季度目标
        quarter_targets = self.calculate_quarter_targets()
        quarter_dau = quarter_targets[quarter]['dau_target']

        # 分解用户结构
        dau_decomposition = self.decompose_dau_target(quarter_dau)

        # 计算获客目标
        acquisition_targets = self.calculate_acquisition_targets(quarter)

        # 计算召回目标
        recall_targets = self.calculate_recall_targets(quarter)

        # 计算留存目标（假设提升10%）
        retention_improvement = 0.10
        improved_d2_retention = self.retention_baseline['d2_retention'] * (1 + retention_improvement)

        retention_impact = self.calculate_retention_impact(
            base_users=acquisition_targets['monthly_new_user_target'],
            retention_rate=self.retention_baseline['d2_retention'],
            improved_retention_rate=improved_d2_retention
        )

        # 汇总结果
        scenario_result = {
            'scenario_name': scenario_name,
            'quarter': quarter,
            'quarter_dau_target': quarter_dau,
            'dau_decomposition': dau_decomposition,
            'acquisition_targets': acquisition_targets,
            'recall_targets': recall_targets,
            'retention_targets': {
                'baseline_d2_retention': self.retention_baseline['d2_retention'],
                'target_d2_retention': improved_d2_retention,
                'improvement_pct': retention_improvement * 100,
                'impact_analysis': retention_impact
            },
            'summary': {
                'total_new_users_needed': acquisition_targets['total_new_users_quarter'],
                'total_recall_users_needed': recall_targets['total_recall_quarter'],
                'retention_improvement_value': retention_impact['value_impact'],
                'growth_gap': quarter_dau - self.dau_peak_2025
            }
        }

        return scenario_result

    def generate_project_financials(self, project_name, project_type,
                                  quarter, estimated_cost,
                                  new_user_impact=0, recall_user_impact=0,
                                  retention_impact_pct=0):
        """
        生成项目财务分析

        Parameters:
        -----------
        project_name : str
            项目名称
        project_type : str
            项目类型（product/operation）
        quarter : str
            所属季度
        estimated_cost : float
            预估成本（元）
        new_user_impact : int
            预计带来的新用户数
        recall_user_impact : int
            预计带来的召回用户数
        retention_impact_pct : float
            预计带来的留存率提升百分比（小数）

        Returns:
        --------
        dict: 项目财务分析
        """
        # 计算ROI
        roi_analysis = self.calculate_project_roi(
            project_cost=estimated_cost,
            new_users_generated=new_user_impact,
            recall_users_generated=recall_user_impact,
            retention_improvement=retention_impact_pct
        )

        # 项目基本信息
        project_info = {
            'project_name': project_name,
            'project_type': project_type,
            'quarter': quarter,
            'estimated_cost': estimated_cost,
            'impact_metrics': {
                'new_users': new_user_impact,
                'recall_users': recall_user_impact,
                'retention_improvement_pct': retention_impact_pct * 100
            }
        }

        # 合并结果
        financials = {**project_info, **roi_analysis}

        return financials

    def print_summary_report(self):
        """打印汇总报告"""
        print("=" * 80)
        print("小蚕业务增长计算工具 - 汇总报告")
        print("=" * 80)

        print(f"\n1. 基础设定:")
        print(f"   2025年DAU峰值: {self.dau_peak_2025:,}")
        print(f"   2026年增长目标: {self.growth_target_pct*100:.0f}%")
        print(f"   2026年DAU目标: {self.dau_target_2026:,}")

        print(f"\n2. 季度目标分解:")
        quarter_targets = self.calculate_quarter_targets()
        for quarter, data in quarter_targets.items():
            if quarter in ['Q2', 'Q3']:  # 只显示用户关心的季度
                print(f"   {quarter}: {data['dau_target']:,} (权重: {data['weight']*100:.0f}%)")

        print(f"\n3. 用户结构基准:")
        for component, pct in self.user_structure_baseline.items():
            component_name = {
                'new_user_pct': '新用户占比',
                'recall_user_pct': '召回用户占比',
                'retained_user_pct': '留存用户占比'
            }[component]
            print(f"   {component_name}: {pct*100:.0f}%")

        print(f"\n4. 留存率基准:")
        for metric, rate in self.retention_baseline.items():
            metric_name = {
                'd2_retention': '次2日留存率',
                'd7_retention': '7日留存率',
                'd30_retention': '30日留存率'
            }[metric]
            print(f"   {metric_name}: {rate*100:.0f}%")

        print("\n" + "=" * 80)

def main():
    """主函数"""
    # 初始化计算器
    calculator = XiaocanGrowthCalculator(
        dau_peak_2025=1150000,  # 115万
        growth_target_pct=0.5    # 增长50%
    )

    # 打印汇总报告
    calculator.print_summary_report()

    print("\n5. 第2季度详细分析:")
    print("-" * 40)

    # 分析第2季度场景
    q2_scenario = calculator.analyze_growth_scenario('Q2', "第2季度基准场景")

    print(f"   DAU目标: {q2_scenario['quarter_dau_target']:,}")
    print(f"   用户结构分解:")
    for component, count in q2_scenario['dau_decomposition'].items():
        component_name = {
            'new_users': '新用户',
            'recall_users': '召回用户',
            'retained_users': '留存用户'
        }[component]
        print(f"     {component_name}: {count:,}")

    print(f"\n   获客目标:")
    acq = q2_scenario['acquisition_targets']
    print(f"     月度新用户目标: {acq['monthly_new_user_target']:,}")
    print(f"     渠道分解:")
    for channel, target in acq['channel_targets'].items():
        channel_name = {
            'captain': '团长拉新',
            'channel': '渠道投放',
            'organic': '自然新增'
        }[channel]
        print(f"       {channel_name}: {target:,}")

    print(f"\n   召回目标:")
    recall = q2_scenario['recall_targets']
    print(f"     月度召回目标: {recall['monthly_recall_target']:,}")
    print(f"     需要触达用户: {recall['reach_users_needed']:,}")
    print(f"     预估月度成本: ¥{recall['monthly_recall_cost']:,.0f}")

    print(f"\n   留存目标:")
    retention = q2_scenario['retention_targets']
    print(f"     次2日留存率目标: {retention['target_d2_retention']*100:.1f}%")
    print(f"     留存提升价值: ¥{retention['impact_analysis']['value_impact']:,.0f}")

    print("\n6. 示例项目财务分析:")
    print("-" * 40)

    # 示例项目1：团长裂变体系升级
    project1 = calculator.generate_project_financials(
        project_name="团长裂变体系升级",
        project_type="product",
        quarter="Q2",
        estimated_cost=500000,  # 50万元
        new_user_impact=30000,  # 带来3万新用户
        recall_user_impact=5000,  # 带来5千召回用户
        retention_impact_pct=0.05  # 留存率提升5%
    )

    print(f"\n   项目: {project1['project_name']}")
    print(f"   类型: {project1['project_type']}")
    print(f"   季度: {project1['quarter']}")
    print(f"   预估成本: ¥{project1['estimated_cost']:,.0f}")
    print(f"   预计ROI: {project1['roi_percentage']:.1f}%")
    print(f"   回收期: {project1['payback_period_months']:.1f}个月")

    # 示例项目2：春季拉新冲刺计划
    project2 = calculator.generate_project_financials(
        project_name="春季拉新冲刺计划",
        project_type="operation",
        quarter="Q2",
        estimated_cost=1000000,  # 100万元
        new_user_impact=100000,  # 带来10万新用户
        recall_user_impact=15000,  # 带来1.5万召回用户
        retention_impact_pct=0.02  # 留存率提升2%
    )

    print(f"\n   项目: {project2['project_name']}")
    print(f"   类型: {project2['project_type']}")
    print(f"   季度: {project2['quarter']}")
    print(f"   预估成本: ¥{project2['estimated_cost']:,.0f}")
    print(f"   预计ROI: {project2['roi_percentage']:.1f}%")
    print(f"   回收期: {project2['payback_period_months']:.1f}个月")

    print("\n" + "=" * 80)
    print("使用说明:")
    print("1. 修改dau_peak_2025和growth_target_pct参数调整基础设定")
    print("2. 使用analyze_growth_scenario()分析不同季度场景")
    print("3. 使用generate_project_financials()评估具体项目财务表现")
    print("4. 所有金额单位均为人民币元")
    print("=" * 80)

if __name__ == "__main__":
    main()