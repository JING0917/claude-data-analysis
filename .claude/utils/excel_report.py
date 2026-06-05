"""
Excel report writer — produces formatted multi-sheet .xlsx with native charts.

Usage:
    from excel_report import ExcelReport

    report = ExcelReport("output.xlsx")
    report.add_overview({"总订单量": 125000, "同比": "+12.3%", "客单价": 38.5})
    report.add_data_sheet("订单明细", df)
    report.add_chart_sheet("趋势图", "line", df, x_col="日期", y_cols=["订单量", "营收"])
    report.add_chart_sheet("对比图", "bar", df, x_col="城市", y_cols=["订单量"])
    report.save()
"""

import xlsxwriter
import io
import os

HEADER_STYLE = {
    "bold": True,
    "bg_color": "#4472C4",
    "font_color": "#FFFFFF",
    "border": 1,
    "align": "center",
    "valign": "vcenter",
    "font_size": 11,
}

DATA_STYLE = {
    "border": 1,
    "valign": "vcenter",
    "font_size": 10,
}

TITLE_STYLE = {
    "bold": True,
    "font_size": 14,
    "font_color": "#1F3864",
}

KPI_LABEL_STYLE = {
    "font_size": 10,
    "font_color": "#666666",
    "valign": "vcenter",
}

KPI_VALUE_STYLE = {
    "bold": True,
    "font_size": 18,
    "font_color": "#1F3864",
}

KPI_DELTA_UP = {"bold": True, "font_size": 12, "font_color": "#006100"}
KPI_DELTA_DOWN = {"bold": True, "font_size": 12, "font_color": "#9C0006"}

def _is_delta(val):
    s = str(val).strip()
    return s.startswith("+") or s.startswith("-") or "%" in s

def _parse_delta(val):
    s = str(val).strip().rstrip("%")
    return float(s)

class ExcelReport:
    def __init__(self, filepath):
        self.filepath = filepath
        self.wb = xlsxwriter.Workbook(filepath, {"nan_inf_to_errors": True})
        self._formats = {}
        self._init_formats()

    def _init_formats(self):
        f = self._formats
        f["header"] = self.wb.add_format(HEADER_STYLE)
        f["data"] = self.wb.add_format(DATA_STYLE)
        f["data_num"] = self.wb.add_format({**DATA_STYLE, "num_format": "#,##0"})
        f["data_pct"] = self.wb.add_format({**DATA_STYLE, "num_format": "0.0%"})
        f["data_dec"] = self.wb.add_format({**DATA_STYLE, "num_format": "#,##0.00"})
        f["data_date"] = self.wb.add_format({**DATA_STYLE, "num_format": "yyyy-mm-dd"})
        f["title"] = self.wb.add_format(TITLE_STYLE)
        f["kpi_label"] = self.wb.add_format(KPI_LABEL_STYLE)
        f["kpi_value"] = self.wb.add_format(KPI_VALUE_STYLE)
        f["kpi_up"] = self.wb.add_format(KPI_DELTA_UP)
        f["kpi_down"] = self.wb.add_format(KPI_DELTA_DOWN)
        f["section"] = self.wb.add_format({"bold": True, "font_size": 12, "bottom": 2, "font_color": "#1F3864"})
        f["pct_red"] = self.wb.add_format({**DATA_STYLE, "num_format": "0.0%", "font_color": "#9C0006"})
        f["pct_green"] = self.wb.add_format({**DATA_STYLE, "num_format": "0.0%", "font_color": "#006100"})

    def add_overview(self, title, metrics, subtitle=None):
        """KPI card row at top of overview sheet."""
        ws = self.wb.add_worksheet("概览") if "概览" not in [s.get_name() for s in self.wb.worksheets()] else self.wb.get_worksheet_by_name("概览")
        row = 0

        ws.merge_range(row, 0, row, 7, title, self._formats["title"])
        row += 1
        if subtitle:
            ws.merge_range(row, 0, row, 7, subtitle, self._formats["kpi_label"])
            row += 1
        row += 1

        col = 0
        dt_format = self.wb.add_format({"font_size": 9, "font_color": "#999999"})
        for label, value in metrics.items():
            if isinstance(value, (list, tuple)):
                main_val, delta = value[0], value[1]
            else:
                main_val, delta = value, None

            ws.merge_range(row, col, row, col + 1, label, self._formats["kpi_label"])
            ws.merge_range(row + 1, col, row + 1, col + 1, str(main_val), self._formats["kpi_value"])
            ws.set_column(col, col, 22)
            ws.set_column(col + 1, col + 1, 4)

            if delta is not None:
                if _is_delta(delta):
                    d = _parse_delta(delta)
                    fmt = self._formats["kpi_up"] if d >= 0 else self._formats["kpi_down"]
                else:
                    fmt = self._formats["kpi_label"]
                ws.write(row + 1, col + 1, f" {delta}", fmt)

            ws.write(row + 2, col, "", dt_format)
            col += 2
            if col > 6:
                col = 0
                row += 4

        ws.set_default_row(18)
        return ws

    def add_data_sheet(self, sheet_name, df, freeze_cols=0):
        """Write a formatted data table sheet. Returns worksheet name."""
        name = sheet_name[:31]
        ws = self.wb.add_worksheet(name)
        ws.freeze_panes(1, freeze_cols)

        for c, col_name in enumerate(df.columns):
            ws.write(0, c, str(col_name), self._formats["header"])

        for r, (_, row_data) in enumerate(df.iterrows()):
            for c, val in enumerate(row_data):
                fmt = self._get_data_format(df, c, val)
                ws.write(r + 1, c, val, fmt)

        self._auto_width(ws, df)
        ws.autofilter(0, 0, len(df), len(df.columns) - 1)
        return ws

    def add_chart_sheet(self, sheet_name, chart_type, df, x_col, y_cols, title=None):
        """Add a sheet with a native Excel chart linked to data."""
        name = sheet_name[:31]
        data_sheet_name = f"_data_{name}"[:31]

        ws_data = self.wb.add_worksheet(data_sheet_name)

        col_names = [x_col] + list(y_cols)
        for c, cn in enumerate(col_names):
            ws_data.write(0, c, str(cn), self._formats["header"])

        for r, (_, row_data) in enumerate(df[col_names].iterrows()):
            for c, val in enumerate(row_data):
                ws_data.write(r + 1, c, val, self._get_data_format(df[col_names], c, val))

        n_rows = len(df)
        n_cols = len(col_names)
        cat_range = [data_sheet_name, 1, 1, n_rows, 0]

        chart = self.wb.add_chart({"type": chart_type})
        chart.set_title({"name": title or sheet_name})
        chart.set_size({"width": 900, "height": 480})
        chart.set_legend({"position": "bottom"})

        colors = ["#4472C4", "#ED7D31", "#A5A5A5", "#FFC000", "#5B9BD5", "#70AD47"]
        for i, yc in enumerate(y_cols):
            val_range = [data_sheet_name, 1, i + 1, n_rows, i + 1]
            chart.add_series({
                "name": yc,
                "categories": cat_range,
                "values": val_range,
                "fill": {"color": colors[i % len(colors)]},
            })

        ws_chart = self.wb.add_worksheet(name)
        ws_chart.insert_chart("B2", chart)
        ws_data.hide()
        return ws_chart

    def add_conditional_format(self, sheet_name, col_letter, col_idx, df):
        """Apply red/green conditional formatting to a numeric column."""
        ws = self.wb.get_worksheet_by_name(sheet_name)
        if ws is None:
            return
        n_rows = len(df)
        green = self._formats["pct_green"]
        red = self._formats["pct_red"]
        cell_range = f"{col_letter}2:{col_letter}{n_rows + 1}"
        ws.conditional_format(cell_range, {"type": "cell", "criteria": ">=", "value": 0, "format": green})
        ws.conditional_format(cell_range, {"type": "cell", "criteria": "<", "value": 0, "format": red})

    def add_section_header(self, ws, row, col, text, end_col=None):
        end = end_col or col + 5
        ws.merge_range(row, col, row, end, text, self._formats["section"])
        return row + 1

    def save(self):
        self.wb.close()
        return self.filepath

    def _get_data_format(self, df, col_idx, val):
        if val is None or (isinstance(val, float) and str(val) == "nan"):
            return self._formats["data"]
        col_name = str(df.columns[col_idx]).lower()
        if "日期" in col_name or "date" in col_name or "时间" in col_name:
            return self._formats["data_date"]
        if "率" in col_name or col_name.endswith("pct") or col_name.endswith("rate"):
            return self._formats["data_pct"]
        if isinstance(val, float):
            if abs(val) < 10 and val == int(val):
                return self._formats["data_num"]
            return self._formats["data_dec"]
        if isinstance(val, int):
            return self._formats["data_num"]
        return self._formats["data"]

    def _auto_width(self, ws, df):
        """Set column widths based on header and first 100 rows of data."""
        sample = df.head(100)
        for c, col_name in enumerate(df.columns):
            max_w = len(str(col_name)) * 2
            for val in sample.iloc[:, c]:
                max_w = max(max_w, len(str(val)) * 1.2)
            ws.set_column(c, c, min(max(max_w, 8), 36))

    @staticmethod
    def img_to_excel(ws, row, col, fig, scale=0.5):
        """Embed a matplotlib figure as image in a worksheet."""
        buf = io.BytesIO()
        fig.savefig(buf, format="png", dpi=150, bbox_inches="tight")
        buf.seek(0)
        ws.insert_image(row, col, "", {"image_data": buf, "x_scale": scale, "y_scale": scale})
