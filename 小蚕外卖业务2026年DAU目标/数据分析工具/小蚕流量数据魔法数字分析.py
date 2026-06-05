#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
小蚕流量数据魔法数字分析工具
专门针对ods.ods_sr_traffic_sensor_event_log_realtime表的魔法数字分析

使用说明:
1. 安装依赖: pip install pandas numpy pymysql
2. 运行脚本: python 小蚕流量数据魔法数字分析.py --explore-tables
3. 查看表结构后，根据需要调整查询参数

核心表: ods.ods_sr_traffic_sensor_event_log_realtime
用户ID字段: distinct_id
"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import pymysql
import warnings
import sys
import os
import json
import argparse
from typing import Dict, List, Optional, Tuple, Any, Set
from collections import defaultdict

warnings.filterwarnings('ignore')

# StarRocks数据库配置
SR_CONFIG = {
    "host": "172.17.64.45",
    "port": 9030,
    "user": "root",
    "password": "O8dtIJ6^KD!Xf8E",
    "database": "ods",  # 使用ods数据库
    "charset": "utf8mb4",
    "buffered": True,
    "connection_timeout": 300,
    "autocommit": True
}

class TrafficMagicNumberAnalyzer:
    """流量数据魔法数字分析器"""

    def __init__(self, config: Dict = None):
        """初始化"""
        self.config = config or SR_CONFIG
        self.connection = None
        self.cursor = None
        self.traffic_table = "ods_sr_traffic_sensor_event_log_realtime"

        # 魔法数字配置
        self.magic_number_config = {
            'detail_page_views': {
                'threshold': 5,
                'description': '详情页查看≥5次'
            },
            'product_clicks': {
                'threshold': 8,
                'description': '商品点击≥8次'
            },
            'filter_uses': {
                'threshold': 3,
                'description': '筛选使用≥3次'
            },
            'search_counts': {
                'threshold': 3,
                'description': '搜索行为≥3次'
            }
        }

        # 事件类型映射（需要根据实际情况调整）
        self.event_type_mapping = {
            'detail_page_views': [
                'view_detail', 'product_view', 'detail_view',
                'view_product', 'item_view', 'goods_view'
            ],
            'product_clicks': [
                'click_product', 'product_click', 'item_click',
                'goods_click', 'click_item', 'tap_product'
            ],
            'filter_uses': [
                'use_filter', 'filter_use', 'apply_filter',
                'filter_apply', 'select_filter', 'filter_select'
            ],
            'search_counts': [
                'search', 'search_action', 'perform_search',
                'execute_search', 'query_search', 'search_query'
            ]
        }

    def connect(self) -> bool:
        """连接数据库"""
        try:
            self.connection = pymysql.connect(**self.config)
            self.cursor = self.connection.cursor()
            print(f"✅ 成功连接到StarRocks数据库: {self.config['host']}:{self.config['port']}")
            print(f"   数据库: {self.config.get('database', '未指定')}")
            return True
        except pymysql.Error as e:
            print(f"❌ 数据库连接失败: {e}")
            print("   请检查:")
            print(f"   1. 网络连接是否正常")
            print(f"   2. 主机地址和端口是否正确: {self.config['host']}:{self.config['port']}")
            print(f"   3. 用户名和密码是否正确")
            print(f"   4. 数据库是否存在: {self.config.get('database', '未指定')}")
            return False

    def disconnect(self):
        """断开连接"""
        try:
            if self.cursor:
                self.cursor.close()
            if self.connection:
                self.connection.close()
            print("✅ 数据库连接已关闭")
        except Exception as e:
            print(f"⚠️  断开连接时发生错误: {e}")

    def get_traffic_table_columns(self) -> List[Dict]:
        """获取流量表的列信息"""
        try:
            if not self.connect():
                return []

            query = """
                SELECT
                    COLUMN_NAME,
                    DATA_TYPE,
                    IS_NULLABLE,
                    COLUMN_COMMENT,
                    COLUMN_TYPE
                FROM information_schema.COLUMNS
                WHERE TABLE_SCHEMA = %s
                AND TABLE_NAME = %s
                ORDER BY ORDINAL_POSITION
            """

            self.cursor.execute(query, (self.config['database'], self.traffic_table))
            columns = []

            for row in self.cursor.fetchall():
                columns.append({
                    'name': row[0],
                    'type': row[1],
                    'nullable': row[2],
                    'comment': row[3] or '',
                    'full_type': row[4]
                })

            print(f"📋 表 '{self.traffic_table}' 的列信息 ({len(columns)} 列):")
            for i, col in enumerate(columns, 1):
                print(f"    {i:3d}. {col['name']:30s} {col['type']:20s} {col['comment']}")

            return columns

        except Exception as e:
            print(f"❌ 获取表列信息失败: {e}")
            return []
        finally:
            self.disconnect()

    def get_event_type_distribution(self, start_date: str, end_date: str, limit: int = 10000) -> Dict:
        """获取事件类型分布，帮助识别关键事件"""
        try:
            if not self.connect():
                return {}

            print(f"🔍 分析事件类型分布 ({start_date} 到 {end_date})")

            # 查找可能的事件类型字段
            # 常见的字段名: event_type, event_name, action, event, type
            event_type_fields = self._find_event_type_field()

            if not event_type_fields:
                print("⚠️  未找到事件类型字段，尝试猜测...")
                # 尝试常见的字段名
                common_event_fields = ['event_type', 'event_name', 'action', 'event', 'type', 'event_type_name']
                for field in common_event_fields:
                    print(f"   尝试字段: {field}")
                    try:
                        test_query = f"""
                            SELECT COUNT(DISTINCT {field}) as distinct_count
                            FROM {self.traffic_table}
                            WHERE date >= '{start_date}' AND date <= '{end_date}'
                            LIMIT 1
                        """
                        self.cursor.execute(test_query)
                        result = self.cursor.fetchone()
                        if result and result[0] > 0:
                            event_type_fields.append(field)
                            print(f"    ✅ 找到事件类型字段: {field}")
                    except:
                        continue

            if not event_type_fields:
                print("❌ 未找到事件类型字段")
                return {}

            # 获取事件类型分布
            event_distribution = {}
            for field in event_type_fields[:3]:  # 最多尝试3个字段
                print(f"\n📊 分析字段 '{field}' 的事件分布:")

                query = f"""
                    SELECT
                        {field} as event_type,
                        COUNT(*) as event_count,
                        COUNT(DISTINCT distinct_id) as unique_users
                    FROM {self.traffic_table}
                    WHERE date >= '{start_date}' AND date <= '{end_date}'
                    GROUP BY {field}
                    ORDER BY event_count DESC
                    LIMIT {limit}
                """

                try:
                    self.cursor.execute(query)
                    results = self.cursor.fetchall()

                    if results:
                        print(f"   前20个事件类型:")
                        for i, (event_type, count, users) in enumerate(results[:20], 1):
                            print(f"     {i:2d}. {event_type[:40]:40s} {count:10,} 次  {users:10,} 用户")

                        event_distribution[field] = [
                            {'event_type': event_type, 'count': count, 'users': users}
                            for event_type, count, users in results
                        ]
                except Exception as e:
                    print(f"   字段 '{field}' 查询失败: {e}")

            return event_distribution

        except Exception as e:
            print(f"❌ 获取事件类型分布失败: {e}")
            return {}
        finally:
            self.disconnect()

    def _find_event_type_field(self) -> List[str]:
        """查找可能的事件类型字段"""
        try:
            if not self.connect():
                return []

            # 获取所有列名
            query = f"""
                SELECT COLUMN_NAME, DATA_TYPE
                FROM information_schema.COLUMNS
                WHERE TABLE_SCHEMA = '{self.config["database"]}'
                AND TABLE_NAME = '{self.traffic_table}'
            """

            self.cursor.execute(query)
            columns = self.cursor.fetchall()

            # 寻找可能的事件类型字段
            event_fields = []
            for col_name, data_type in columns:
                col_lower = col_name.lower()
                # 常见的事件类型字段名
                if any(keyword in col_lower for keyword in ['event', 'action', 'type', 'name']):
                    # 排除ID字段
                    if not col_lower.endswith('_id'):
                        event_fields.append(col_name)

            print(f"🔍 找到可能的事件类型字段: {event_fields}")
            return event_fields

        except Exception as e:
            print(f"❌ 查找事件类型字段失败: {e}")
            return []
        finally:
            self.disconnect()

    def get_time_field_info(self) -> Dict:
        """获取时间字段信息"""
        try:
            if not self.connect():
                return {}

            # 查找可能的时间字段
            query = f"""
                SELECT COLUMN_NAME, DATA_TYPE
                FROM information_schema.COLUMNS
                WHERE TABLE_SCHEMA = '{self.config["database"]}'
                AND TABLE_NAME = '{self.traffic_table}'
                AND DATA_TYPE IN ('datetime', 'timestamp', 'date', 'bigint', 'int')
                ORDER BY COLUMN_NAME
            """

            self.cursor.execute(query)
            time_fields = []

            for col_name, data_type in self.cursor.fetchall():
                col_lower = col_name.lower()
                # 常见的时间字段名
                if any(keyword in col_lower for keyword in ['time', 'date', 'timestamp', 'create', 'update']):
                    time_fields.append({'name': col_name, 'type': data_type})

            print(f"📅 找到时间字段:")
            for field in time_fields:
                print(f"    - {field['name']} ({field['type']})")

            # 尝试确定主要时间字段
            if time_fields:
                # 优先选择包含'time'或'date'的字段
                primary_field = None
                for field in time_fields:
                    field_lower = field['name'].lower()
                    if 'time' in field_lower or 'date' in field_lower:
                        primary_field = field['name']
                        break

                if not primary_field and time_fields:
                    primary_field = time_fields[0]['name']

                print(f"   主要时间字段: {primary_field}")

                # 获取时间范围
                try:
                    range_query = f"""
                        SELECT
                            MIN({primary_field}) as min_time,
                            MAX({primary_field}) as max_time,
                            COUNT(DISTINCT DATE({primary_field})) as days
                        FROM {self.traffic_table}
                        WHERE {primary_field} IS NOT NULL
                    """
                    self.cursor.execute(range_query)
                    min_time, max_time, days = self.cursor.fetchone()

                    print(f"   时间范围: {min_time} 到 {max_time}")
                    print(f"   总天数: {days}")

                    return {
                        'fields': time_fields,
                        'primary_field': primary_field,
                        'min_time': str(min_time) if min_time else None,
                        'max_time': str(max_time) if max_time else None,
                        'days': days
                    }
                except:
                    print(f"   无法获取时间范围")

            return {'fields': time_fields, 'primary_field': None}

        except Exception as e:
            print(f"❌ 获取时间字段信息失败: {e}")
            return {}
        finally:
            self.disconnect()

    def extract_magic_number_data(self, start_date: str, end_date: str,
                                event_type_field: str = None,
                                time_field: str = None,
                                event_mapping: Dict = None,
                                limit: int = None) -> pd.DataFrame:
        """
        提取魔法数字分析数据

        参数:
        - start_date, end_date: 时间范围
        - event_type_field: 事件类型字段名
        - time_field: 时间字段名
        - event_mapping: 事件类型映射（覆盖默认映射）
        - limit: 限制数据行数
        """
        try:
            if not self.connect():
                return pd.DataFrame()

            # 使用提供的映射或默认映射
            if event_mapping is None:
                event_mapping = self.event_type_mapping

            print(f"🔍 提取魔法数字数据 ({start_date} 到 {end_date})")
            print(f"   事件类型字段: {event_type_field}")
            print(f"   时间字段: {time_field}")

            # 构建查询
            query = self._build_magic_number_query(
                start_date, end_date, event_type_field, time_field, event_mapping, limit
            )

            print(f"📝 执行查询...")
            print(f"   SQL长度: {len(query)} 字符")

            start_time = datetime.now()
            self.cursor.execute(query)

            # 获取列名
            column_names = [desc[0] for desc in self.cursor.description]

            # 获取数据
            data = self.cursor.fetchall()

            # 转换为DataFrame
            df = pd.DataFrame(data, columns=column_names)

            end_time = datetime.now()
            duration = (end_time - start_time).total_seconds()

            print(f"✅ 数据提取完成!")
            print(f"   提取行数: {len(df):,}")
            print(f"   提取列数: {len(column_names)}")
            print(f"   耗时: {duration:.2f} 秒")

            if not df.empty:
                print(f"\n📋 数据预览:")
                print(df.head().to_string())

            return df

        except Exception as e:
            print(f"❌ 数据提取失败: {e}")
            import traceback
            traceback.print_exc()
            return pd.DataFrame()
        finally:
            self.disconnect()

    def _build_magic_number_query(self, start_date: str, end_date: str,
                                event_type_field: str, time_field: str,
                                event_mapping: Dict, limit: int) -> str:
        """构建魔法数字查询SQL"""

        # 如果未指定事件类型字段，使用第一个可用的
        if not event_type_field:
            event_type_field = "event_type"  # 默认值

        # 如果未指定时间字段，使用第一个可用的
        if not time_field:
            time_field = "date"  # 默认值

        # 构建事件类型条件
        event_conditions = []
        for magic_type, event_names in event_mapping.items():
            if event_names:
                # 构建IN条件
                event_list = ", ".join([f"'{name}'" for name in event_names])
                condition = f"SUM(CASE WHEN {event_type_field} IN ({event_list}) THEN 1 ELSE 0 END) as {magic_type}"
                event_conditions.append(condition)

        event_selects = ",\n        ".join(event_conditions)

        # 基础查询
        query = f"""
        WITH user_events AS (
            SELECT
                distinct_id as user_id,
                DATE({time_field}) as event_date,
                {event_type_field} as event_type,
                COUNT(*) as event_count
            FROM {self.traffic_table}
            WHERE {time_field} >= '{start_date}'
                AND {time_field} <= '{end_date}'
                AND distinct_id IS NOT NULL
                AND {event_type_field} IS NOT NULL
            GROUP BY distinct_id, DATE({time_field}), {event_type_field}
        ),

        user_daily_agg AS (
            SELECT
                user_id,
                event_date,
                {event_selects}
            FROM user_events
            GROUP BY user_id, event_date
        ),

        user_period_agg AS (
            SELECT
                user_id,
                -- 魔法数字相关指标
                SUM(detail_page_views) as detail_page_views,
                SUM(product_clicks) as product_clicks,
                SUM(filter_uses) as filter_uses,
                SUM(search_counts) as search_counts,

                -- 基础行为指标
                COUNT(DISTINCT event_date) as active_days,
                SUM(detail_page_views + product_clicks + filter_uses + search_counts) as total_events,

                -- 时间范围
                MIN(event_date) as first_active_date,
                MAX(event_date) as last_active_date
            FROM user_daily_agg
            GROUP BY user_id
        )

        SELECT
            *,
            '{start_date}' as analysis_start_date,
            '{end_date}' as analysis_end_date,
            CURRENT_DATE() as extraction_date
        FROM user_period_agg
        WHERE total_events > 0  -- 只选择有行为的用户
        """

        if limit:
            query += f" LIMIT {limit}"

        return query

    def calculate_magic_number_achievement(self, df: pd.DataFrame) -> pd.DataFrame:
        """计算魔法数字达成状态"""
        if df.empty:
            print("⚠️  数据为空，无法计算魔法数字")
            return df

        print("🧮 计算魔法数字达成状态...")

        try:
            result_df = df.copy()

            # 检查必要的列
            required_cols = list(self.magic_number_config.keys())
            missing_cols = [col for col in required_cols if col not in result_df.columns]

            if missing_cols:
                print(f"⚠️  缺少魔法数字相关列: {missing_cols}")
                print("   将使用默认值0")
                for col in missing_cols:
                    result_df[col] = 0

            # 计算魔法数字达成状态
            for magic_type, config in self.magic_number_config.items():
                if magic_type in result_df.columns:
                    threshold = config['threshold']
                    achievement_col = f"magic_{magic_type}_achieved"
                    result_df[achievement_col] = (result_df[magic_type] >= threshold).astype(int)

            # 计算达成个数
            achievement_cols = [f"magic_{col}_achieved" for col in self.magic_number_config.keys()]
            result_df['magic_number_achieved_count'] = result_df[achievement_cols].sum(axis=1)

            # 计算等级
            def assign_magic_tier(count):
                if count == 0:
                    return '未达成'
                elif count == 1:
                    return '青铜'
                elif count == 2:
                    return '白银'
                elif count == 3:
                    return '黄金'
                else:  # count == 4
                    return '钻石'

            result_df['magic_number_tier'] = result_df['magic_number_achieved_count'].apply(assign_magic_tier)

            # 计算活跃度
            if 'active_days' in result_df.columns:
                result_df['avg_events_per_day'] = result_df['total_events'] / result_df['active_days']
                result_df['activity_intensity'] = pd.cut(
                    result_df['avg_events_per_day'],
                    bins=[0, 1, 5, 10, 20, float('inf')],
                    labels=['极低', '低', '中', '高', '极高'],
                    right=False
                )

            # 生成报告
            self._generate_magic_number_report(result_df)

            return result_df

        except Exception as e:
            print(f"❌ 魔法数字计算失败: {e}")
            import traceback
            traceback.print_exc()
            return df

    def _generate_magic_number_report(self, df: pd.DataFrame):
        """生成魔法数字报告"""
        print(f"\n📊 魔法数字分析报告")
        print("="*60)
        print(f"总用户数: {len(df):,}")

        if 'total_events' in df.columns:
            print(f"总事件数: {df['total_events'].sum():,}")
            print(f"人均事件数: {df['total_events'].mean():.2f}")

        if 'active_days' in df.columns:
            print(f"平均活跃天数: {df['active_days'].mean():.2f}")

        # 魔法数字达成情况
        achievement_cols = [f"magic_{col}_achieved" for col in self.magic_number_config.keys()]

        if all(col in df.columns for col in achievement_cols):
            print(f"\n魔法数字达成情况:")
            for i, (magic_type, config) in enumerate(self.magic_number_config.items(), 1):
                col_name = f"magic_{magic_type}_achieved"
                if col_name in df.columns:
                    achieved = df[col_name].sum()
                    total = len(df)
                    percentage = (achieved / total * 100) if total > 0 else 0
                    print(f"  {i}. {config['description']}: {achieved:,}/{total:,} ({percentage:.1f}%)")

        if 'magic_number_achieved_count' in df.columns:
            print(f"\n魔法数字达成个数分布:")
            for count in range(5):
                user_count = (df['magic_number_achieved_count'] == count).sum()
                percentage = (user_count / len(df) * 100) if len(df) > 0 else 0
                print(f"  达成{count}个: {user_count:,} ({percentage:.1f}%)")

        if 'magic_number_tier' in df.columns:
            print(f"\n魔法数字等级分布:")
            tier_dist = df['magic_number_tier'].value_counts()
            for tier, count in tier_dist.items():
                percentage = (count / len(df) * 100)
                print(f"  {tier}: {count:,} ({percentage:.1f}%)")

    def export_to_excel(self, df: pd.DataFrame, filename: str,
                       output_dir: str = "output") -> Tuple[bool, str]:
        """导出数据到Excel"""
        if df.empty:
            print("⚠️  数据为空，无法导出")
            return False, ""

        try:
            os.makedirs(output_dir, exist_ok=True)

            if not filename.endswith('.xlsx'):
                filename += '.xlsx'
            filepath = os.path.join(output_dir, filename)

            # 导出到Excel
            with pd.ExcelWriter(filepath, engine='openpyxl') as writer:
                # 主数据
                df.to_excel(writer, sheet_name='魔法数字数据', index=False)

                # 汇总统计
                summary_data = self._create_summary_sheet(df)
                summary_df = pd.DataFrame(summary_data)
                summary_df.to_excel(writer, sheet_name='汇总统计', index=False)

                # 魔法数字配置
                config_data = []
                for magic_type, config in self.magic_number_config.items():
                    config_data.append({
                        '魔法数字类型': magic_type,
                        '阈值': config['threshold'],
                        '描述': config['description']
                    })
                config_df = pd.DataFrame(config_data)
                config_df.to_excel(writer, sheet_name='配置信息', index=False)

            file_size = os.path.getsize(filepath) / (1024 * 1024)

            print(f"💾 Excel文件导出完成!")
            print(f"   文件路径: {filepath}")
            print(f"   文件大小: {file_size:.2f} MB")
            print(f"   工作表: 魔法数字数据, 汇总统计, 配置信息")

            return True, filepath

        except Exception as e:
            print(f"❌ Excel导出失败: {e}")
            print("   请安装openpyxl: pip install openpyxl")
            return False, ""

    def _create_summary_sheet(self, df: pd.DataFrame) -> List[Dict]:
        """创建汇总统计表数据"""
        summary = []

        # 基础统计
        summary.append({'指标': '总用户数', '数值': len(df)})

        if 'total_events' in df.columns:
            summary.append({'指标': '总事件数', '数值': df['total_events'].sum()})
            summary.append({'指标': '人均事件数', '数值': df['total_events'].mean()})

        if 'active_days' in df.columns:
            summary.append({'指标': '平均活跃天数', '数值': df['active_days'].mean()})

        # 魔法数字达成率
        achievement_cols = [f"magic_{col}_achieved" for col in self.magic_number_config.keys()]

        for i, (magic_type, config) in enumerate(self.magic_number_config.items(), 1):
            col_name = f"magic_{magic_type}_achieved"
            if col_name in df.columns:
                achieved = df[col_name].sum()
                rate = (achieved / len(df) * 100) if len(df) > 0 else 0
                summary.append({'指标': f'魔法数字{i}达成率(%)', '数值': rate})

        # 等级分布
        if 'magic_number_tier' in df.columns:
            tier_dist = df['magic_number_tier'].value_counts()
            for tier, count in tier_dist.items():
                percentage = (count / len(df) * 100)
                summary.append({'指标': f'{tier}级用户占比(%)', '数值': percentage})

        return summary

    def run_exploration(self):
        """运行探索模式，了解表结构"""
        print("="*70)
        print("🔍 小蚕流量数据表探索模式")
        print("="*70)

        print(f"\n1️⃣ 查看表结构...")
        columns = self.get_traffic_table_columns()

        print(f"\n2️⃣ 查看时间字段信息...")
        time_info = self.get_time_field_info()

        print(f"\n3️⃣ 查看事件类型分布（最近7天）...")
        end_date = datetime.now().strftime("%Y-%m-%d")
        start_date = (datetime.now() - timedelta(days=7)).strftime("%Y-%m-%d")
        event_dist = self.get_event_type_distribution(start_date, end_date, limit=50)

        print(f"\n4️⃣ 当前魔法数字配置:")
        for i, (magic_type, config) in enumerate(self.magic_number_config.items(), 1):
            print(f"   魔法数字{i}: {config['description']} (阈值: {config['threshold']})")

        print(f"\n5️⃣ 事件类型映射（需要根据实际事件名调整）:")
        for magic_type, event_names in self.event_type_mapping.items():
            print(f"   {magic_type}: {event_names[:3]}...")

        print(f"\n💡 建议:")
        print(f"   1. 根据上面的事件类型分布，调整event_type_mapping")
        print(f"   2. 确定时间字段名，用于时间范围过滤")
        print(f"   3. 调整魔法数字阈值（当前配置见上）")

    def run_analysis(self, start_date: str, end_date: str,
                    event_type_field: str = None,
                    time_field: str = None,
                    limit: int = None,
                    export_excel: bool = True):
        """运行完整分析流程"""
        print("="*70)
        print("🚀 小蚕流量数据魔法数字分析")
        print("="*70)

        print(f"\n📅 分析参数:")
        print(f"   时间范围: {start_date} 到 {end_date}")
        print(f"   事件类型字段: {event_type_field or '自动检测'}")
        print(f"   时间字段: {time_field or '自动检测'}")
        print(f"   数据限制: {'无限制' if limit is None else f'{limit} 行'}")

        # 提取数据
        print(f"\n1️⃣ 提取数据...")
        df = self.extract_magic_number_data(
            start_date=start_date,
            end_date=end_date,
            event_type_field=event_type_field,
            time_field=time_field,
            limit=limit
        )

        if df.empty:
            print("❌ 数据提取失败，终止流程")
            return

        # 计算魔法数字
        print(f"\n2️⃣ 计算魔法数字...")
        df = self.calculate_magic_number_achievement(df)

        # 导出Excel
        if export_excel and not df.empty:
            print(f"\n3️⃣ 导出Excel文件...")
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"小蚕流量魔法数字_{start_date}_to_{end_date}_{timestamp}"

            success, filepath = self.export_to_excel(df, filename)
            if success:
                print(f"✅ 分析完成! 文件已保存到: {filepath}")
            else:
                print("⚠️  Excel导出失败，数据保留在DataFrame中")

        print(f"\n🎉 分析流程完成!")
        print(f"   共分析 {len(df):,} 个用户")


def main():
    """主函数"""
    parser = argparse.ArgumentParser(description='小蚕流量数据魔法数字分析工具')

    parser.add_argument('--explore', action='store_true',
                       help='探索模式：查看表结构和事件分布')
    parser.add_argument('--analyze', action='store_true',
                       help='分析模式：执行魔法数字分析')
    parser.add_argument('--start-date', type=str, default='2026-03-01',
                       help='开始日期 (格式: YYYY-MM-DD)')
    parser.add_argument('--end-date', type=str, default='2026-03-31',
                       help='结束日期 (格式: YYYY-MM-DD)')
    parser.add_argument('--event-field', type=str,
                       help='事件类型字段名 (如: event_type, event_name)')
    parser.add_argument('--time-field', type=str,
                       help='时间字段名 (如: event_time, date)')
    parser.add_argument('--limit', type=int,
                       help='限制数据行数')
    parser.add_argument('--no-excel', action='store_true',
                       help='不导出Excel文件')

    args = parser.parse_args()

    analyzer = TrafficMagicNumberAnalyzer()

    if args.explore:
        analyzer.run_exploration()
    elif args.analyze:
        analyzer.run_analysis(
            start_date=args.start_date,
            end_date=args.end_date,
            event_type_field=args.event_field,
            time_field=args.time_field,
            limit=args.limit,
            export_excel=not args.no_excel
        )
    else:
        print("请指定运行模式:")
        print("  --explore  探索表结构和事件分布")
        print("  --analyze  执行魔法数字分析")
        print("\n示例:")
        print("  python 小蚕流量数据魔法数字分析.py --explore")
        print("  python 小蚕流量数据魔法数字分析.py --analyze --start-date 2026-03-01 --end-date 2026-03-31")


if __name__ == "__main__":
    main()