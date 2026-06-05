#!/usr/bin/env python3
"""
更新钉钉文档中的平均差异数据
"""
import pandas as pd
import re

def update_report_average_gaps():
    """更新报告中的平均差异数据"""
    report_path = "analysis_reports/钉钉文档_小蚕用户美团下单频次分析_匹配类型分层版.md"

    print(f"正在读取报告: {report_path}")
    with open(report_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 正确的平均差异数据（来自计算）
    gap_data = {
        '高潜力用户': {
            '用户自己下单': 4.42,
            '用户美团数据可能异常': 4.28,
            '订单部分由其他用户下单': 5.44,
            '订单完全由其他有关系用户下单': 4.68
        },
        '中潜力用户': {
            '用户自己下单': 2.17,
            '用户美团数据可能异常': 2.0,
            '订单部分由其他用户下单': 2.47,
            '订单完全由其他有关系用户下单': 2.02
        },
        '低潜力用户': {
            '用户自己下单': 1.0,
            '用户美团数据可能异常': 1.0,
            '订单部分由其他用户下单': 1.0,
            '订单完全由其他有关系用户下单': 1.0
        }
    }

    # 1. 更新高潜力用户表格
    print("\n更新高潜力用户表格...")
    high_potential_pattern = r'(\|\s*\*\*用户自己下单\*\*\s*\|\s*41,468\s*\|\s*\*\*49\.9%\*\*\s*\|\s*)(\d+\.?\d*)(\s*单\s*\|)'
    content = re.sub(high_potential_pattern, r'\g<1>4.42\g<3>', content)

    high_potential_pattern2 = r'(\|\s*用户美团数据可能异常\s*\|\s*31,771\s*\|\s*38\.2%\s*\|\s*)(\d+\.?\d*)(\s*单\s*\|)'
    content = re.sub(high_potential_pattern2, r'\g<1>4.28\g<3>', content)

    high_potential_pattern3 = r'(\|\s*订单部分由其他用户下单\s*\|\s*5,654\s*\|\s*6\.8%\s*\|\s*)(\d+\.?\d*)(\s*单\s*\|)'
    content = re.sub(high_potential_pattern3, r'\g<1>5.44\g<3>', content)

    high_potential_pattern4 = r'(\|\s*订单完全由其他有关系用户下单\s*\|\s*4,255\s*\|\s*\*\*5\.1%\*\*\s*\|\s*)(\d+\.?\d*)(\s*单\s*\|)'
    content = re.sub(high_potential_pattern4, r'\g<1>4.68\g<3>', content)

    # 2. 更新中潜力用户表格
    print("更新中潜力用户表格...")
    medium_potential_pattern1 = r'(\|\s*\*\*用户自己下单\*\*\s*\|\s*39,794\s*\|\s*\*\*61\.3%\*\*\s*\|\s*)(\d+\.?\d*)(\s*单\s*\|)'
    content = re.sub(medium_potential_pattern1, r'\g<1>2.17\g<3>', content)

    medium_potential_pattern2 = r'(\|\s*用户美团数据可能异常\s*\|\s*20,358\s*\|\s*31\.4%\s*\|\s*)(\d+\.?\d*)(\s*单\s*\|)'
    content = re.sub(medium_potential_pattern2, r'\g<1>2.0\g<3>', content)

    medium_potential_pattern3 = r'(\|\s*订单部分由其他用户下单\s*\|\s*3,149\s*\|\s*4\.8%\s*\|\s*)(\d+\.?\d*)(\s*单\s*\|)'
    content = re.sub(medium_potential_pattern3, r'\g<1>2.47\g<3>', content)

    medium_potential_pattern4 = r'(\|\s*订单完全由其他有关系用户下单\s*\|\s*1,614\s*\|\s*\*\*2\.5%\*\*\s*\|\s*)(\d+\.?\d*)(\s*单\s*\|)'
    content = re.sub(medium_potential_pattern4, r'\g<1>2.02\g<3>', content)

    # 3. 低潜力用户表格保持不变（都是1.0单）

    # 4. 更新最高优先级用户的平均订单差异
    print("更新最高优先级用户的平均订单差异...")
    target_user_pattern = r'(平均订单差异：\*\*)(\d+\.?\d*)(单\*\*（美团比小蚕多）)'
    content = re.sub(target_user_pattern, r'\g<1>4.42\g<3>', content)

    # 5. 更新结论部分的描述
    print("更新结论部分的数据描述...")
    # 更新核心发现中的描述
    core_findings_pattern = r'(美团消费比小蚕多)(\d+\.?\d*)(单以上)'
    content = re.sub(core_findings_pattern, r'\g<1>4.5\g<3>', content)

    # 6. 更新核心发现中的百分比描述（如果需要）
    # 高潜力用户中自己下单的百分比描述

    # 保存更新后的报告
    output_path = "analysis_reports/钉钉文档_小蚕用户美团下单频次分析_匹配类型分层版_修正版.md"
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f"\n报告已更新并保存到: {output_path}")

    # 验证更新
    print("\n验证更新内容:")
    print("- 高潜力用户平均差异:")
    print("  • 用户自己下单: 4.42单 (原4.45单)")
    print("  • 用户美团数据可能异常: 4.28单 (原4.45单)")
    print("  • 订单部分由其他用户下单: 5.44单 (原4.45单)")
    print("  • 订单完全由其他有关系用户下单: 4.68单 (原4.45单)")

    print("\n- 中潜力用户平均差异:")
    print("  • 用户自己下单: 2.17单 (原2.13单)")
    print("  • 用户美团数据可能异常: 2.0单 (原2.13单)")
    print("  • 订单部分由其他用户下单: 2.47单 (原2.13单)")
    print("  • 订单完全由其他有关系用户下单: 2.02单 (原2.13单)")

    print("\n- 最高优先级用户:")
    print("  • 平均订单差异: 4.42单 (原4.45单)")

if __name__ == "__main__":
    update_report_average_gaps()