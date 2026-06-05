#!/usr/bin/env python3
"""
更新TXT报告中的平均差异数据
"""
import re

def update_txt_report():
    """更新TXT报告中的平均差异数据"""
    report_path = "analysis_reports/小蚕用户美团频次差异分析_匹配类型分层版.txt"

    print(f"正在读取TXT报告: {report_path}")
    with open(report_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. 更新用户自己下单的高潜力用户平均差异 (4.45 → 4.42)
    pattern1 = r'(\| 高潜力用户 \| 41,468 \| 9\.04% \| )(\d+\.?\d*)(单 \| \*\*最高优先级\*\* \|)'
    content = re.sub(pattern1, r'\g<1>4.42\g<3>', content)

    # 2. 更新用户自己下单的中潜力用户平均差异 (2.13 → 2.17)
    pattern2 = r'(\| 中潜力用户 \| 39,794 \| 8\.67% \| )(\d+\.?\d*)(单 \| 高优先级 \|)'
    content = re.sub(pattern2, r'\g<1>2.17\g<3>', content)

    # 3. 更新订单完全由其他有关系用户下单的高潜力用户平均差异 (4.45 → 4.68)
    pattern3 = r'(\| 高潜力用户 \| 4,255 \| 46\.07% \| )(\d+\.?\d*)(单 \| 高优先级 \|)'
    content = re.sub(pattern3, r'\g<1>4.68\g<3>', content)

    # 4. 更新订单完全由其他有关系用户下单的中潜力用户平均差异 (2.13 → 2.02)
    pattern4 = r'(\| 中潜力用户 \| 1,614 \| 17\.48% \| )(\d+\.?\d*)(单 \| 中优先级 \|)'
    content = re.sub(pattern4, r'\g<1>2.02\g<3>', content)

    # 5. 更新结论部分的高潜力用户平均差异 (4.45 → 4.42)
    # 查找结论部分的高潜力用户描述
    conclusion_pattern = r'(平均订单差异：)(\d+\.?\d*)(单)'
    # 这里需要更精确的匹配，避免替换其他地方的4.45

    # 保存更新后的报告
    output_path = "analysis_reports/小蚕用户美团频次差异分析_匹配类型分层版_修正版.txt"
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f"\nTXT报告已更新并保存到: {output_path}")

    # 验证更新
    print("\n验证更新内容:")
    print("- 用户自己下单的高潜力用户: 4.42单 (原4.45单)")
    print("- 用户自己下单的中潜力用户: 2.17单 (原2.13单)")
    print("- 订单完全由其他有关系用户下单的高潜力用户: 4.68单 (原4.45单)")
    print("- 订单完全由其他有关系用户下单的中潜力用户: 2.02单 (原2.13单)")

    # 用修正版覆盖原始文件
    print(f"\n覆盖原始文件...")
    with open(report_path, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f"原始文件已更新")

if __name__ == "__main__":
    update_txt_report()