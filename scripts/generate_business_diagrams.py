import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch

plt.rcParams['font.family'] = ['Arial Unicode MS', 'sans-serif']
plt.rcParams['axes.unicode_minus'] = False

# ============================================================
# Figure 1: 商业模式 — 大字版，修正结算方向
# ============================================================
fig1, ax1 = plt.subplots(1, 1, figsize=(24, 15))
ax1.set_xlim(0, 24)
ax1.set_ylim(0, 15)
ax1.axis('off')
ax1.set_facecolor('#FAFBFC')

# Title
ax1.text(12, 14.5, '小蚕霸王餐 商业模式', fontsize=30, fontweight='bold',
         ha='center', va='center', color='#1a1a1a')

# ===== UPSTREAM SECTION =====
ax1.text(12, 13.5, '▲  活动来源（上游）', fontsize=16, ha='center', va='center',
         fontweight='bold', color='#555555')

# 4 source columns — wider canvas, adjusted x positions
src_cols = [
    {'x': 4.0,  'title': '晓晓',       'sub': '分发到小蚕首页',          'color': '#2980B9', 'face': '#D4E6F1', 'kind': 'platform'},
    {'x': 9.5,  'title': '自营活动',    'sub': '商家 / BD / 代理商 发布', 'color': '#27AE60', 'face': '#D5F5E3', 'kind': 'self'},
    {'x': 15.0, 'title': '美团官方',    'sub': '接口同步',                'color': '#E67E22', 'face': '#FDEBD0', 'kind': 'platform'},
    {'x': 20.5, 'title': '饿了么官方',  'sub': '接口同步',                'color': '#AAAAAA', 'face': '#F2F3F4', 'kind': 'paused'},
]

y_src = 12.0
box_w = 4.5
box_h = 1.9

for col in src_cols:
    x = col['x']
    bx = x - box_w / 2
    by = y_src - box_h / 2

    rect = FancyBboxPatch((bx, by), box_w, box_h, boxstyle='round,pad=0.3',
                           facecolor=col['face'], edgecolor=col['color'],
                           linewidth=2.5, alpha=0.85)
    ax1.add_patch(rect)

    ax1.text(x, y_src + 0.2, col['title'], fontsize=18, fontweight='bold',
             ha='center', va='center', color=col['color'])
    ax1.text(x, y_src - 0.45, col['sub'], fontsize=12, ha='center', va='center', color='#666666')

    if col['kind'] == 'paused':
        ax1.text(x + box_w / 2 - 0.05, y_src + box_h / 2 + 0.1, '已暂停',
                 fontsize=12, fontweight='bold', ha='center', va='center',
                 color='white',
                 bbox=dict(boxstyle='round,pad=0.3', facecolor='#C0392B',
                           edgecolor='#C0392B', linewidth=1))

# ===== CENTER: 小蚕 =====
y_center = 8.8
center_w = 8.0
center_h = 2.8

rect_center = FancyBboxPatch((12 - center_w / 2, y_center - center_h / 2),
                              center_w, center_h, boxstyle='round,pad=0.5',
                              facecolor='#D5F5E3', edgecolor='#27AE60',
                              linewidth=4, alpha=0.9)
ax1.add_patch(rect_center)
ax1.text(12, y_center + 0.5, '小  蚕', fontsize=30, fontweight='bold',
         ha='center', va='center', color='#27AE60')
ax1.text(12, y_center - 0.25, '(中心平台)', fontsize=14, ha='center', va='center', color='#666666')
ax1.text(12, y_center - 0.75, '活动聚合 · 分发转化 · 返现结算', fontsize=13,
         ha='center', va='center', color='#888888')

# Arrows: 4 sources → 小蚕 (spread along top edge)
center_top = y_center + center_h / 2  # = 10.2
# 小蚕 top edge x: 8 to 16
target_xs = [9.5, 10.8, 13.2, 14.5]

for i, col in enumerate(src_cols):
    linestyle = 'dashed' if col['kind'] == 'paused' else 'solid'
    lw = 2.0 if col['kind'] == 'paused' else 3.0
    ax1.annotate('', xy=(target_xs[i], center_top + 0.05),
                 xytext=(col['x'], y_src - box_h / 2 - 0.05),
                 arrowprops=dict(arrowstyle='->', color=col['color'], lw=lw,
                                linestyle=linestyle, connectionstyle='arc3,rad=0'))

# Paused label on 饿了么 arrow
ax1.text(18.0, 10.5, '已暂停', fontsize=11, ha='center', va='center',
         color='#C0392B', fontweight='bold',
         bbox=dict(boxstyle='round,pad=0.2', facecolor='white',
                   edgecolor='#C0392B', linewidth=1.5))

# ===== DIVIDER =====
ax1.axhline(y=7.0, xmin=0.04, xmax=0.96, color='#CCCCCC', linewidth=1.5, linestyle='--')

# ===== DOWNSTREAM SECTION =====
ax1.text(12, 6.6, '▼  活动分发（下游）— 小蚕站内', fontsize=16, ha='center', va='center',
         fontweight='bold', color='#555555')

y_ch = 5.2
ch_w = 6.5
ch_h = 2.2

channels = [
    {'x': 8,  'title': '首页分发', 'desc': '活动展示在小蚕首页\n用户在首页浏览并报名',
     'color': '#27AE60', 'face': '#D5F5E3'},
    {'x': 16, 'title': '搜索分发', 'desc': '用户搜索活动\n精准匹配并报名',
     'color': '#1ABC9C', 'face': '#D1F2EB'},
]

for ch in channels:
    x = ch['x']
    rect = FancyBboxPatch((x - ch_w / 2, y_ch - ch_h / 2), ch_w, ch_h,
                           boxstyle='round,pad=0.3', facecolor=ch['face'],
                           edgecolor=ch['color'], linewidth=2.5, alpha=0.7)
    ax1.add_patch(rect)
    ax1.text(x, y_ch + 0.35, ch['title'], fontsize=18, fontweight='bold',
             ha='center', va='center', color=ch['color'])
    ax1.text(x, y_ch - 0.4, ch['desc'], fontsize=13, ha='center', va='center', color='#555555')

# Arrows: 小蚕 → channels
center_bot = y_center - center_h / 2  # = 7.4
ax1.annotate('', xy=(8, y_ch + ch_h / 2 + 0.05),
             xytext=(10.0, center_bot - 0.05),
             arrowprops=dict(arrowstyle='->', color='#27AE60', lw=3.0,
                            connectionstyle='arc3,rad=-0.12'))
ax1.annotate('', xy=(16, y_ch + ch_h / 2 + 0.05),
             xytext=(14.0, center_bot - 0.05),
             arrowprops=dict(arrowstyle='->', color='#1ABC9C', lw=3.0,
                            connectionstyle='arc3,rad=0.12'))

# ===== USER SECTION =====
y_user = 3.1

ax1.text(12, y_user + 0.5, '用  户', fontsize=24, fontweight='bold',
         ha='center', va='center',
         bbox=dict(boxstyle='round,pad=0.7', facecolor='#F5EEF8',
                   edgecolor='#8E44AD', linewidth=3.5))

# User flow steps
flow_y = y_user - 0.7
flow_steps = [
    ('报名',       '#3498DB', '#D6EAF8'),
    ('提交订单检测', '#E67E22', '#FDEBD0'),
    ('检测通过',    '#2ECC71', '#D5F5E3'),
    ('收到返现',    '#C0392B', '#FADBD8'),
]

flow_spacing = 3.2
flow_x_start = 12 - (len(flow_steps) - 1) * flow_spacing / 2

for i, (label, color, face) in enumerate(flow_steps):
    fx = flow_x_start + i * flow_spacing
    ax1.text(fx, flow_y, label, fontsize=13, ha='center', va='center', fontweight='bold',
             bbox=dict(boxstyle='round,pad=0.5', facecolor=face, edgecolor=color, linewidth=2))
    if i < len(flow_steps) - 1:
        ax1.annotate('', xy=(fx + flow_spacing / 2 - 0.35, flow_y),
                     xytext=(fx + 0.55, flow_y),
                     arrowprops=dict(arrowstyle='->', color='#888888', lw=2))

# Arrows: channels → user
ax1.annotate('', xy=(10.5, y_user + 1.3),
             xytext=(8, y_ch - ch_h / 2 - 0.05),
             arrowprops=dict(arrowstyle='->', color='#27AE60', lw=3.0,
                            connectionstyle='arc3,rad=-0.2'))
ax1.annotate('', xy=(13.5, y_user + 1.3),
             xytext=(16, y_ch - ch_h / 2 - 0.05),
             arrowprops=dict(arrowstyle='->', color='#1ABC9C', lw=3.0,
                            connectionstyle='arc3,rad=0.2'))

# ===== DIVIDER =====
ax1.axhline(y=1.8, xmin=0.04, xmax=0.96, color='#CCCCCC', linewidth=1.5, linestyle='--')

# ===== SETTLEMENT SECTION =====
ax1.text(12, 1.5, '结算流程', fontsize=16, ha='center', va='center',
         fontweight='bold', color='#555555')

y_settle = 0.85

# Left: 自营结算 — 小蚕给代理商佣金 + BD向商家收款
settle_l = FancyBboxPatch((1.2, y_settle - 0.55), 10.2, 1.4, boxstyle='round,pad=0.3',
                           facecolor='#D5F5E3', edgecolor='#27AE60', linewidth=2.5, alpha=0.5)
ax1.add_patch(settle_l)
ax1.text(6.3, y_settle + 0.28, '自营活动结算', fontsize=15, fontweight='bold',
         ha='center', va='center', color='#27AE60')
ax1.text(6.3, y_settle - 0.1, '小蚕给代理商佣金   |   活动下线后 BD 向商家收款', fontsize=13,
         ha='center', va='center', color='#555555')

# Right: 平台结算 — 美团/饿了么官方给小蚕钱
settle_r = FancyBboxPatch((12.6, y_settle - 0.55), 10.2, 1.4, boxstyle='round,pad=0.3',
                           facecolor='#FDEBD0', edgecolor='#E67E22', linewidth=2.5, alpha=0.5)
ax1.add_patch(settle_r)
ax1.text(17.7, y_settle + 0.28, '平台活动结算（美团 / 饿了么）', fontsize=15, fontweight='bold',
         ha='center', va='center', color='#E67E22')
ax1.text(17.7, y_settle - 0.1, '美团 / 饿了么官方 → 定期结算付款 → 小蚕', fontsize=13,
         ha='center', va='center', color='#555555')

fig1.tight_layout(pad=0.3)
fig1.savefig('analysis_reports/商业模式.png', dpi=150, bbox_inches='tight', facecolor='white')
plt.close(fig1)
print('商业模式 chart saved.')

# ============================================================
# Figure 2: 用户流转路径 — 纯流程，无数据，大字版
# ============================================================
fig2, ax2 = plt.subplots(1, 1, figsize=(20, 8.5))
ax2.set_xlim(0, 20)
ax2.set_ylim(0, 8.5)
ax2.axis('off')
ax2.set_facecolor('#FAFBFC')

steps = [
    {'x': 2.0, 'num': '第1步', 'title': '打开小蚕\n看活动列表',
     'desc': '浏览首页活动',
     'color': '#3498DB', 'face': '#D6EAF8', 'icon_text': '浏览'},
    {'x': 6.0, 'num': '第2步', 'title': '报名活动\n抢名额',
     'desc': '点击报名按钮',
     'color': '#2ECC71', 'face': '#D5F5E3', 'icon_text': '报名'},
    {'x': 10.0, 'num': '第3步', 'title': '跳转外卖平台\n去下单',
     'desc': '美团 / 淘宝闪购 / 京东',
     'color': '#E67E22', 'face': '#FDEBD0', 'icon_text': '下单'},
    {'x': 14.0, 'num': '第4步', 'title': '完成订单\n(外卖送到)',
     'desc': '配送完成即完单',
     'color': '#8E44AD', 'face': '#E8DAEF', 'icon_text': '完单'},
    {'x': 18.0, 'num': '第5步', 'title': '收到返现\n(现金到账)',
     'desc': '完单后自动返现',
     'color': '#C0392B', 'face': '#FADBD8', 'icon_text': '返现'},
]

y_box_bottom = 2.2
y_box_height = 3.2
y_box_mid = y_box_bottom + y_box_height / 2
box_width = 3.2

ax2.text(10, 8.1, '小蚕用户：从看到活动到拿到返现的 5 步', fontsize=24, fontweight='bold',
         ha='center', va='center', color='#1a1a1a')

ax2.text(10, 7.45, '跳转平台： 美团外卖  /  淘宝闪购  /  京东外卖', fontsize=13, ha='center', va='center',
         color='#E67E22', fontweight='bold',
         bbox=dict(boxstyle='round,pad=0.35', facecolor='#FEF9E7', edgecolor='#E67E22', linewidth=1.5, alpha=0.85))

for s in steps:
    x = s['x']
    bx = x - box_width / 2

    rect = FancyBboxPatch((bx, y_box_bottom), box_width, y_box_height,
                           boxstyle='round,pad=0.3', facecolor=s['face'],
                           edgecolor=s['color'], linewidth=2.5, alpha=0.85)
    ax2.add_patch(rect)

    # Step number above box
    ax2.text(x, y_box_bottom + y_box_height + 0.3, s['num'], fontsize=13,
             ha='center', va='center', color=s['color'], fontweight='bold')

    # Icon tag
    ax2.text(x, y_box_bottom + y_box_height - 0.5, s['icon_text'],
             fontsize=13, ha='center', va='center',
             color='white', fontweight='bold',
             bbox=dict(boxstyle='round,pad=0.3', facecolor=s['color'], edgecolor=s['color'], linewidth=1))

    # Separator line
    ax2.plot([bx + 0.5, bx + box_width - 0.5], [y_box_mid + 0.55, y_box_mid + 0.55],
             color=s['color'], linewidth=1, alpha=0.4)

    # Step title
    ax2.text(x, y_box_mid + 0.1, s['title'], fontsize=16, ha='center', va='center',
             fontweight='bold', color='#1a1a1a')

    # Description
    ax2.text(x, y_box_mid - 0.65, s['desc'], fontsize=12, ha='center', va='center', color='#888888')

for i in range(len(steps) - 1):
    x1 = steps[i]['x'] + box_width / 2 + 0.05
    x2 = steps[i + 1]['x'] - box_width / 2 - 0.05
    y_arrow = y_box_mid
    ax2.annotate('', xy=(x2, y_arrow), xytext=(x1, y_arrow),
                 arrowprops=dict(arrowstyle='->', color='#AAAAAA', lw=3, connectionstyle='arc3,rad=0'))

fig2.tight_layout(pad=0.5)
fig2.savefig('analysis_reports/用户流转路径.png', dpi=150, bbox_inches='tight', facecolor='white')
plt.close(fig2)
print('用户流转路径 chart saved.')

print('All business diagrams generated.')
