from fpdf import FPDF
import os

FONT_PATH = "/Library/Fonts/Arial Unicode.ttf"

class ChinesePDF(FPDF):
    def __init__(self):
        super().__init__('P', 'mm', 'A4')
        self.add_font("CJK", "", FONT_PATH, uni=True)
        self.add_font("CJK", "B", FONT_PATH, uni=True)  # fpdf2 uses same font for bold
        self.set_auto_page_break(True, 20)

    def header(self):
        pass

    def footer(self):
        self.set_y(-18)
        self.set_font("CJK", "", 7)
        self.set_text_color(150, 150, 150)
        self.cell(0, 10, f"第 {self.page_no()} 页", align='C')

def parse_md(filepath):
    """Simple markdown parser returning list of (type, content) tuples."""
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    elements = []
    i = 0
    while i < len(lines):
        line = lines[i].rstrip()

        if not line:
            i += 1
            continue

        # Horizontal rule ---
        if line.strip() == '---':
            elements.append(('hr', ''))
            i += 1
            continue

        # H1 heading
        if line.startswith('# '):
            elements.append(('h1', line[2:].strip()))
            i += 1
            continue

        # Bold inline **text** (person info line)
        if line.startswith('**') and line.endswith('**'):
            elements.append(('title_line', line.strip('*')))
            i += 1
            continue

        # H2 heading
        if line.startswith('## '):
            elements.append(('h2', line[3:].strip()))
            i += 1
            continue

        # H3 heading (company line with bold)
        if line.startswith('### '):
            elements.append(('h3', line[4:].strip()))
            i += 1
            continue

        # Bold company title **...**
        if line.startswith('**') and '|' in line:
            # Company + date + title lines like **xxx | date**
            elements.append(('company_title', line.strip('*')))
            i += 1
            continue

        # Company info line (starts with 公司简介)
        if line.startswith('公司简介') or line.startswith('**公司简介'):
            text = line.replace('**', '').strip()
            elements.append(('company_desc', text))
            i += 1
            continue

        # Bullet point
        if line.startswith('- **') or line.startswith('- '):
            text = line[2:].strip()
            elements.append(('bullet', text))
            i += 1
            continue

        # Table row
        if line.startswith('|'):
            elements.append(('table_row', line.strip()))
            i += 1
            continue

        elements.append(('text', line))
        i += 1

    return elements


def render_pdf(md_path, output_path):
    elements = parse_md(md_path)
    pdf = ChinesePDF()
    pdf.add_page()

    for elem_type, content in elements:
        if elem_type == 'h1':
            pdf.set_font("CJK", "B", 18)
            pdf.set_text_color(0, 0, 0)
            pdf.cell(0, 10, content, new_x="LMARGIN", new_y="NEXT")
            pdf.ln(2)

        elif elem_type == 'title_line':
            pdf.set_font("CJK", "", 11)
            pdf.set_text_color(80, 80, 80)
            pdf.cell(0, 7, content, new_x="LMARGIN", new_y="NEXT")
            pdf.ln(3)

        elif elem_type == 'hr':
            pdf.set_draw_color(68, 114, 196)
            pdf.set_line_width(0.5)
            y = pdf.get_y()
            pdf.line(pdf.l_margin, y, pdf.w - pdf.r_margin, y)
            pdf.ln(4)

        elif elem_type == 'h2':
            pdf.ln(2)
            pdf.set_font("CJK", "B", 14)
            pdf.set_text_color(0, 0, 0)
            pdf.cell(0, 9, content, new_x="LMARGIN", new_y="NEXT")
            # Underline for section headers
            y = pdf.get_y()
            pdf.set_draw_color(68, 114, 196)
            pdf.set_line_width(0.4)
            pdf.line(pdf.l_margin, y, pdf.w - pdf.r_margin, y)
            pdf.ln(4)

        elif elem_type == 'h3':
            pdf.set_font("CJK", "B", 12)
            pdf.set_text_color(68, 114, 196)
            pdf.cell(0, 8, content, new_x="LMARGIN", new_y="NEXT")
            pdf.ln(1)

        elif elem_type == 'company_title':
            pdf.set_font("CJK", "B", 11)
            pdf.set_text_color(0, 0, 0)
            pdf.cell(0, 7, content, new_x="LMARGIN", new_y="NEXT")

        elif elem_type == 'company_desc':
            pdf.set_font("CJK", "", 8.5)
            pdf.set_text_color(120, 120, 120)
            pdf.set_x(pdf.l_margin + 5)
            pdf.multi_cell(pdf.w - pdf.l_margin - pdf.r_margin - 10, 5, content)
            pdf.ln(1)

        elif elem_type == 'bullet':
            pdf.set_font("CJK", "", 10)
            pdf.set_text_color(50, 50, 50)
            bullet_text = content

            # Check for bold markup inside bullet
            if bullet_text.startswith('**'):
                end_bold = bullet_text.find('**', 2)
                if end_bold > 0:
                    bold_part = bullet_text[2:end_bold]
                    rest = bullet_text[end_bold+2:].lstrip('：: ')
                    full = f"{bold_part}：{rest}" if rest else bold_part
                    # Draw bullet
                    pdf.set_x(pdf.l_margin + 8)
                    pdf.set_font("CJK", "", 9)
                    pdf.set_text_color(68, 114, 196)
                    pdf.cell(4, 5, "•")
                    pdf.set_font("CJK", "B", 10)
                    pdf.set_text_color(50, 50, 50)
                    pdf.multi_cell(pdf.w - pdf.l_margin - pdf.r_margin - 18, 5.5, full)
                else:
                    pdf.set_x(pdf.l_margin + 8)
                    pdf.set_font("CJK", "", 9)
                    pdf.set_text_color(68, 114, 196)
                    pdf.cell(4, 5, "•")
                    pdf.set_font("CJK", "", 10)
                    pdf.set_text_color(50, 50, 50)
                    pdf.multi_cell(pdf.w - pdf.l_margin - pdf.r_margin - 18, 5.5, bullet_text)
            else:
                pdf.set_x(pdf.l_margin + 8)
                pdf.set_font("CJK", "", 9)
                pdf.set_text_color(68, 114, 196)
                pdf.cell(4, 5, "•")
                pdf.set_font("CJK", "", 10)
                pdf.set_text_color(50, 50, 50)
                pdf.multi_cell(pdf.w - pdf.l_margin - pdf.r_margin - 18, 5.5, bullet_text)
            pdf.ln(0.5)

        elif elem_type == 'table_row':
            cells = [c.strip() for c in content.split('|') if c.strip()]
            # Skip separator rows
            if all(c.replace('-', '').replace(' ', '') == '' for c in cells):
                continue
            pdf.set_font("CJK", "", 8.5)
            pdf.set_text_color(50, 50, 50)
            col_w = (pdf.w - pdf.l_margin - pdf.r_margin) / len(cells)
            for cell in cells:
                pdf.cell(col_w, 6, cell)
            pdf.ln()

        elif elem_type == 'text':
            pdf.set_font("CJK", "", 10)
            pdf.set_text_color(50, 50, 50)
            pdf.multi_cell(pdf.w - pdf.l_margin - pdf.r_margin, 5.5, content)
            pdf.ln(0.5)

    pdf.output(output_path)
    print(f"  -> {output_path}")


if __name__ == "__main__":
    base = "/Users/dataanalysis_dahe/Desktop/claude-data-analysis-main/resume"
    files = [
        ("应聘商业分析_王静_13106133373.md", "应聘商业分析_王静_13106133373.pdf"),
        ("应聘策略分析_王静_13106133373.md", "应聘策略分析_王静_13106133373.pdf"),
        ("应聘数据分析师_王静_13106133373.md", "应聘数据分析师_王静_13106133373.pdf"),
        ("应聘数据分析负责人_王静_13106133373.md", "应聘数据分析负责人_王静_13106133373.pdf"),
        ("应聘数据产品经理_王静_13106133373.md", "应聘数据产品经理_王静_13106133373.pdf"),
    ]

    for md_file, pdf_file in files:
        md_path = os.path.join(base, md_file)
        pdf_path = os.path.join(base, pdf_file)
        print(f"Generating: {md_file} -> {pdf_file}")
        try:
            render_pdf(md_path, pdf_path)
        except Exception as e:
            print(f"  ERROR: {e}")
            import traceback
            traceback.print_exc()

    print("\nDone. All PDFs generated.")
