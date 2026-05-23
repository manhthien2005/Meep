"""Extract the section outline + figure list from the sample SRS PDF into JSON.

Deterministic parse of the PDF's own table-of-contents pages — no hand-typing,
so the JSON faithfully mirrors the template structure. Run:

    python reports/_template/tools/extract_outline.py

Outputs reports/_template/srs-sample-outline.json
"""

import json
import re
import sys
from pathlib import Path

import fitz  # PyMuPDF

REPORTS = Path(__file__).resolve().parents[2]  # reports/_template/tools -> reports/
PDF = next(REPORTS.glob("Nhom1_*SRS_FinalProject*.pdf"))
OUT = REPORTS / "_template" / "srs-sample-outline.json"

# TOC (Mục lục) lives on pages 2-4; figure index (Mục lục hình ảnh) on pages 5-6.
TOC_PAGES = (2, 3, 4)
FIG_PAGES = (5, 6)

# "1.2.3. Title ....... 12"  (number + title + page on one physical line)
FULL = re.compile(r"^(\d+(?:\.\d+)*)\.\s*(.+?)\s*\.{3,}\s*(\d+)\s*$")
# "1.2.3."  (sub-section number alone on its line; title follows on the next)
NUM_ONLY = re.compile(r"^(\d+(?:\.\d+)*)\.\s*$")
# "Title ....... 12"  (the dangling title line that follows a NUM_ONLY)
TITLE_PAGE = re.compile(r"^(.+?)\s*\.{3,}\s*(\d+)\s*$")
# "Hình 12. Caption ....... 34"  (figure index entry; '.' after number optional)
FIG = re.compile(r"^(Hình\s+\d+)\.?\s+(.+?)\s*\.{2,}\s*(\d+)\s*$")
FIG_START = re.compile(r"^Hình\s+\d+\b")


def page_text(doc, pages):
    return "\n".join(doc[p - 1].get_text() for p in pages)


def parse_toc(text):
    sections, pending = [], None
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line == "MỤC LỤC":
            continue
        if pending:  # previous line was a bare section number
            m = TITLE_PAGE.match(line)
            if m:
                sections.append(_entry(pending, m.group(1), m.group(2)))
                pending = None
                continue
            pending = None  # malformed; drop and fall through
        m = FULL.match(line)
        if m:
            sections.append(_entry(m.group(1), m.group(2), m.group(3)))
            continue
        m = NUM_ONLY.match(line)
        if m:
            pending = m.group(1)
    return sections


def _entry(number, title, page):
    return {
        "number": number,
        "level": number.count(".") + 1,
        "title": title.strip(),
        "page": int(page),
    }


def parse_figures(text):
    figures, buf = [], None
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith("MỤC LỤC"):
            continue
        candidate = (buf + " " + line) if buf else line
        m = FIG.match(candidate)
        if m:
            figures.append({"id": m.group(1), "caption": m.group(2).strip(), "page": int(m.group(3))})
            buf = None
        elif FIG_START.match(candidate):
            buf = candidate  # caption wraps to next line; keep buffering
    return figures


def main():
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")  # Windows console defaults to cp1252
    doc = fitz.open(PDF)
    sections = parse_toc(page_text(doc, TOC_PAGES))
    figures = parse_figures(page_text(doc, FIG_PAGES))
    payload = {
        "source_pdf": PDF.name,
        "page_count": doc.page_count,
        "section_count": len(sections),
        "figure_count": len(figures),
        "sections": sections,
        "figures": figures,
    }
    OUT.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"sections={len(sections)} figures={len(figures)} -> {OUT.relative_to(REPORTS.parent)}")
    top = [s for s in sections if s["level"] == 1]
    print("top-level chapters:", ", ".join(f'{s["number"]} {s["title"]}' for s in top))
    if len(top) != 6:
        print("WARN: expected 6 top-level chapters", file=sys.stderr)


if __name__ == "__main__":
    main()
