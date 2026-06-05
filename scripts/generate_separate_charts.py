import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
import numpy as np

plt.rcParams['font.family'] = ['Arial Unicode MS', 'PingFang SC', 'Heiti SC', 'sans-serif']
plt.rcParams['axes.unicode_minus'] = False

file_path = 'data_storage/开放平台活动销单日趋势.xlsx'

df1 = pd.read_excel(file_path, sheet_name='开放平台活动销单日趋势')
df3 = pd.read_excel(file_path, sheet_name='开放平台报名转化')

df1['统计日期'] = pd.to_datetime(df1['统计日期'])
df3['dt'] = pd.to_datetime(df3['dt'])

m = df1.merge(df3, left_on='统计日期', right_on='dt', how='left')

m['晓晓有效订单'] = m['开放平台有效订单量'] - m['有效订单量']
m['小蚕人均报名订单量'] = m['报名订单量'] / m['报名用户量']
m['小蚕下单完单率'] = m['有效订单量'] / m['报名订单量']
m['小蚕报名完单率'] = m['有效订单量'] / m['报名用户量']
m['小蚕占比'] = m['有效订单量'] / m['开放平台有效订单量']
m['销单率_pct'] = m['开放平台销单率'] * 100

dates = m['统计日期']

COLORS = {
    'xiaocan': '#4C72B0',
    'xiaoxiao': '#DD8452',
    'rate_line': '#E74C3C',
    'rate_line2': '#2ECC71',
    'bar_light': '#A8C5E8',
}

# ============================================================
# Chart 1: 渠道拆解 + 销单率
# ============================================================
fig1, ax1a = plt.subplots(figsize=(14, 7))

bars1 = ax1a.bar(dates, m['晓晓有效订单'], color=COLORS['xiaoxiao'], label='晓晓本平台订单', width=0.7)
bars2 = ax1a.bar(dates, m['有效订单量'], bottom=m['晓晓有效订单'], color=COLORS['xiaocan'], label='小蚕分发订单', width=0.7)

ax1b = ax1a.twinx()
line1, = ax1b.plot(dates, m['销单率_pct'], color=COLORS['rate_line'], linewidth=2.5, marker='o', markersize=5, label='销单率', zorder=5)

ax1a.set_title('开放平台双渠道订单量与销单率趋势', fontsize=16, fontweight='bold', pad=15)
ax1a.set_xlabel('日期', fontsize=12)
ax1a.set_ylabel('有效订单量', fontsize=12)
ax1b.set_ylabel('销单率 (%)', fontsize=12)
ax1a.yaxis.set_major_formatter(mticker.FuncFormatter(lambda x, _: f'{x:,.0f}'))

bars_all = [bars1, bars2, line1]
labels_all = ['晓晓本平台订单', '小蚕分发订单', '销单率']
ax1a.legend(bars_all, labels_all, loc='upper left', fontsize=10, frameon=True)

ax1b.set_ylim(0, 100)

ax1a.grid(axis='y', alpha=0.3)
ax1a.set_xlim(dates.iloc[0] - pd.Timedelta(days=0.5), dates.iloc[-1] + pd.Timedelta(days=0.5))
fig1.autofmt_xdate(rotation=30)
fig1.tight_layout()
fig1.savefig('analysis_reports/chart1_渠道拆解_销单率.png', dpi=150, bbox_inches='tight')
plt.close(fig1)
print('Chart 1 saved.')

# ============================================================
# Chart 2: 小蚕人均报名订单量 (line on TOP of bars)
# ============================================================
fig2, ax2a = plt.subplots(figsize=(14, 7))

bars_vol = ax2a.bar(dates, m['报名用户量'] / 10000, color=COLORS['bar_light'], label='报名用户量（万）', width=0.7, zorder=1)

ax2b = ax2a.twinx()
line_per_capita, = ax2b.plot(dates, m['小蚕人均报名订单量'], color=COLORS['rate_line'], linewidth=2.5, marker='s', markersize=6, label='人均报名订单量', zorder=10)

# Also bring the axis line and markers to front
ax2b.set_zorder(ax2a.get_zorder() + 1)
ax2b.patch.set_visible(False)

y_min = m['小蚕人均报名订单量'].min()
y_max = m['小蚕人均报名订单量'].max()
ax2b.set_ylim(y_min - (y_max - y_min) * 0.3, y_max + (y_max - y_min) * 0.3)

# Value labels
for i, (d, v) in enumerate(zip(dates, m['小蚕人均报名订单量'])):
    if i % 3 == 0:
        ax2b.annotate(f'{v:.3f}', xy=(d, v), xytext=(0, 10), textcoords='offset points',
                      fontsize=8, color=COLORS['rate_line'], ha='center')

# Mean reference line
mean_val = m['小蚕人均报名订单量'].mean()
ax2b.axhline(y=mean_val, color='gray', linestyle='--', linewidth=1, alpha=0.6)
ax2b.text(dates.iloc[-1], mean_val, f'均值 {mean_val:.3f}', fontsize=9, color='gray',
          va='bottom', ha='right', alpha=0.8)

ax2a.set_title('小蚕分发渠道：人均报名订单量趋势', fontsize=16, fontweight='bold', pad=15)
ax2a.set_xlabel('日期', fontsize=12)
ax2a.set_ylabel('报名用户量（万）', fontsize=12)
ax2b.set_ylabel('人均报名订单量', fontsize=12)

bars_handles = [bars_vol, line_per_capita]
bars_labels = ['报名用户量（万）', '人均报名订单量']
ax2a.legend(bars_handles, bars_labels, loc='upper left', fontsize=10, frameon=True)

ax2a.grid(axis='y', alpha=0.3)
ax2a.set_xlim(dates.iloc[0] - pd.Timedelta(days=0.5), dates.iloc[-1] + pd.Timedelta(days=0.5))
fig2.autofmt_xdate(rotation=30)
fig2.tight_layout()
fig2.savefig('analysis_reports/chart2_人均报名订单量.png', dpi=150, bbox_inches='tight')
plt.close(fig2)
print('Chart 2 saved.')

# ============================================================
# Chart 3: 下单→完单率 + 报名→完单率
# ============================================================
fig3, ax3 = plt.subplots(figsize=(14, 7))

pct_order_complete = m['小蚕下单完单率'] * 100
pct_signup_complete = m['小蚕报名完单率'] * 100

line_oc, = ax3.plot(dates, pct_order_complete, color=COLORS['rate_line'], linewidth=2.5,
                     marker='o', markersize=5, label='下单→完单率')
line_sc, = ax3.plot(dates, pct_signup_complete, color=COLORS['rate_line2'], linewidth=2.5,
                     marker='s', markersize=5, label='报名→完单率')

# Value labels
for i, (d, v) in enumerate(zip(dates, pct_order_complete)):
    if i % 4 == 0:
        ax3.annotate(f'{v:.1f}%', xy=(d, v), xytext=(0, -14), textcoords='offset points',
                     fontsize=8, color=COLORS['rate_line'], ha='center')
for i, (d, v) in enumerate(zip(dates, pct_signup_complete)):
    if i % 4 == 0:
        ax3.annotate(f'{v:.1f}%', xy=(d, v), xytext=(0, 10), textcoords='offset points',
                     fontsize=8, color=COLORS['rate_line2'], ha='center')

# Trend arrow annotations
oc_first = pct_order_complete.iloc[0]
oc_last = pct_order_complete.iloc[-1]
sc_first = pct_signup_complete.iloc[0]
sc_last = pct_signup_complete.iloc[-1]

ann_style = dict(fontsize=11, fontweight='bold', ha='center',
                 bbox=dict(boxstyle='round,pad=0.3', facecolor='white', edgecolor='gray', alpha=0.9))

ax3.text(dates.iloc[1], pct_order_complete.iloc[0] - 1,
         f'{oc_first:.1f}% → {oc_last:.1f}%\n(+{oc_last - oc_first:.1f}pp)',
         color=COLORS['rate_line'], **ann_style)

ax3.text(dates.iloc[-2], pct_signup_complete.iloc[-2] - 1.5,
         f'{sc_first:.1f}% → {sc_last:.1f}%\n(+{sc_last - sc_first:.1f}pp)',
         color=COLORS['rate_line2'], **ann_style)

ax3.set_title('小蚕分发渠道：下单→完单率 与 报名→完单率', fontsize=16, fontweight='bold', pad=15)
ax3.set_xlabel('日期', fontsize=12)
ax3.set_ylabel('转化率 (%)', fontsize=12)
ax3.set_ylim(0, 100)
ax3.legend(loc='lower left', fontsize=10, frameon=True)
ax3.grid(axis='y', alpha=0.3)
ax3.set_xlim(dates.iloc[0] - pd.Timedelta(days=0.5), dates.iloc[-1] + pd.Timedelta(days=0.5))
fig3.autofmt_xdate(rotation=30)
fig3.tight_layout()
fig3.savefig('analysis_reports/chart3_转化漏斗.png', dpi=150, bbox_inches='tight')
plt.close(fig3)
print('Chart 3 saved.')

print('All 3 separate charts generated.')
