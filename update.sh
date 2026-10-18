#!/bin/sh
# Regenerate index.html (sites, docs, audio) and pages.html (loose mirrored pages)
# from the folder contents, then check that every local link in both resolves.
# Usage: ./update.sh [directory]
# names.json next to this script maps a site folder to its display name.
# binds next to this script lists folders that live on another drive (see run-quark.sh).
# ajatt.txt lists AJATT folders without a sibling page; all AJATT entries go to ajatt.html.
TARGET="${1:-$HOME/localdocs}"
HERE="$(cd "$(dirname "$0")" && pwd)"
export NAMES_FILE="$HERE/names.json" BINDS_FILE="$HERE/binds" AJATT_FILE="$HERE/ajatt.txt"
cd "$TARGET" || exit 1
exec python3 - <<'PY'
import os, re, sys, html, json, urllib.parse as up

SKIP_DIRS = {"images", "docs"}
TITLE = re.compile(rb"<title[^>]*>(.*?)</title>", re.I | re.S)
MIRROR_NOISE = re.compile(rb"\s*\|.*$", re.S)  # drop " | Site name" suffixes

def disp(n):  return n.encode("utf-8", "surrogateescape").decode("utf-8", "replace")
def href(n):  return up.quote(os.fsencode(n))
def title_of(path, fallback):
    try:
        with open(path, "rb") as f:
            m = TITLE.search(f.read(16384))
    except OSError:
        m = None
    if m:
        t = re.sub(rb"\s+", b" ", m.group(1)).strip()
        t = html.unescape(t.decode("utf-8", "replace"))
        if t: return t
    return disp(fallback)
def link(url, text): return f'<li><a href="{url}">{html.escape(text)}</a></li>'

def page(title, body):
    return ('<!doctype html><html lang="en"><meta charset="utf-8">'
            '<meta name="viewport" content="width=device-width,initial-scale=1">'
            f'<title>{html.escape(title)}</title>'
            '<style>body{font:16px/1.5 system-ui,sans-serif;max-width:60rem;margin:2rem auto;padding:0 1rem;'
            'background:#fff;color:#222}h1{margin-bottom:0}h2{border-bottom:1px solid #ccc;margin-top:2rem}'
            'ul{columns:18rem;padding-left:1.2rem}li{break-inside:avoid;margin:.2rem 0}'
            'a{color:#0645ad}.ext{border-left:4px solid #c77700;padding-left:.5rem}.ext a{color:#a35a00}'
            '.ext code{color:#555}.missing{color:#c00;font-weight:bold}'
            '@media(prefers-color-scheme:dark){body{background:#181818;color:#ddd}a{color:#8ab4f8}'
            'h2{border-color:#444}.ext a{color:#f0b35a}.ext code{color:#aaa}.missing{color:#ff6b6b}}</style>' + body)

def write(name, text):
    tmp = name + ".tmp"
    with open(tmp, "w", encoding="utf-8", errors="surrogateescape") as f: f.write(text)
    if os.path.getsize(tmp) == 0: sys.exit("refusing to write empty " + name)
    os.replace(tmp, name)

VARIANT = re.compile(r"^(.+)[0-9a-f]{4}\.html$")  # HTTrack saves ?query variants as <base><hash>.html
NAMES_FILE = os.environ["NAMES_FILE"]
NAMES = json.load(open(NAMES_FILE, encoding="utf-8")) if os.path.isfile(NAMES_FILE) else {}
def lines(f): return [l.strip() for l in open(f, encoding="utf-8") if l.strip() and not l.startswith("#")] if os.path.isfile(f) else []
AJATT = set(lines(os.environ["AJATT_FILE"]))
AJATT_MARK = b"alljapaneseallthetime"
def is_ajatt(path):
    with open(path, "rb") as f: return AJATT_MARK in f.read(65536)
top = sorted(os.listdir("."), key=lambda s: s.lower())
names = set(top); variants = 0
sites, ajatt, docs, audio, pages, linked = [], [], [], [], [], set()  # sites/ajatt hold (sort key, <li>)
for n in top:
    if os.path.isdir(n):
        if n in SKIP_DIRS or n.endswith("_files") or n.startswith("."): continue
        idx = os.path.join(n, "index.html")
        if os.path.isfile(idx):
            t = title_of(idx, n)  # HTTrack's generic "Local index - HTTrack ..." says nothing; show the folder name
            stub = t.startswith("Local index")
            # A failed HTTrack mirror holds only a stub; its real page is the sibling <n>.html.
            sib = stub and n + ".html" in names
            if sib: url = href(n + ".html"); linked.add(n + ".html")
            else: url = href(n) + "/index.html"
            item = (n.lower(), link(url, NAMES.get(n) or (disp(n) if stub else t + "  (" + disp(n) + ")")))
            (ajatt if n in AJATT or sib and is_ajatt(n + ".html") else sites).append(item)
    elif n.endswith(".mp3"): audio.append(link(href(n), disp(n)))
    elif n.endswith(".html") and n not in ("index.html", "pages.html"):
        m = VARIANT.match(n)
        if m and (m.group(1) + ".html") in names: variants += 1
        else: pages.append((title_of(n, n), n))
# Folders bind-mounted from another drive: colored, with where the data really lives.
for line in lines(os.environ["BINDS_FILE"]):
    path, target = line.split(None, 1)
    here = os.path.isdir(target) and os.listdir(target)
    sites.append((path.lower(), f'<li class=ext><a href="{href(path)}/">{html.escape(NAMES.get(path, path))}</a>'
                  f' <code>-&gt; {html.escape(target)}</code>'
                  + ("" if here else ' <span class=missing>drive not attached</span>') + "</li>"))
if ajatt:
    sites.append(("ajatt", link("ajatt.html", f"AJATT: All Japanese All The Time ({len(ajatt)} pages)")))
sites = [li for _, li in sorted(sites)]
if os.path.isdir("docs"):
    for n in sorted(os.listdir("docs"), key=str.lower): docs.append(link("docs/" + href(n), disp(n)))

sec = lambda h, items: f"<h2>{h} ({len(items)})</h2><ul>{''.join(items)}</ul>" if items else ""
FILTER = ('<p><input id=q placeholder="filter" autofocus style="width:100%;font:inherit;padding:.4rem"></p>'
          '<script>q.oninput=()=>{const t=q.value.toLowerCase();for(const l of document.querySelectorAll("li"))'
          'l.hidden=!l.textContent.toLowerCase().includes(t)}</script>')
body = ("<h1>localdocs</h1><p>Local mirror of reference sites. Run <code>./update.sh</code> to rebuild this page.</p>"
        f'<p><a href="pages.html">All {len(pages)} loose mirrored pages</a> ({variants} ?query variants hidden)</p>'
        + FILTER + sec("Sites", sites) + sec("Documents", docs) + sec("Audio", audio))
write("index.html", page("localdocs", body))
write("ajatt.html", page("localdocs: AJATT", '<p><a href="index.html">Home</a></p><h1>AJATT: All Japanese All The Time</h1>'
      + FILTER + "<ul>" + "".join(li for _, li in sorted(ajatt, key=lambda a: a[1].lower())) + "</ul>"))
pages = [p for p in pages if p[1] not in linked]  # already listed under Sites
pages.sort(key=lambda p: p[0].lower())
write("pages.html", page("localdocs: all pages", '<p><a href="index.html">Home</a></p><h1>Pages</h1>' + FILTER + '<ul>'
      + "".join(link(href(n), t) for t, n in pages) + "</ul>"))
print(f"index.html: {len(sites)} sites, {len(docs)} docs, {len(audio)} audio; ajatt.html: {len(ajatt)}; pages.html: {len(pages)} pages")

# Link check on the two generated files: every local href must exist.
HREF = re.compile(r'href="([^"]*)"')
bad = 0
for f in ("index.html", "ajatt.html", "pages.html"):
    for u in HREF.findall(open(f, encoding="utf-8", errors="surrogateescape").read()):
        if re.match(r"[a-z]+:", u): continue
        p = up.unquote_to_bytes(html.unescape(u).split("#")[0].split("?")[0])
        if p and not os.path.exists(p):
            print("BROKEN", f, u); bad += 1
print("link check:", "FAIL %d broken" % bad if bad else "ok, all links resolve")
sys.exit(1 if bad else 0)
PY
