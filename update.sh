#!/bin/sh
# Regenerate index.html (sites, docs, audio) and pages.html (loose mirrored pages)
# from the folder contents, then check that every local link in both resolves.
# Usage: ./update.sh [directory]
TARGET="${1:-$HOME/localdocs}"
cd "$TARGET" || exit 1
exec python3 - <<'PY'
import os, re, sys, html, urllib.parse as up

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
            'a{color:#0645ad}@media(prefers-color-scheme:dark){body{background:#181818;color:#ddd}a{color:#8ab4f8}'
            'h2{border-color:#444}}</style>' + body)

def write(name, text):
    tmp = name + ".tmp"
    with open(tmp, "w", encoding="utf-8", errors="surrogateescape") as f: f.write(text)
    if os.path.getsize(tmp) == 0: sys.exit("refusing to write empty " + name)
    os.replace(tmp, name)

VARIANT = re.compile(r"^(.+)[0-9a-f]{4}\.html$")  # HTTrack saves ?query variants as <base><hash>.html
top = sorted(os.listdir("."), key=lambda s: s.lower())
names = set(top); variants = 0
sites, docs, audio, pages = [], [], [], []
for n in top:
    if os.path.isdir(n):
        if n in SKIP_DIRS or n.endswith("_files") or n.startswith("."): continue
        idx = os.path.join(n, "index.html")
        if os.path.isfile(idx): sites.append(link(href(n) + "/index.html", title_of(idx, n) + "  (" + disp(n) + ")"))
    elif n.endswith(".mp3"): audio.append(link(href(n), disp(n)))
    elif n.endswith(".html") and n not in ("index.html", "pages.html"):
        m = VARIANT.match(n)
        if m and (m.group(1) + ".html") in names: variants += 1
        else: pages.append((title_of(n, n), n))
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
pages.sort(key=lambda p: p[0].lower())
write("pages.html", page("localdocs: all pages", '<p><a href="index.html">Home</a></p><h1>Pages</h1>' + FILTER + '<ul>'
      + "".join(link(href(n), t) for t, n in pages) + "</ul>"))
print(f"index.html: {len(sites)} sites, {len(docs)} docs, {len(audio)} audio; pages.html: {len(pages)} pages")

# Link check on the two generated files: every local href must exist.
HREF = re.compile(r'href="([^"]*)"')
bad = 0
for f in ("index.html", "pages.html"):
    for u in HREF.findall(open(f, encoding="utf-8", errors="surrogateescape").read()):
        if re.match(r"[a-z]+:", u): continue
        p = up.unquote_to_bytes(html.unescape(u).split("#")[0].split("?")[0])
        if p and not os.path.exists(p):
            print("BROKEN", f, u); bad += 1
print("link check:", "FAIL %d broken" % bad if bad else "ok, all links resolve")
sys.exit(1 if bad else 0)
PY
