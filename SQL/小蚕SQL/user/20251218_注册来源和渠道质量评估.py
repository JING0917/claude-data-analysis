
# 2. 导入基础库
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

# 解决中文乱码
plt.rcParams['font.sans-serif'] = ['WenQuanYi Zen Hei']
plt.rcParams['axes.unicode_minus'] = False


# 3. 直接读取Excel的“整体”Sheet（不绕弯）
def read_excel_direct():
    # 固定文件名，直接读取
    excel_name = "20251218_各渠道注册用户花费和收益_大禾.xlsx"
    try:
        # 优先读“整体”Sheet（用户说整体是日数据聚合）
        df = pd.read_excel(excel_name, sheet_name='整体')
        print(f"✅ 成功读取「整体」Sheet，共{len(df)}行数据")
        
        # 必须包含的核心字段（少一个就提示）
        required_cols = ['注册渠道', '注册用户量', '渠道拉新支出', '近30日内营销支出', '近30日内订单利润', '次3日访问留存率', '次7日访问留存率', '次30日访问留存率']
        missing_cols = [col for col in required_cols if col not in df.columns]
        if missing_cols:
            print(f"❌ 「整体」Sheet缺字段：{missing_cols}，请检查文件")
            return None
        
        # 清洗无效数据（注册量/支出/利润不能为0或负）
        df['总支出'] = df['渠道拉新支出'] + df['近30日内营销支出']
        df_clean = df[
            (df['注册用户量'] > 0) & 
            (df['总支出'] > 0) & 
            (df['近30日内订单利润'] >= 0)
        ]
        print(f"✅ 数据清洗完成，有效渠道数：{df_clean['注册渠道'].nunique()}")
        return df_clean
    
    except Exception as e:
        print(f"❌ 读取失败：{str(e)[:50]}，请确认Excel在当前目录且「整体」Sheet存在")
        return None


# 4. 计算核心指标（严格按用户ROI公式）
def calc_key_metrics(df):
    # 重命名列，方便后续使用
    df_metrics = df.rename(columns={
        '注册用户量': '总注册量',
        '渠道拉新支出': '拉新支出(元)',
        '近30日内营销支出': '营销支出(元)',
        '近30日内订单利润': '利润(元)',
        '次3日访问留存率': '3日留存率',
        '次7日访问留存率': '7日留存率',
        '次30日访问留存率': '30日留存率'
    })
    
    # 计算指标（用户公式：ROI=利润/(拉新+营销)×100%）
    df_metrics['总支出(元)'] = df_metrics['拉新支出(元)'] + df_metrics['营销支出(元)']
    df_metrics['ROI(%)'] = (df_metrics['利润(元)'] / df_metrics['总支出(元)'] * 100).round(2)
    df_metrics['CAC(元/人)'] = (df_metrics['总支出(元)'] / df_metrics['总注册量']).round(2)
    df_metrics['ARPU(元/人)'] = (df_metrics['利润(元)'] / df_metrics['总注册量']).round(2)
    
    # 按总注册量降序，方便看主要渠道
    df_metrics = df_metrics.sort_values('总注册量', ascending=False).reset_index(drop=True)
    
    # 打印指标表（清晰展示）
    print("\n" + "="*100)
    print("📊 各渠道核心指标表")
    print("="*100)
    display_cols = ['注册渠道', '总注册量', '总支出(元)', '利润(元)', 'ROI(%)', 'CAC(元/人)', 'ARPU(元/人)', '30日留存率']
    print(df_metrics[display_cols].to_string(index=False))
    
    # 保存到Excel（当前目录）
    df_metrics[display_cols].to_excel('渠道核心指标结果.xlsx', index=False)
    print(f"\n✅ 指标表已保存：渠道核心指标结果.xlsx")
    return df_metrics


# 5. 画3张关键图表（简洁直观）
def draw_simple_charts(df):
    # 图1：ROI对比（红负绿正）
    plt.figure(figsize=(10, 5))
    df_roi = df.sort_values('ROI(%)', ascending=False)
    colors = ['#22c55e' if x >= 0 else '#ef4444' for x in df_roi['ROI(%)']]
    plt.bar(df_roi['注册渠道'], df_roi['ROI(%)'], color=colors, alpha=0.8)
    plt.axhline(y=0, color='black', linestyle='-', alpha=0.6, label='盈利边界(ROI=0)')
    plt.title('各渠道投资回报率(ROI)对比', fontsize=12, fontweight='bold')
    plt.xlabel('注册渠道')
    plt.ylabel('ROI(%)')
    plt.xticks(rotation=45, ha='right')
    plt.legend()
    plt.tight_layout()
    plt.savefig('渠道ROI图.png', dpi=300)
    plt.close()
    print("✅ ROI图已保存：渠道ROI图.png")
    
    # 图2：30日留存率对比（按留存降序）
    plt.figure(figsize=(10, 5))
    df_ret = df.sort_values('30日留存率', ascending=False)
    plt.bar(df_ret['注册渠道'], df_ret['30日留存率']*100, color='#3b82f6', alpha=0.8)
    plt.title('各渠道30日留存率对比', fontsize=12, fontweight='bold')
    plt.xlabel('注册渠道')
    plt.ylabel('30日留存率(%)')
    plt.xticks(rotation=45, ha='right')
    plt.tight_layout()
    plt.savefig('渠道30日留存图.png', dpi=300)
    plt.close()
    print("✅ 30日留存图已保存：渠道30日留存图.png")
    
    # 图3：CAC vs ARPU（成本vs价值）
    plt.figure(figsize=(10, 5))
    x = np.arange(len(df))
    width = 0.35
    plt.bar(x - width/2, df['CAC(元/人)'], width, label='CAC(获客成本)', color='#f59e0b', alpha=0.8)
    plt.bar(x + width/2, df['ARPU(元/人)'], width, label='ARPU(单用户价值)', color='#10b981', alpha=0.8)
    plt.title('各渠道CAC与ARPU对比', fontsize=12, fontweight='bold')
    plt.xlabel('注册渠道')
    plt.ylabel('金额(元)')
    plt.xticks(x, df['注册渠道'], rotation=45, ha='right')
    plt.legend()
    plt.tight_layout()
    plt.savefig('渠道CAC-ARPU图.png', dpi=300)
    plt.close()
    print("✅ CAC-ARPU图已保存：渠道CAC-ARPU图.png")


# 6. 输出简单结论（直接给行动建议）
def get_clear_conclusion(df):
    print("\n" + "="*100)
    print("🎯 分析结论与行动建议")
    print("="*100)
    
    # 优质渠道：ROI>20% 且 30日留存>10%（高盈利+高活跃）
    good_ch = df[(df['ROI(%)'] > 20) & (df['30日留存率'] > 0.1)]['注册渠道'].tolist()
    # 风险渠道：ROI<0 或 30日留存<5%（亏损/低质量）
    bad_ch = df[(df['ROI(%)'] < 0) | (df['30日留存率'] < 0.05)]['注册渠道'].tolist()
    # 潜力渠道：剩下的（需优化）
    mid_ch = [ch for ch in df['注册渠道'] if ch not in good_ch + bad_ch]
    
    print(f"1. 🌟 优质渠道（建议加预算20%-30%）：{good_ch if good_ch else '暂无'}")
    print(f"2. ⚠️  风险渠道（建议暂停/减预算80%）：{bad_ch if bad_ch else '暂无'}")
    print(f"3. ⚡ 潜力渠道（建议1个月优化测试）：{mid_ch if mid_ch else '暂无'}")
    print("="*100)


# 7. 一键跑完全流程（不用改任何东西）
def run_all():
    # 步骤1：读数据
    df_clean = read_excel_direct()
    if df_clean is None or len(df_clean) == 0:
        print("❌ 没有有效数据，分析终止")
        return
    
    # 步骤2：算指标
    df_metrics = calc_key_metrics(df_clean)
    
    # 步骤3：画图
    draw_simple_charts(df_metrics)
    
    # 步骤4：给结论
    get_clear_conclusion(df_metrics)
    
    print("\n🎉 所有分析完成！文件都在Jupyter当前目录～")


# 启动分析（点运行就完事）
run_all()