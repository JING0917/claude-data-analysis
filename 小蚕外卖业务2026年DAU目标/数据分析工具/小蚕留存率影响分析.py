#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
小蚕留存率影响分析与增长模拟
基于实际留存率数据：新用户次2日留存21%，召回用户次2日留存15.6%
"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta

class RetentionImpactAnalyzer:
    """留存率影响分析器"""

    def __init__(self, daily_new_users=20000, daily_recall_users=20000,
                 new_user_d2_retention=0.21, recall_user_d2_retention=0.156,
                 current_dau=940000, target_dau=1725000):
        """
        初始化分析器

        Parameters:
        -----------
        daily_new_users : int
            每日新增注册用户
        daily_recall_users : int
            每日召回用户
        new_user_d2_retention : float
            新用户次2日留存率
        recall_user_d2_retention : float
            召回用户次2日留存率
        current_dau : int
            当前DAU
        target_dau : int
            目标DAU
        """
        self.daily_new = daily_new_users
        self.daily_recall = daily_recall_users
        self.new_d2_retention = new_user_d2_retention
        self.recall_d2_retention = recall_user_d2_retention
        self.current_dau = current_dau
        self.target_dau = target_dau

        # 计算增长缺口
        self.growth_gap = target_dau - current_dau

        # 行业基准留存率（用于对比）
        self.benchmark_retention = {
            'new_user_d2': 0.35,  # 行业平均次2日留存
            'new_user_d7': 0.25,  # 7日留存
            'new_user_d30': 0.15,  # 30日留存
            'recall_user_d2': 0.25,  # 召回用户次2日留存
            'recall_user_d7': 0.18,  # 召回用户7日留存
            'recall_user_d30': 0.10   # 召回用户30日留存
        }

    def analyze_retention_gap(self):
        """分析留存率差距"""
        gaps = {
            'new_user_d2_gap': self.new_d2_retention - self.benchmark_retention['new_user_d2'],
            'new_user_d2_gap_pct': (self.new_d2_retention - self.benchmark_retention['new_user_d2']) / self.benchmark_retention['new_user_d2'] * 100,
            'recall_user_d2_gap': self.recall_d2_retention - self.benchmark_retention['recall_user_d2'],
            'recall_user_d2_gap_pct': (self.recall_d2_retention - self.benchmark_retention['recall_user_d2']) / self.benchmark_retention['recall_user_d2'] * 100
        }

        # 计算留存率提升的潜在影响
        potential_impact = self._calculate_retention_improvement_impact()

        return {
            'current_retention': {
                'new_user_d2': self.new_d2_retention,
                'recall_user_d2': self.recall_d2_retention
            },
            'benchmark_retention': self.benchmark_retention,
            'gaps': gaps,
            'potential_impact': potential_impact
        }

    def _calculate_retention_improvement_impact(self):
        """计算留存率提升的潜在影响"""
        # 假设提升到行业平均水平的潜在收益
        improved_new_retention = self.benchmark_retention['new_user_d2']
        improved_recall_retention = self.benchmark_retention['recall_user_d2']

        # 计算每日活跃用户增量（基于留存率提升）
        # 简化模型：假设用户活跃30天，留存率提升会增加每日活跃用户数
        daily_new_active_increase = self.daily_new * (improved_new_retention - self.new_d2_retention) * 30 * 0.5
        daily_recall_active_increase = self.daily_recall * (improved_recall_retention - self.recall_d2_retention) * 30 * 0.5

        total_dau_increase = daily_new_active_increase + daily_recall_active_increase

        # 计算对增长目标的贡献度
        contribution_to_gap = total_dau_increase / self.growth_gap * 100 if self.growth_gap > 0 else 0

        return {
            'daily_new_active_increase': daily_new_active_increase,
            'daily_recall_active_increase': daily_recall_active_increase,
            'total_dau_increase': total_dau_increase,
            'contribution_to_growth_gap': contribution_to_gap,
            'new_retention_target': improved_new_retention,
            'recall_retention_target': improved_recall_retention
        }

    def simulate_user_cohort_analysis(self, days=30):
        """模拟用户队列分析"""
        # 模拟新用户队列的留存情况
        cohorts = []
        for day in range(days):
            # 第day天的新用户
            cohort_size = self.daily_new
            day1_active = cohort_size  # 第1天100%活跃（假设）

            # 计算后续日子的活跃用户数（简化模型）
            # 使用次2日留存率作为每日衰减的近似
            daily_retention_rate = self.new_d2_retention ** (1/1)  # 简化：假设每日留存率一致

            cohort_data = {
                'cohort_day': day,
                'cohort_size': cohort_size,
                'day1_active': day1_active,
                'day2_active': cohort_size * self.new_d2_retention,
                'day7_active': cohort_size * (self.new_d2_retention ** 6),  # 近似
                'day30_active': cohort_size * (self.new_d2_retention ** 29)  # 近似
            }
            cohorts.append(cohort_data)

        # 计算第30天的DAU构成（来自过去30天的队列）
        dau_from_new_users = sum([cohort['day30_active'] for cohort in cohorts[:30]])

        # 类似计算召回用户
        recall_cohorts = []
        for day in range(days):
            cohort_size = self.daily_recall
            recall_cohort_data = {
                'cohort_day': day,
                'cohort_size': cohort_size,
                'day1_active': cohort_size,
                'day2_active': cohort_size * self.recall_d2_retention,
                'day7_active': cohort_size * (self.recall_d2_retention ** 6),
                'day30_active': cohort_size * (self.recall_d2_retention ** 29)
            }
            recall_cohorts.append(recall_cohort_data)

        dau_from_recall_users = sum([cohort['day30_active'] for cohort in recall_cohorts[:30]])

        # 估计留存用户（当前DAU - 新用户贡献 - 召回用户贡献）
        estimated_retained_dau = self.current_dau - dau_from_new_users - dau_from_recall_users

        return {
            'dau_decomposition_estimated': {
                'from_new_users': dau_from_new_users,
                'from_recall_users': dau_from_recall_users,
                'from_retained_users': estimated_retained_dau,
                'new_users_pct': dau_from_new_users / self.current_dau * 100,
                'recall_users_pct': dau_from_recall_users / self.current_dau * 100,
                'retained_users_pct': estimated_retained_dau / self.current_dau * 100
            },
            'cohort_analysis': {
                'new_user_cohorts': cohorts[:5],  # 只显示前5个队列示例
                'recall_user_cohorts': recall_cohorts[:5]
            }
        }

    def calculate_retention_improvement_scenarios(self):
        """计算留存率提升的不同场景"""
        scenarios = []

        # 场景1：小幅提升（提升20%）
        scenario1 = {
            'name': '小幅提升（+20%）',
            'new_retention': min(1.0, self.new_d2_retention * 1.2),
            'recall_retention': min(1.0, self.recall_d2_retention * 1.2),
            'timeframe': 'Q2'
        }

        # 场景2：中等提升（提升50%）
        scenario2 = {
            'name': '中等提升（+50%）',
            'new_retention': min(1.0, self.new_d2_retention * 1.5),
            'recall_retention': min(1.0, self.recall_d2_retention * 1.5),
            'timeframe': 'Q3'
        }

        # 场景3：达到行业平均
        scenario3 = {
            'name': '行业平均水平',
            'new_retention': self.benchmark_retention['new_user_d2'],
            'recall_retention': self.benchmark_retention['recall_user_d2'],
            'timeframe': 'Q4'
        }

        scenarios = [scenario1, scenario2, scenario3]

        # 计算每个场景的DAU影响
        for scenario in scenarios:
            impact = self._calculate_scenario_impact(
                scenario['new_retention'],
                scenario['recall_retention']
            )
            scenario.update(impact)

        return scenarios

    def _calculate_scenario_impact(self, new_retention_target, recall_retention_target):
        """计算场景影响"""
        # 计算DAU增量（简化模型）
        # 假设影响过去30天的新用户和召回用户
        days_affected = 30

        # 新用户DAU增量
        new_user_dau_increase = self.daily_new * days_affected * (new_retention_target - self.new_d2_retention) * 0.5

        # 召回用户DAU增量
        recall_user_dau_increase = self.daily_recall * days_affected * (recall_retention_target - self.recall_d2_retention) * 0.5

        total_dau_increase = new_user_dau_increase + recall_user_dau_increase

        # 计算对增长目标的贡献
        contribution = total_dau_increase / self.growth_gap * 100 if self.growth_gap > 0 else 0

        # 计算所需提升幅度
        new_retention_improvement_pct = (new_retention_target - self.new_d2_retention) / self.new_d2_retention * 100
        recall_retention_improvement_pct = (recall_retention_target - self.recall_d2_retention) / self.recall_d2_retention * 100

        return {
            'new_user_dau_increase': new_user_dau_increase,
            'recall_user_dau_increase': recall_user_dau_increase,
            'total_dau_increase': total_dau_increase,
            'contribution_to_growth': contribution,
            'new_retention_improvement_pct': new_retention_improvement_pct,
            'recall_retention_improvement_pct': recall_retention_improvement_pct
        }

    def generate_retention_optimization_strategy(self):
        """生成留存率优化策略"""
        strategies = []

        # 新用户留存优化策略
        new_user_strategies = [
            {
                'name': '新手引导优化',
                'target_metric': 'new_user_d2_retention',
                'target_improvement': 0.05,  # 提升5个百分点
                'estimated_impact': self.daily_new * 30 * 0.05 * 0.5,
                'priority': 'P0',
                'quarter': 'Q2'
            },
            {
                'name': '首单体验优化',
                'target_metric': 'new_user_d2_retention',
                'target_improvement': 0.03,
                'estimated_impact': self.daily_new * 30 * 0.03 * 0.5,
                'priority': 'P0',
                'quarter': 'Q2'
            },
            {
                'name': '个性化推荐',
                'target_metric': 'new_user_d2_retention',
                'target_improvement': 0.04,
                'estimated_impact': self.daily_new * 30 * 0.04 * 0.5,
                'priority': 'P1',
                'quarter': 'Q3'
            }
        ]

        # 召回用户留存优化策略
        recall_user_strategies = [
            {
                'name': '召回内容个性化',
                'target_metric': 'recall_user_d2_retention',
                'target_improvement': 0.04,
                'estimated_impact': self.daily_recall * 30 * 0.04 * 0.5,
                'priority': 'P0',
                'quarter': 'Q2'
            },
            {
                'name': '召回时机优化',
                'target_metric': 'recall_user_d2_retention',
                'target_improvement': 0.03,
                'estimated_impact': self.daily_recall * 30 * 0.03 * 0.5,
                'priority': 'P1',
                'quarter': 'Q2'
            },
            {
                'name': '回流用户专属权益',
                'target_metric': 'recall_user_d2_retention',
                'target_improvement': 0.05,
                'estimated_impact': self.daily_recall * 30 * 0.05 * 0.5,
                'priority': 'P1',
                'quarter': 'Q3'
            }
        ]

        # 计算策略总影响
        total_impact_new = sum([s['estimated_impact'] for s in new_user_strategies])
        total_impact_recall = sum([s['estimated_impact'] for s in recall_user_strategies])
        total_impact = total_impact_new + total_impact_recall

        return {
            'new_user_strategies': new_user_strategies,
            'recall_user_strategies': recall_user_strategies,
            'total_impact': {
                'new_user_dau_increase': total_impact_new,
                'recall_user_dau_increase': total_impact_recall,
                'total_dau_increase': total_impact,
                'contribution_to_growth': total_impact / self.growth_gap * 100 if self.growth_gap > 0 else 0
            }
        }

    def print_comprehensive_analysis(self):
        """打印综合分析报告"""
        print("=" * 80)
        print("小蚕留存率影响综合分析报告")
        print("=" * 80)

        print(f"\n1. 当前留存率状况：")
        print(f"   新用户次2日留存率: {self.new_d2_retention*100:.1f}%")
        print(f"   召回用户次2日留存率: {self.recall_d2_retention*100:.1f}%")

        print(f"\n2. 与行业基准对比：")
        retention_gap = self.analyze_retention_gap()
        print(f"   新用户留存率差距: {retention_gap['gaps']['new_user_d2_gap_pct']:+.1f}%")
        print(f"   召回用户留存率差距: {retention_gap['gaps']['recall_user_d2_gap_pct']:+.1f}%")
        print(f"   行业基准新用户留存: {self.benchmark_retention['new_user_d2']*100:.1f}%")
        print(f"   行业基准召回用户留存: {self.benchmark_retention['recall_user_d2']*100:.1f}%")

        print(f"\n3. 留存率提升的潜在影响：")
        impact = retention_gap['potential_impact']
        print(f"   预计DAU增量: {impact['total_dau_increase']:,.0f}")
        print(f"   对增长目标的贡献: {impact['contribution_to_growth_gap']:.1f}%")
        print(f"   其中新用户贡献: {impact['daily_new_active_increase']:,.0f}")
        print(f"   召回用户贡献: {impact['daily_recall_active_increase']:,.0f}")

        print(f"\n4. 用户队列分析（估算）：")
        cohort_analysis = self.simulate_user_cohort_analysis()
        decomposition = cohort_analysis['dau_decomposition_estimated']
        print(f"   DAU构成估算：")
        print(f"     来自新用户: {decomposition['from_new_users']:,.0f} ({decomposition['new_users_pct']:.1f}%)")
        print(f"     来自召回用户: {decomposition['from_recall_users']:,.0f} ({decomposition['recall_users_pct']:.1f}%)")
        print(f"     来自留存用户: {decomposition['from_retained_users']:,.0f} ({decomposition['retained_users_pct']:.1f}%)")

        print(f"\n5. 留存率提升场景模拟：")
        scenarios = self.calculate_retention_improvement_scenarios()
        for scenario in scenarios:
            print(f"\n   {scenario['name']} ({scenario['timeframe']}):")
            print(f"     新用户留存目标: {scenario['new_retention']*100:.1f}% "
                  f"(提升{scenario['new_retention_improvement_pct']:+.1f}%)")
            print(f"     召回用户留存目标: {scenario['recall_retention']*100:.1f}% "
                  f"(提升{scenario['recall_retention_improvement_pct']:+.1f}%)")
            print(f"     预计DAU增量: {scenario['total_dau_increase']:,.0f}")
            print(f"     对增长目标贡献: {scenario['contribution_to_growth']:.1f}%")

        print(f"\n6. 留存率优化策略建议：")
        strategy = self.generate_retention_optimization_strategy()

        print(f"   新用户留存优化策略（P0优先级）：")
        for s in strategy['new_user_strategies']:
            if s['priority'] == 'P0':
                print(f"     • {s['name']}: 目标提升{s['target_improvement']*100:.1f}个百分点")
                print(f"       预计DAU增量: {s['estimated_impact']:,.0f}, 季度: {s['quarter']}")

        print(f"\n   召回用户留存优化策略（P0优先级）：")
        for s in strategy['recall_user_strategies']:
            if s['priority'] == 'P0':
                print(f"     • {s['name']}: 目标提升{s['target_improvement']*100:.1f}个百分点")
                print(f"       预计DAU增量: {s['estimated_impact']:,.0f}, 季度: {s['quarter']}")

        print(f"\n7. 策略总影响估算：")
        total = strategy['total_impact']
        print(f"   总DAU增量: {total['total_dau_increase']:,.0f}")
        print(f"   对增长目标贡献: {total['contribution_to_growth']:.1f}%")
        print(f"   其中：")
        print(f"     新用户策略贡献: {total['new_user_dau_increase']:,.0f}")
        print(f"     召回用户策略贡献: {total['recall_user_dau_increase']:,.0f}")

        print(f"\n8. 关键洞察：")
        insights = [
            "新用户留存率(21%)显著低于行业基准(35%)，提升空间巨大",
            "召回用户留存率(15.6%)更低，表明召回后的激活不足",
            "留存率提升对DAU增长的杠杆效应显著，应作为Q2重点",
            "当前用户结构失衡（新用户仅占2.1%），改善留存可优化结构",
            "留存率每提升10%，可带来约数万DAU的增量"
        ]

        for i, insight in enumerate(insights, 1):
            print(f"   {i}. {insight}")

        print(f"\n9. 第2季度留存优化重点项目建议：")
        print(f"   a. 新手引导流程重设计（目标：新用户留存提升至25%）")
        print(f"   b. 召回内容个性化系统（目标：召回留存提升至20%）")
        print(f"   c. 首单保障与激励计划（目标：新用户留存提升5个百分点）")
        print(f"   d. 回流用户专属活动体系（目标：召回留存提升4个百分点）")

        print(f"\n10. 实施建议：")
        print(f"    • 建立留存率日报机制，监控每日变化")
        print(f"    • 开展A/B测试，快速验证优化效果")
        print(f"    • 新用户与召回用户分层运营，差异化策略")
        print(f"    • 留存率指标纳入团队考核（产品+运营）")

        print("\n" + "=" * 80)
        print("分析结论：")
        print("1. 留存率是当前增长的瓶颈，也是最大的机会点")
        print("2. 新用户留存率提升应作为Q2最高优先级")
        print("3. 召回用户留存率优化可快速见效，应同步推进")
        print("4. 留存率提升可与拉新扩量形成增长飞轮")
        print("=" * 80)

def main():
    """主函数"""
    analyzer = RetentionImpactAnalyzer(
        daily_new_users=20000,
        daily_recall_users=20000,
        new_user_d2_retention=0.21,      # 21%
        recall_user_d2_retention=0.156,   # 15.6%
        current_dau=940000,
        target_dau=1725000
    )

    analyzer.print_comprehensive_analysis()

    print("\n" + "=" * 80)
    print("数据说明：")
    print("1. 当前数据：2026年3月实际运营数据")
    print("2. 行业基准：基于外卖/本地生活行业平均水平")
    print("3. 影响估算：采用简化模型，实际效果可能有所差异")
    print("4. 建议优先级：基于业务影响和实施难度综合评估")
    print("=" * 80)

if __name__ == "__main__":
    main()