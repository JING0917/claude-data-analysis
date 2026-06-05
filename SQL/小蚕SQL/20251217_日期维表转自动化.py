import pandas as pd
from datetime import datetime, timedelta
from chinese_calendar import is_workday, is_holiday, get_holiday_detail

# 日期范围 示例给到25年结束
start_date = datetime(2024, 1, 1)
end_date = datetime(2025, 12, 31)
dates = pd.date_range(start=start_date, end=end_date)

# 构建数据列表
data = []
for date in dates:
    current_date_txt = date.strftime('%Y-%m-%d')
    current_date_num = int(date.strftime('%Y%m%d'))
    yr = date.strftime('%Y')
    quarter_of_year = f"{yr}-Q{(date.month - 1) // 3 + 1}"
    month_of_year = date.strftime('%Y-%m')
    week_of_year = int(date.strftime('%U'))  # 从0开始
    day_of_year = int(date.strftime('%j'))   # 第几天（001-365）
    day_of_week = f"星期{['一','二','三','四','五','六','日'][date.weekday()]}"
    is_workday_flag = '1' if is_workday(date) else '0'
    
    holiday_name = ''
    if is_holiday(date):
        _, holiday_name = get_holiday_detail(date)

    data.append({
        'current_date_txt': current_date_txt,
        'current_date_num': current_date_num,
        'yr': yr,
        'quarter_of_year': quarter_of_year,
        'month_of_year': month_of_year,
        'week_of_year': week_of_year,
        'day_of_year': day_of_year,
        'day_of_week': day_of_week,
        'holiday': holiday_name,
        'is_workday': is_workday_flag,
        'create_time': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    })

# 转为 DataFrame
df = pd.DataFrame(data)

# 显示前10行
print(df.head(10))

# 导出为 Excel 文件
df.to_excel("日期维度表_自动生成.xlsx", index=False)