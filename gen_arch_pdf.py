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
    pdf.subtitle("从小蚕 StarRocks 存算一体到 Flink 双出 + MySQL 服务层")

    # Section 1
    pdf.h2("现状：StarRocks 被当成全能层")
    pdf.body("StarRocks 同时承接 OLAP（分析）+ OLTP（点查）+ 存储，后端服务直接查 StarRocks 时延迟不可控。", size=10)
    pdf.ln(2)

    # Current problem diagram
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

    # Section 3 - Target architecture: Flink dual-sink
    pdf.h2("改造方案：Flink 双出 + MySQL 服务层")
    pdf.ln(2)

    pdf.set_fill_color(230, 244, 234)
    pdf.set_draw_color(26, 127, 55)
    pdf.set_line_width(0.8)
    pdf.rect(pdf.l_margin, pdf.get_y(), w, 34, style="DF")
    y0 = pdf.get_y() + 2
    pdf.set_xy(pdf.l_margin + 5, y0)
    pdf.set_font("CJK", "B", 10)
    pdf.set_text_color(26, 127, 55)
    pdf.cell(w - 10, 6, "改造方案 — 不动链路，只加 sink")
    pdf.set_xy(pdf.l_margin + 5, y0 + 8)
    pdf.set_font("CJK", "", 8)
    pdf.set_text_color(40, 80, 40)
    lines = [
        "MySQL 业务库 ──CDC──→ Flink（现有链路）──原有 sink──→ StarRocks（分析）",
        "                                    └─新增 sink──→ 后端 MySQL（结果表）",
        "Kafka 用户日志 ──→ Flink（现有链路）──原有 sink──→ StarRocks（分析）",
        "                                    └─新增 sink──→ 后端 MySQL（结果表）",
        "                                                           │",
        "                                                      后端服务（< 50ms）",
        "                                                           │",
        "                                                    看板 / 报表",
    ]
    for l in lines:
        pdf.set_xy(pdf.l_margin + 5, pdf.get_y())
        pdf.cell(w - 10, 4.5, l)
        pdf.ln(4.5)
    y_end = pdf.get_y()
    pdf.set_y(y_end + 4)
    pdf.body("Flink 已经在跑，后端 MySQL 本来就有，改造只做两件事：1) Flink 作业加一个 MySQL JDBC sink，把后端需要的结果表写到后端 MySQL；2) 后端服务把查询切到 MySQL。不新增组件，不改业务代码。")

    # Section 4 - Responsibilities
    pdf.h2("各层职责")
    pdf.table(
        ["层", "角色"],
        [
            ["Flink", "数据中转与计算。消费 binlog 和 Kafka，清洗聚合后双出到 StarRocks 和 MySQL"],
            ["StarRocks", "分析查询。只接 Flink 写入，不再直接扛后端点查"],
            ["后端 MySQL", "扛住后端 OLTP 点查。Flink 把预计算好的结果表写到这里"],
            ["后端服务", "只访问 MySQL，延迟 < 50ms"],
        ]
    )

    pdf.ln(6)
    pdf.h2("跟现状的核心区别")
    pdf.table(
        ["现状", "改造后"],
        [
            ["Flink 只出 StarRocks", "Flink 双出：StarRocks + MySQL"],
            ["StarRocks 扛点查", "MySQL 扛点查"],
            ["后端服务查 StarRocks", "后端服务查 MySQL"],
            ["一套集群扛所有负载", "分析（StarRocks）和服务（MySQL）分层"],
            ["后端 3 秒超时", "后端 50ms 以内"],
            ["再搭一套 SR 做隔离，冗余成本翻倍", "不新增组件，Flink 多一个 sink"],
        ]
    )

    # Section 5 - Cost analysis
    pdf.h2("成本分析")
    pdf.body("改造几乎没有增量成本——Flink 和 MySQL 都是现有组件：")
    pdf.body("· Flink 加一个 sink 不增加 TaskManager，写入量不变")
    pdf.body("· 后端 MySQL 加几张结果表，存储增量很小（只存后端要查的列，不存全量明细）")
    pdf.body("· 不引入 OSS / Paimon / Redis / StarRocks CN 等新组件")
    pdf.ln(2)
    pdf.body("跟此前两套 StarRocks 集群方案或 Paimon 路线比，这条路没有新组件开销，只有一次性的 Flink 作业改造和结果表建表工作。")

    pdf.h3("边际成本对比")
    pdf.table(
        ["场景", "当前", "Flink 双出后"],
        [
            ["分析查询增加", "扩 BE 节点，磁盘一起买", "StarRocks 只跑分析，扩容不变但节奏可控"],
            ["后端点查压力增大", "扩 BE 或加集群，I/O 竞争仍在", "扩 MySQL 读副本，成本远低于扩 BE"],
            ["闲时降本", "缩不下来（BE 带着数据）", "StarRocks 分析侧可考虑缩容"],
            ["新增数据链路", "新链路从头建", "往 Flink 上加 sink 即可"],
        ]
    )

    # Section 6 - Future evolution
    pdf.h2("后续演进：什么时候加 Paimon")
    pdf.body("Flink 双出解决的是当前最紧迫的问题——后端点查超时。Paimon + StarRocks 存算分离解决的是另一个层次的问题：数据量到几十 TB 后存储成本压不住、需要多引擎共享同一份数据、需要 Time Travel 做数据回溯。")
    pdf.body("当前阶段不必上 Paimon，但 Flink 双出的架构天然兼容后续演进——StarRocks 那路的数据已经管好了，以后如果要切到 Paimon 做湖格式，只需要把 StarRocks 的写入目标从内部表改成 Paimon 外表，Flink → MySQL 这条服务链路完全不受影响。")
    pdf.body("加 Paimon 的触发条件：")
    pdf.body("· 数据量到几十 TB，StarRocks 本地存储成本成为主要矛盾")
    pdf.body("· 有多引擎共享同一份数据的需求（StarRocks + Flink + Spark 都要读同一份）")
    pdf.body("· 需要 Time Travel 做数据回溯（财务对账、历史快照）")
    pdf.body("· 有专门的数据平台团队能维护 Paimon 集群")

    pdf.ln(6)
    pdf.set_fill_color(255, 248, 197)
    pdf.set_draw_color(212, 167, 44)
    pdf.set_line_width(0.5)
    y_box = pdf.get_y()
    pdf.rect(pdf.l_margin + 2, y_box, w - 4, 14, style="DF")
    pdf.set_xy(pdf.l_margin + 8, y_box + 3)
    pdf.set_font("CJK", "B", 10)
    pdf.set_text_color(120, 80, 0)
    pdf.cell(w - 16, 8, "结论：Flink 加一个 MySQL sink，后端服务切到 MySQL，3 秒超时直接解决。"
             "不动链路、不建新集群、不加组件，现有条件下最省路径。"
             "Paimon 留到数据规模上来再说，Flink 双出的架构到时候可以平滑切过去。")

    path = "/Users/dataanalysis_dahe/Desktop/claude-data-analysis-main/架构演进.pdf"
    pdf.output(path)
    print(f"Done: {path}")


if __name__ == "__main__":
    gen()
