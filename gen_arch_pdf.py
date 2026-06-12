from fpdf import FPDF
import os

FONT_PATH = "/Library/Fonts/Arial Unicode.ttf"


class ArchPDF(FPDF):
    def __init__(self):
        super().__init__('P', 'mm', 'A4')
        self.add_font("CJK", "", FONT_PATH, uni=True)
        self.add_font("CJK", "B", FONT_PATH, uni=True)
        self.set_auto_page_break(True, 18)

    def doctitle(self, text):
        self.set_font("CJK", "B", 18)
        self.set_text_color(0, 0, 0)
        self.cell(0, 12, text, new_x="LMARGIN", new_y="NEXT")
        self.ln(6)

    def subtitle(self, text):
        self.set_font("CJK", "", 10)
        self.set_text_color(100, 100, 100)
        self.cell(0, 7, text, new_x="LMARGIN", new_y="NEXT")
        self.ln(10)

    def h2(self, text):
        self.ln(4)
        self.set_font("CJK", "B", 14)
        self.set_text_color(0, 0, 0)
        self.cell(0, 9, text, new_x="LMARGIN", new_y="NEXT")
        y = self.get_y()
        self.set_draw_color(9, 105, 218)
        self.set_line_width(0.4)
        self.line(self.l_margin, y, self.w - self.r_margin, y)
        self.ln(5)

    def h3(self, text):
        self.set_font("CJK", "B", 12)
        self.set_text_color(9, 105, 218)
        self.cell(0, 8, text, new_x="LMARGIN", new_y="NEXT")
        self.ln(3)

    def body(self, text, size=10, bold=False):
        style = "B" if bold else ""
        self.set_font("CJK", style, size)
        self.set_text_color(50, 50, 50)
        self.multi_cell(0, 6, text, align='L')
        self.ln(1)

    def box(self, lines, color=None, fill=None):
        """Draw a labeled box for architecture diagrams."""
        if color is None:
            color = (50, 50, 50)
        w = 60
        h = len(lines) * 6 + 6
        x = self.get_x()
        y = self.get_y()
        if fill:
            self.set_fill_color(*fill)
        self.set_draw_color(*color)
        self.set_line_width(0.3)
        self.rect(x, y, w, h, style="DF" if fill else "D")
        self.set_xy(x, y + 3)
        for line in lines:
            self.set_x(x + 3)
            self.set_font("CJK", "B" if lines.index(line) == 0 else "", 8)
            self.set_text_color(*color)
            self.cell(w - 6, 5.5, line)
            self.ln(5.5)
        self.set_xy(x, y + h)

    def arrow_down(self):
        x = self.get_x() + 26
        y = self.get_y()
        self.set_draw_color(100, 100, 100)
        self.set_line_width(0.3)
        self.line(x, y, x, y + 8)
        self.line(x - 2, y + 6, x, y + 8)
        self.line(x + 2, y + 6, x, y + 8)
        self.set_xy(self.l_margin, y + 8)

    def arrow_right(self, x1, y1, x2):
        self.set_draw_color(100, 100, 100)
        self.set_line_width(0.3)
        self.line(x1, y1, x2, y1)
        self.line(x2 - 2, y1 - 2, x2, y1)
        self.line(x2 - 2, y1 + 2, x2, y1)

    def gap(self, h=4):
        self.ln(h)

    def table(self, headers, rows):
        col_w = (self.w - self.l_margin - self.r_margin) / len(headers)
        self.set_fill_color(246, 248, 250)
        self.set_font("CJK", "B", 9)
        self.set_text_color(50, 50, 50)
        for i, h in enumerate(headers):
            self.cell(col_w, 7, h, border=0, fill=True)
        self.ln()
        self.set_font("CJK", "", 9)
        for row in rows:
            for cell in row:
                self.cell(col_w, 6.5, cell)
            self.ln()


def gen():
    pdf = ArchPDF()
    pdf.add_page()

    # Title
    pdf.doctitle("数据架构演进")
    pdf.subtitle("从小蚕 StarRocks 存算一体到 Paimon + StarRocks 存算分离")

    # Section 1
    pdf.h2("现状：StarRocks 被当成全能层")
    pdf.body("StarRocks 同时承接 OLAP（分析）+ OLTP（点查）+ 存储，后端服务直接查 StarRocks 时延迟不可控。", size=10)
    pdf.ln(2)

    # ASCII architecture diagram - simplified into text + structure
    pdf.set_fill_color(255, 241, 240)
    pdf.set_draw_color(207, 34, 46)
    pdf.set_line_width(0.8)
    w = pdf.w - pdf.l_margin - pdf.r_margin
    pdf.rect(pdf.l_margin, pdf.get_y(), w, 28, style="DF")
    y0 = pdf.get_y() + 2
    pdf.set_xy(pdf.l_margin + 5, y0)
    pdf.set_font("CJK", "B", 10)
    pdf.set_text_color(207, 34, 46)
    pdf.cell(w - 10, 6, "当前问题架构")
    pdf.set_xy(pdf.l_margin + 5, y0 + 8)
    pdf.set_font("CJK", "", 9)
    pdf.set_text_color(100, 50, 50)
    pdf.cell(w - 10, 5, "业务数据源  →  StarRocks 存算一体（单集群）  →  看板 / 报表 / 后端服务")
    pdf.set_xy(pdf.l_margin + 5, y0 + 14)
    pdf.set_font("CJK", "", 8)
    pdf.set_text_color(207, 34, 46)
    pdf.cell(w - 10, 5, "后端 OLTP 点查也走 StarRocks → 高峰期 3 秒超时，I/O 不可隔离")

    pdf.set_y(y0 + 30)

    # Section 2 - Isolation problem
    pdf.h2("存算一体在腾讯云上的隔离困境")

    pdf.h3("Workload Group 只能做软隔离")
    pdf.body("CPU 和内存可以按 query 分组划分，但磁盘 I/O 和网络带宽是所有 Workload Group 共享的。后端点查扫热数据时吃 I/O，分析侧大查询 GROUP BY 全表扫描也吃 I/O —— 两股流量在同一个 BE 进程里抢同一块盘，谁也躲不开。")

    pdf.h3("扩容绑死")
    pdf.body("想给分析侧加算力就必须同时加存储（每扩一个 BE 都带一块盘），想扩存储容量也得捎上计算。成本不是线性增长的，是按节点整体翻倍的。高峰期分析查询和点查并发上去，只能整体升配，没法单独给某一层加弹性。")

    pdf.h3("实践验证")
    pdf.body("此前试图用「再搭一套 StarRocks 集群给后端专用」来缓解，结果是：存储数据要写两份，两套集群各自维护，单集群内部的 I/O 竞争依然存在，本质上是用冗余成本换一个不彻底的解法。", bold=False)

    # Section 3 - Target architecture
    pdf.h2("目标架构：Paimon + StarRocks 存算分离 + MySQL/Redis")
    pdf.ln(2)

    pdf.set_fill_color(230, 244, 234)
    pdf.set_draw_color(26, 127, 55)
    pdf.set_line_width(0.8)
    pdf.rect(pdf.l_margin, pdf.get_y(), w, 34, style="DF")
    y0 = pdf.get_y() + 2
    pdf.set_xy(pdf.l_margin + 5, y0)
    pdf.set_font("CJK", "B", 10)
    pdf.set_text_color(26, 127, 55)
    pdf.cell(w - 10, 6, "目标架构 — 各层物理隔离")
    pdf.set_xy(pdf.l_margin + 5, y0 + 8)
    pdf.set_font("CJK", "", 8)
    pdf.set_text_color(40, 80, 40)
    lines = [
        "业务数据源 ──CDC──→ OSS/COS（共享存储）",
        "    ├── Paimon（ACID · Upsert · Time Travel）",
        "    └── StarRocks 计算层（只做分析，弹性扩缩）",
        "            │",
        "            ▼ 物化视图预计算",
        "    ┌───────┴───────┐",
        "    ▼               ▼",
        "  MySQL（持久化）  Redis（热缓存）",
        "    └───────┬───────┘",
        "            ▼",
        "       后端服务（< 50ms）→ 看板 / 报表",
    ]
    for l in lines:
        pdf.set_xy(pdf.l_margin + 5, pdf.get_y())
        pdf.cell(w - 10, 4.5, l)
        pdf.ln(4.5)
    y_end = pdf.get_y()
    pdf.set_y(y_end + 6)

    # Section 4 - Responsibilities
    pdf.h2("各层职责")
    pdf.table(
        ["层", "角色"],
        [
            ["Paimon", "湖格式，管实时写入、Upsert、ACID、Time Travel"],
            ["StarRocks", "只做分析查询，挂载 Paimon 外表，存算分离弹性扩缩"],
            ["MySQL", "OLTP 持久化层，后端点查的最终出口"],
            ["Redis", "热缓存层，高频指标预计算后缓存"],
            ["后端服务", "只访问 MySQL/Redis，延迟可控"],
        ]
    )

    pdf.ln(6)
    pdf.h2("核心变化对比")
    pdf.table(
        ["现状", "改造后"],
        [
            ["StarRocks 扛写入", "Paimon 扛写入"],
            ["StarRocks 扛点查", "MySQL/Redis 扛点查"],
            ["一套集群不分家", "分析和服务分层"],
            ["锁在存算一体，扩缩绑死", "存算分离，计算弹性扩缩，存储按量付费"],
            ["Workload Group 软隔离，I/O 不可控", "各层物理隔离，I/O 路径完全分开"],
            ["后端 3 秒超时", "后端 50ms 以内"],
            ["两套集群双写，冗余成本高", "统一存储底座，无数据冗余"],
        ]
    )

    # Section 5 - Cost analysis
    pdf.add_page()
    pdf.h2("成本分析")

    pdf.h3("当前成本结构")
    pdf.body("存算一体下 BE 节点捆绑 CPU + 内存 + SSD，成本以节点为单位整体翻。此前两套集群双写方案，存储和算力各翻一倍，用冗余换隔离，边际成本线性甚至超线性增长。")

    pdf.h3("目标架构成本拆解")
    pdf.table(
        ["组件", "角色", "成本特征"],
        [
            ["OSS/COS", "共享存储", "按量付费，¥0.1/GB·月级别，远低 BE 本地 SSD"],
            ["Flink（Paimon CDC）", "实时写入与 Compaction", "最大增量成本，TaskManager 数随写入量增长"],
            ["StarRocks CN", "纯计算", "不带盘，分析查询少了可缩容，按需弹性"],
            ["MySQL", "OLTP 持久化", "小规格即够用（2C4G），几百元/月"],
            ["Redis", "热缓存", "小规格（2-4GB），几百元/月"],
        ]
    )
    pdf.ln(2)
    pdf.body("关键判断：组件从 1 个变成 5 个，基础设施月费短期可能不降反升。真正的成本收益不在绝对值，在边际曲线——业务增长时，存储按 GB 线性付费、计算按核弹性扩缩，不再被「扩一个 BE 就绑一块盘」锁死。Flink 集群规模是最大变量，写入流量不大的情况下整体成本可控，写入量上去后需单独评估。")

    pdf.h3("边际成本对比")
    pdf.table(
        ["场景", "当前（存算一体）", "目标（存算分离）"],
        [
            ["分析查询增加", "扩 BE 节点，磁盘一起买", "扩 CN 节点，只加计算"],
            ["存储容量不够", "扩 BE 节点，算力一起买", "扩 OSS 容量，按量付费"],
            ["后端点查压力增大", "扩 BE 或加集群，I/O 竞争仍在", "扩 MySQL 读副本/Redis 规格，成本可控"],
            ["闲时降本", "缩不下来（BE 带着数据）", "CN 可以缩，OSS 和 MySQL 保底"],
        ]
    )

    # Section 6 - Business fit
    pdf.h2("小蚕业务适配性")

    pdf.h3("命中的点")
    pdf.body("外卖业务的读写模式天然分层——下单、改状态、查订单详情是 OLTP（高频点查），看板、报表、用户分析是 OLAP（大扫聚合）。把两种负载塞进一个列存引擎里，就是目前 3 秒超时的根因。读写分离、分析和服务分层这个大方向，对小蚕是对的。")

    pdf.h3("要不要上 Paimon？分情况看")
    pdf.body("Paimon 解决的核心问题是实时湖格式（ACID、Upsert、Time Travel）和共享存储多引擎访问。但它引入了一条额外的 CDC 链路和 Flink 运维负担。小蚕目前的核心痛点不是湖格式，是后端点查超时。")
    pdf.body("值得上 Paimon 的情况：")
    pdf.body("· 数据量已到几十 TB 且持续涨，存储成本成为主要矛盾")
    pdf.body("· 有多引擎共享同一份数据的需求（StarRocks + Flink + Spark 都要读）")
    pdf.body("· 需要 Time Travel 做数据回溯（财务对账、历史快照查询）")
    pdf.body("· 有专门的数据平台团队维护 Flink 和 Paimon 集群")
    pdf.ln(2)
    pdf.body("如果以上不满足，更简方案：应用层双写——写数据时同时写 StarRocks 和 MySQL，StarRocks 专注分析，MySQL 扛后端点查，Redis 做热缓存。同样解决 3 秒超时，组件更少、运维更轻、往后再按需补 Paimon。这个路径可以分步走——先做 MySQL/Redis 服务层，跑通了再看要不要加 Paimon 做湖格式，不用一步到位。")

    pdf.ln(6)
    pdf.set_fill_color(255, 248, 197)
    pdf.set_draw_color(212, 167, 44)
    pdf.set_line_width(0.5)
    y_box = pdf.get_y()
    pdf.rect(pdf.l_margin + 2, y_box, w - 4, 14, style="DF")
    pdf.set_xy(pdf.l_margin + 8, y_box + 3)
    pdf.set_font("CJK", "B", 10)
    pdf.set_text_color(120, 80, 0)
    pdf.cell(w - 16, 8, "综合判断：存算分离、读写分层的方向没错，但不必一步到位到 Paimon。核心矛盾是 OLTP"
             "不该打 OLAP 数据库——先把 MySQL/Redis 服务层建起来，StarRocks 回归分析，"
             "已经可以解决 3 秒超时。Paimon 留到数据规模上来、存储成本成为主要矛盾时再上。")

    path = "/Users/dataanalysis_dahe/Desktop/claude-data-analysis-main/架构演进.pdf"
    pdf.output(path)
    print(f"Done: {path}")


if __name__ == "__main__":
    gen()
