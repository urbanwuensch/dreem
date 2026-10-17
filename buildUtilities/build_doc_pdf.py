"""Build the complete drEEM documentation as one PDF.

Renders every help page in toolbox/doc with headless Chrome, adds a title page with
table of contents (page numbers) and bookmarks, and merges everything with pypdf.

Usage:  python3 build_doc_pdf.py <repo root> <output pdf>
Needs:  Google Chrome (or CHROME=<path to browser>), Python package pypdf
"""
import os
import re
import shutil
import subprocess
import sys
import tempfile
from datetime import date
from html import escape
from pathlib import Path

try:
    from pypdf import PdfReader, PdfWriter
except ImportError:
    sys.exit("pypdf is missing. Install it with:  python3 -m pip install pypdf")

CHROME_CANDIDATES = [
    os.environ.get("CHROME", ""),
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/Applications/Chromium.app/Contents/MacOS/Chromium",
    "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge",
    r"C:\Program Files\Google\Chrome\Application\chrome.exe",
    "/usr/bin/google-chrome",
    "/usr/bin/chromium",
]

# Sections in the order of toolbox/doc/helptoc.xml; the function reference is added below
OVERVIEW = [
    ("dreem.html", "drEEM Toolbox — Overview"),
    ("Installation of the toolbox.html", "Installation and Requirements"),
    ("function_overview.html", "Function Overview (graphical)"),
    ("Whats new.html", "What's New"),
    ("drEEMdataset.html", "The drEEM Dataset Object"),
    ("drEEMhistory.html", "The Dataset History"),
    ("drEEMstatus.html", "The Dataset Status"),
]
TUTORIALS = [
    ("tutorials.html", "Tutorials — Overview"),
    ("tutorials_01.html", "Tutorials (Toolbox and MATLAB)"),
    ("dreem_workflow.html", "Working with the Toolbox"),
    ("tips_tricks.html", "Tips and Tricks"),
    ("tutorials_02.html", "Tutorials (Toolbox and CDOM Analysis)"),
    ("import_tutorial_01.html", "Simple Data Import (recommended)"),
    ("import_tutorial_02.html", "Complex Data Import (not recommended)"),
    ("processing_tutorial_01.html", "Data Processing"),
    ("prepare4Parafac_tutorial.html", "Data Quality Inspection"),
    ("parafac_tutorial_01.html", "PARAFAC"),
    ("tutorial_export_01.html", "Open Research Data (Data Export)"),
]


def find_chrome():
    for c in CHROME_CANDIDATES:
        if c and Path(c).is_file():
            return c
    for name in ("google-chrome", "chromium", "chrome"):
        if shutil.which(name):
            return shutil.which(name)
    sys.exit("No Chrome/Chromium found. Set the environment variable CHROME to the browser executable.")


def render(chrome, html_file, pdf_file):
    cmd = [chrome, "--headless=new", "--disable-gpu", "--no-pdf-header-footer",
           "--virtual-time-budget=10000", f"--print-to-pdf={pdf_file}",
           Path(html_file).resolve().as_uri()]
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=180)
    if not Path(pdf_file).is_file():
        sys.exit(f"Chrome could not render {html_file}:\n{result.stderr[-2000:]}")


def used_pages(reader):
    """Number of pages without the trailing blank pages that page breaks sometimes create."""
    n = len(reader.pages)
    while n > 1 and not reader.pages[n - 1].extract_text().strip() and not reader.pages[n - 1].images:
        n -= 1
    return n


def toc_html(title, subtitle, sections, first_pages):
    rows = []
    for name, entries in sections:
        rows.append(f'<tr class="section"><td colspan="2">{escape(name)}</td></tr>')
        for (_, label), page in zip(entries, first_pages[name]):
            rows.append(f"<tr><td>{escape(label)}</td><td class='p'>{page}</td></tr>")
    return f"""<!DOCTYPE html><html><head><meta charset="utf-8"><style>
body {{ font-family: Helvetica, Arial, sans-serif; font-size: 11pt; color: #222; margin: 2cm; }}
h1 {{ font-size: 26pt; margin-bottom: 0.2em; }}
.sub {{ color: #555; margin-bottom: 2em; }}
table {{ width: 100%; border-collapse: collapse; }}
td {{ padding: 2px 0; }}
.p {{ text-align: right; width: 4em; }}
.section td {{ font-weight: bold; padding-top: 1em; border-bottom: 1px solid #999; }}
</style></head><body>
<h1>{escape(title)}</h1><div class="sub">{escape(subtitle)}</div>
<h2>Table of Contents</h2><table>{''.join(rows)}</table></body></html>"""


def main(repo, out):
    repo = Path(repo)
    doc = repo / "toolbox" / "doc"
    functions = sorted(p.stem for p in (repo / "documentation" / "functions").glob("*.md")
                       if p.stem != "drEEMstatus")          # already in the overview
    sections = [
        ("Overview", OVERVIEW),
        ("Tutorials", TUTORIALS),
        ("Function Reference", [(f + ".html", f) for f in functions]),
    ]
    missing = [f for _, entries in sections for f, _ in entries if not (doc / f).is_file()]
    if missing:
        sys.exit("Missing help pages in toolbox/doc: " + ", ".join(missing))

    m = re.search(r'version\s*=\s*"([^"]+)"', (repo / "toolbox" / "@drEEMtoolbox" / "drEEMtoolbox.m").read_text())
    version = m.group(1) if m else "unknown"
    title = "drEEM Toolbox Documentation"
    subtitle = f"Version {version} — generated {date.today().isoformat()}"

    chrome = find_chrome()
    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        rendered = {}   # section -> list of (label, PdfReader)
        for name, entries in sections:
            rendered[name] = []
            for k, (f, label) in enumerate(entries):
                pdf = tmp / f"{name[:3]}_{k:03d}.pdf"
                print(f"  {f}", flush=True)
                render(chrome, doc / f, pdf)
                r = PdfReader(pdf)
                rendered[name].append((label, r, used_pages(r)))

        # Table of contents: render once to learn its length, then with final page numbers
        def first_pages(toc_len):
            pages, n = {}, toc_len + 1
            for name, docs in rendered.items():
                pages[name] = []
                for _, _, used in docs:
                    pages[name].append(n)
                    n += used
            return pages

        toc_file, toc_pdf = tmp / "toc.html", tmp / "toc.pdf"
        toc_len = 1
        for _ in range(3):
            toc_file.write_text(toc_html(title, subtitle, sections, first_pages(toc_len)), encoding="utf-8")
            render(chrome, toc_file, toc_pdf)
            n = len(PdfReader(toc_pdf).pages)
            if n == toc_len:
                break
            toc_len = n

        writer = PdfWriter()
        writer.append(PdfReader(toc_pdf))
        writer.add_outline_item("Table of Contents", 0)
        for name, docs in rendered.items():
            parent = None
            for label, r, used in docs:
                start = len(writer.pages)
                writer.append(r, pages=(0, used))
                # bookmarks may only point to pages that already exist
                if parent is None:
                    parent = writer.add_outline_item(name, start)
                writer.add_outline_item(label, start, parent=parent)
        writer.add_metadata({"/Title": title, "/Subject": subtitle})
        out = Path(out)
        out.parent.mkdir(parents=True, exist_ok=True)
        with open(out, "wb") as fh:
            writer.write(fh)
    print(f"Wrote {out} ({len(PdfReader(out).pages)} pages)")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])
