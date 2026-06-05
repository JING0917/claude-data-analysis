#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
小蚕当前状态分析与目标差距计算
基于2026年3月实际数据：DAU 94万+，每日拉新2万+，召回2万+
"""

import pandas as pd
import numpy as np

class XiaocanCurrentAnalysis:
    """基于当前状态的分析"""

    def __init__(self, current_dau=940000, daily_new_users=20000,
                 daily_recall_users=20000, dau_peak_2025=1150000,
                 growth_target_pct=0.5):
        """
        初始化分析器

        Parameters:
        -----------
        current_dau : int
            当前日均DAU（3月份数据）
        daily_new_users : int
            每日新增注册用户量
        daily_recall_users : int
            每日召回用户量
        dau_peak_2025 : int
            2025年DAU峰值
        growth_target_pct : float
            2026年增长目标百分比
        """
        self.current_dau = current_dau
        self.daily_new_users = daily_new_users
        self.daily_recall_users = daily_recall_users
        self.dau_peak_2025 = dau_peak_2025
        self.growth_target_pct = growth_target_pct

        # 计算目标
        self.dau_target_2026 = int(dau_peak_2025 * (1 + growth_target_pct))

        # 计算当前用户结构
        self.current_structure = self._calculate_current_structure()

        # 计算增长缺口
        self.growth_gap = self._calculate_growth_gap()

        # 季度权重（更新基于当前状态）
        self.quarter_weights = self._calculate_quarter_weights()

    def _calculate_current_structure(self):
        """计算当前用户结构"""
        # DAU中的用户构成（基于描述）
        # "每日拉新用户量2万+，召回用户2万+，其他是留存用户"
        # 假设：DAU = 新注册当日活跃 + 召回当日活跃 + 留存用户活跃
        new_users_in_dau = self.daily_new_users  # 假设新增用户当日都活跃
        recall_users_in_dau = self.daily_recall_users  # 假设召回用户当日都活跃
        retained_users_in_dau = self.current_dau - new_users_in_dau - recall_users_in_dau

        return {
            'new_users_dau': new_users_in_dau,
            'recall_users_dau': recall_users_in_dau,
            'retained_users_dau': retained_users_in_dau,
            'new_users_pct': new_users_in_dau / self.current_dau,
            'recall_users_pct': recall_users_in_dau / self.current_dau,
            'retained_users_pct': retained_users_in_dau / self.current_dau
        }

    def _calculate_growth_gap(self):
        """计算增长缺口"""
        # 从当前到25年峰值的恢复空间
        recovery_gap = max(0, self.dau_peak_2025 - self.current_dau)

        # 从25年峰值到26年目标的增长空间
        growth_gap = self.dau_target_2026 - self.dau_peak_2025

        # 总缺口
        total_gap = self.dau_target_2026 - self.current_dau

        return {
            'recovery_gap': recovery_gap,
            'growth_gap': growth_gap,
            'total_gap': total_gap,
            'recovery_pct': recovery_gap / self.current_dau * 100 if self.current_dau > 0 else 0,
            'growth_pct': growth_gap / self.dau_peak_2025 * 100 if self.dau_peak_2025 > 0 else 0,
            'total_pct': total_gap / self.current_dau * 100 if self.current_dau > 0 else 0
        }

    def _calculate_quarter_weights(self):
        """基于当前时间（3月）计算季度权重"""
        # 当前3月，属于第1季度末
        # 第1季度（1-3月）剩余增长空间有限
        # 重新分配季度权重
        return {
            'Q1': 0.30,  # 第1季度：30%（已基本完成）
            'Q2': 0.55,  # 第2季度：55%
            'Q3': 0.85,  # 第3季度：85%
            'Q4': 1.00   # 第4季度：100%
        }

    def calculate_quarterly_targets_from_current(self):
        """从当前状态计算季度目标"""
        targets = {}
        total_gap = self.growth_gap['total_gap']

        for quarter, weight in self.quarter_weights.items():
            # 该季度需要达到的DAU
            quarter_dau = self.current_dau + total_gap * weight

            # 该季度需要增长的量
            quarter_growth = quarter_dau - self.current_dau

            targets[quarter] = {
                'dau_target': int(quarter_dau),
                'growth_needed': int(quarter_growth),
                'weight': weight,
                'growth_pct': quarter_growth / self.current_dau * 100
            }

        return targets

    def analyze_dau_components_growth(self, target_dau, target_structure=None):
        """
        分析DAU各组成部分的增长需求

        Parameters:
        -----------
        target_dau : int
            目标DAU
        target_structure : dict, optional
            目标用户结构比例

        Returns:
        --------
        dict: 各组成部分增长需求
        """
        if target_structure is None:
            # 基于业务优化假设的目标结构
            target_structure = {
                'new_users_pct': 0.10,  # 目标：新用户占比10%（当前约2.1%）
                'recall_users_pct': 0.08,  # 目标：召回用户占比8%（当前约2.1%）
                'retained_users_pct': 0.82  # 目标：留存用户占比82%
            }

        # 计算目标各组成部分
        target_components = {
            'new_users': int(target_dau * target_structure['new_users_pct']),
            'recall_users': int(target_dau * target_structure['recall_users_pct']),
            'retained_users': int(target_dau * target_structure['retained_users_pct'])
        }

        # 计算增长需求
        growth_needed = {
            'new_users': target_components['new_users'] - self.current_structure['new_users_dau'],
            'recall_users': target_components['recall_users'] - self.current_structure['recall_users_dau'],
            'retained_users': target_components['retained_users'] - self.current_structure['retained_users_dau']
        }

        # 计算增长贡献度
        total_growth = sum(growth_needed.values())
        if total_growth > 0:
            contribution = {
                k: v / total_growth * 100
                for k, v in growth_needed.items()
            }
        else:
            contribution = {k: 0 for k in growth_needed.keys()}

        return {
            'target_components': target_components,
            'growth_needed': growth_needed,
            'contribution_pct': contribution,
            'target_structure': target_structure,
            'current_structure': {
                'new_users_pct': self.current_structure['new_users_pct'],
                'recall_users_pct': self.current_structure['recall_users_pct'],
                'retained_users_pct': self.current_structure['retained_users_pct']
            }
        }

    def calculate_daily_metrics_requirements(self, target_monthly_new_users,
                                           target_monthly_recall_users,
                                           days_in_month=30):
        """
        计算每日指标需求

        Parameters:
        -----------
        target_monthly_new_users : int
            月度新增用户目标
        target_monthly_recall_users : int
            月度召回用户目标
        days_in_month : int
            月度天数

        Returns:
        --------
        dict: 每日指标需求
        """
        current_daily_new = self.daily_new_users
        current_daily_recall = self.daily_recall_users

        target_daily_new = target_monthly_new_users / days_in_month
        target_daily_recall = target_monthly_recall_users / days_in_month

        improvement_new = target_daily_new / current_daily_new if current_daily_new > 0 else float('inf')
        improvement_recall = target_daily_recall / current_daily_recall if current_daily_recall > 0 else float('inf')

        return {
            'current_daily_new': current_daily_new,
            'target_daily_new': target_daily_new,
            'new_users_improvement': improvement_new,
            'current_daily_recall': current_daily_recall,
            'target_daily_recall': target_daily_recall,
            'recall_improvement': improvement_recall,
            'monthly_new_target': target_monthly_new_users,
            'monthly_recall_target': target_monthly_recall_users
        }

    def calculate_user_acquisition_costs(self, current_cac_new=15, current_cac_recall=8,
                                       target_cac_new=12, target_cac_recall=6):
        """
        计算用户获取成本

        Parameters:
        -----------
        current_cac_new : float
            当前新用户获取成本（元/用户）
        current_cac_recall : float
            当前召回用户成本（元/用户）
        target_cac_new : float
            目标新用户获取成本
        target_cac_recall : float
            目标召回用户成本

        Returns:
        --------
        dict: 成本分析
        """
        # 当前月度成本
        current_monthly_cost_new = self.daily_new_users * 30 * current_cac_new
        current_monthly_cost_recall = self.daily_recall_users * 30 * current_cac_recall
        current_total_monthly_cost = current_monthly_cost_new + current_monthly_cost_recall

        # 假设月度目标（示例）
        target_monthly_new = self.daily_new_users * 30 * 2  # 翻倍
        target_monthly_recall = self.daily_recall_users * 30 * 2  # 翻倍

        # 目标月度成本
        target_monthly_cost_new = target_monthly_new * target_cac_new
        target_monthly_cost_recall = target_monthly_recall * target_cac_recall
        target_total_monthly_cost = target_monthly_cost_new + target_monthly_cost_recall

        # 成本效率提升
        cost_efficiency_new = (current_cac_new - target_cac_new) / current_cac_new * 100 if current_cac_new > 0 else 0
        cost_efficiency_recall = (current_cac_recall - target_cac_recall) / current_cac_recall * 100 if current_cac_recall > 0 else 0

        return {
            'current_costs': {
                'new_user_cac': current_cac_new,
                'recall_cac': current_cac_recall,
                'monthly_new_cost': current_monthly_cost_new,
                'monthly_recall_cost': current_monthly_cost_recall,
                'total_monthly_cost': current_total_monthly_cost
            },
            'target_costs': {
                'new_user_cac': target_cac_new,
                'recall_cac': target_cac_recall,
                'monthly_new_cost': target_monthly_cost_new,
                'monthly_recall_cost': target_monthly_cost_recall,
                'total_monthly_cost': target_total_monthly_cost
            },
            'cost_efficiency_improvement': {
                'new_user_pct': cost_efficiency_new,
                'recall_user_pct': cost_efficiency_recall,
                'total_cost_change_pct': (target_total_monthly_cost - current_total_monthly_cost) / current_total_monthly_cost * 100
            }
        }

    def generate_growth_scenario(self, scenario_name="优化增长场景"):
        """生成增长场景分析"""
        # 计算季度目标
        quarterly_targets = self.calculate_quarterly_targets_from_current()

        # 分析Q2目标
        q2_target = quarterly_targets['Q2']['dau_target']
        q2_analysis = self.analyze_dau_components_growth(q2_target)

        # 计算每日指标需求（假设Q2需要达成月度新增翻倍）
        monthly_new_target_q2 = self.daily_new_users * 30 * 2  # 翻倍
        monthly_recall_target_q2 = self.daily_recall_users * 30 * 2  # 翻倍
        daily_metrics_q2 = self.calculate_daily_metrics_requirements(
            monthly_new_target_q2, monthly_recall_target_q2
        )

        # 计算成本分析
        cost_analysis = self.calculate_user_acquisition_costs()

        # 汇总场景
        scenario = {
            'scenario_name': scenario_name,
            'current_state': {
                'dau': self.current_dau,
                'daily_new_users': self.daily_new_users,
                'daily_recall_users': self.daily_recall_users,
                'structure_pct': {
                    'new_users': self.current_structure['new_users_pct'] * 100,
                    'recall_users': self.current_structure['recall_users_pct'] * 100,
                    'retained_users': self.current_structure['retained_users_pct'] * 100
                }
            },
            'annual_targets': {
                'dau_peak_2025': self.dau_peak_2025,
                'dau_target_2026': self.dau_target_2026,
                'growth_gap_analysis': self.growth_gap
            },
            'quarterly_targets': quarterly_targets,
            'q2_detailed_analysis': {
                'dau_target': q2_target,
                'components_growth': q2_analysis,
                'daily_metrics_requirements': daily_metrics_q2
            },
            'cost_analysis': cost_analysis,
            'key_insights': self._generate_key_insights()
        }

        return scenario

    def _generate_key_insights(self):
        """生成关键洞察"""
        insights = []

        # 结构失衡洞察
        if self.current_structure['new_users_pct'] < 0.05:
            insights.append("结构失衡：新用户占比过低（仅{:.1f}%），增长可持续性风险高".format(
                self.current_structure['new_users_pct'] * 100))

        if self.current_structure['recall_users_pct'] < 0.05:
            insights.append("召回贡献低：召回用户占比仅{:.1f}%，用户资产运营效率待提升".format(
                self.current_structure['recall_users_pct'] * 100))

        # 增长压力洞察
        total_gap = self.growth_gap['total_gap']
        if total_gap / self.current_dau > 0.5:
            insights.append("增长压力大：需要实现{:.1f}%的DAU增长，需多管齐下".format(
                self.growth_gap['total_pct']))

        # 恢复空间洞察
        if self.growth_gap['recovery_gap'] > 0:
            insights.append("恢复空间：需先恢复{:,}DAU至25年峰值水平".format(
                self.growth_gap['recovery_gap']))

        # 效率提升机会
        if self.daily_new_users > 0 and self.daily_recall_users > 0:
            new_per_dau = self.daily_new_users / self.current_dau
            recall_per_dau = self.daily_recall_users / self.current_dau

            if new_per_dau < 0.03:  # 新增占DAU比例低于3%
                insights.append("拉新效率：每日新增仅占DAU的{:.2f}%，需提升拉新规模或效率".format(new_per_dau * 100))

            if recall_per_dau < 0.03:
                insights.append("召回效率：每日召回仅占DAU的{:.2f}%，沉默用户运营有待加强".format(recall_per_dau * 100))

        return insights

    def print_detailed_report(self):
        """打印详细分析报告"""
        print("=" * 80)
        print("小蚕业务当前状态分析报告（基于2026年3月数据）")
        print("=" * 80)

        print(f"\n1. 当前状态（3月份）：")
        print(f"   日均DAU: {self.current_dau:,}")
        print(f"   每日新增注册用户: {self.daily_new_users:,}")
        print(f"   每日召回用户: {self.daily_recall_users:,}")
        print(f"   每日留存用户: {self.current_structure['retained_users_dau']:,}")

        print(f"\n2. 当前用户结构（DAU构成）：")
        print(f"   新用户占比: {self.current_structure['new_users_pct']*100:.2f}%")
        print(f"   召回用户占比: {self.current_structure['recall_users_pct']*100:.2f}%")
        print(f"   留存用户占比: {self.current_structure['retained_users_pct']*100:.2f}%")

        print(f"\n3. 增长目标分析：")
        print(f"   2025年DAU峰值: {self.dau_peak_2025:,}")
        print(f"   2026年DAU目标: {self.dau_target_2026:,} (增长{self.growth_target_pct*100:.0f}%)")
        print(f"   当前与峰值差距: {self.dau_peak_2025 - self.current_dau:,} (恢复空间)")
        print(f"   总增长缺口: {self.growth_gap['total_gap']:,}")
        print(f"   需要增长率: {self.growth_gap['total_pct']:.1f}%")

        print(f"\n4. 季度增长路径（从当前状态出发）：")
        quarterly_targets = self.calculate_quarterly_targets_from_current()
        for quarter, data in quarterly_targets.items():
            if quarter in ['Q2', 'Q3']:
                print(f"   {quarter}: DAU目标 {data['dau_target']:,} (增长{data['growth_pct']:.1f}%)")

        print(f"\n5. 第2季度详细增长需求：")
        q2_target = quarterly_targets['Q2']['dau_target']
        q2_analysis = self.analyze_dau_components_growth(q2_target)

        print(f"   Q2 DAU目标: {q2_target:,}")
        print(f"   用户结构优化目标：")
        print(f"     新用户占比: {q2_analysis['target_structure']['new_users_pct']*100:.1f}% "
              f"(当前: {q2_analysis['current_structure']['new_users_pct']*100:.2f}%)")
        print(f"     召回用户占比: {q2_analysis['target_structure']['recall_users_pct']*100:.1f}% "
              f"(当前: {q2_analysis['current_structure']['recall_users_pct']*100:.2f}%)")

        print(f"\n   各组成部分增长需求：")
        for component, growth in q2_analysis['growth_needed'].items():
            component_cn = {
                'new_users': '新用户',
                'recall_users': '召回用户',
                'retained_users': '留存用户'
            }[component]
            print(f"     {component_cn}: 需要增长 {growth:,}")

        print(f"\n   增长贡献度：")
        for component, contrib in q2_analysis['contribution_pct'].items():
            component_cn = {
                'new_users': '新用户',
                'recall_users': '召回用户',
                'retained_users': '留存用户'
            }[component]
            print(f"     {component_cn}: 贡献 {contrib:.1f}%")

        print(f"\n6. 每日指标提升需求：")
        # 假设Q2需要实现新增和召回翻倍
        monthly_new_target = self.daily_new_users * 30 * 2
        monthly_recall_target = self.daily_recall_users * 30 * 2
        daily_req = self.calculate_daily_metrics_requirements(monthly_new_target, monthly_recall_target)

        print(f"   新增用户：")
        print(f"     当前: {daily_req['current_daily_new']:,.0f}/日")
        print(f"     目标: {daily_req['target_daily_new']:,.0f}/日")
        print(f"     需提升: {daily_req['new_users_improvement']:.1f}倍")

        print(f"\n   召回用户：")
        print(f"     当前: {daily_req['current_daily_recall']:,.0f}/日")
        print(f"     目标: {daily_req['target_daily_recall']:,.0f}/日")
        print(f"     需提升: {daily_req['recall_improvement']:.1f}倍")

        print(f"\n7. 关键洞察与建议：")
        insights = self._generate_key_insights()
        for i, insight in enumerate(insights, 1):
            print(f"   {i}. {insight}")

        print(f"\n8. 战略建议重点：")
        print(f"   a. 结构优化：大幅提升新用户和召回用户占比")
        print(f"   b. 规模扩张：新增和召回量需翻倍增长")
        print(f"   c. 效率提升：降低获客成本，提升用户价值")
        print(f"   d. 留存加固：维持高留存用户基础")

        print("\n" + "=" * 80)
        print("下一步行动建议：")
        print("1. 立即启动第2季度增长项目，聚焦拉新和召回")
        print("2. 优化用户结构，目标新用户占比提升至10%")
        print("3. 建立日报监控机制，追踪核心指标进展")
        print("4. 资源配置向高ROI渠道倾斜")
        print("=" * 80)

def main():
    """主函数"""
    # 基于用户提供的3月份数据
    analyzer = XiaocanCurrentAnalysis(
        current_dau=940000,      # 94万DAU
        daily_new_users=20000,   # 每日新增2万+
        daily_recall_users=20000, # 每日召回2万+
        dau_peak_2025=1150000,   # 25年峰值115万
        growth_target_pct=0.5     # 增长50%
    )

    # 打印详细报告
    analyzer.print_detailed_report()

    # 生成增长场景分析（可选）
    print("\n\n9. 增长场景模拟分析：")
    print("-" * 40)
    scenario = analyzer.generate_growth_scenario("第2季度优化增长")

    print(f"场景: {scenario['scenario_name']}")
    print(f"Q2 DAU目标: {scenario['q2_detailed_analysis']['dau_target']:,}")

    # 显示成本分析摘要
    cost_analysis = scenario['cost_analysis']
    print(f"\n成本效率提升目标：")
    print(f"  新用户获取成本: ¥{cost_analysis['current_costs']['new_user_cac']:.1f} → "
          f"¥{cost_analysis['target_costs']['new_user_cac']:.1f} "
          f"(降低{cost_analysis['cost_efficiency_improvement']['new_user_pct']:.1f}%)")
    print(f"  召回用户成本: ¥{cost_analysis['current_costs']['recall_cac']:.1f} → "
          f"¥{cost_analysis['target_costs']['recall_cac']:.1f} "
          f"(降低{cost_analysis['cost_efficiency_improvement']['recall_user_pct']:.1f}%)")

    print("\n" + "=" * 80)
    print("分析完成时间: 2026年3月24日")
    print("数据来源: 用户提供的3月份实际运营数据")
    print("=" * 80)

if __name__ == "__main__":
    main()