#!/usr/bin/env python3
"""
Download World English Bible (en-web) from wldeh/bible-api and emit a single JSON
bundle for the Protestant 66-book canon. Strips common inline WEB translator notes
and drops identical full-chapter repeats (common in Psalms in that API feed).

  python3 Scripts/build_web_bible.py

Output: BIBLE TODO/Resources/web_bible.json
"""
from __future__ import annotations

import json
import re
import sys
import time
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT_PATH = ROOT / "BIBLE TODO" / "Resources" / "web_bible.json"
BASE = "https://raw.githubusercontent.com/wldeh/bible-api/main/bibles/en-web/books"

BOOKS: list[tuple[str, int]] = [
    ("genesis", 50),
    ("exodus", 40),
    ("leviticus", 27),
    ("numbers", 36),
    ("deuteronomy", 34),
    ("joshua", 24),
    ("judges", 21),
    ("ruth", 4),
    ("1samuel", 31),
    ("2samuel", 24),
    ("1kings", 22),
    ("2kings", 25),
    ("1chronicles", 29),
    ("2chronicles", 36),
    ("ezra", 10),
    ("nehemiah", 13),
    ("esther", 10),
    ("job", 42),
    ("psalms", 150),
    ("proverbs", 31),
    ("ecclesiastes", 12),
    ("songofsolomon", 8),
    ("isaiah", 66),
    ("jeremiah", 52),
    ("lamentations", 5),
    ("ezekiel", 48),
    ("daniel", 12),
    ("hosea", 14),
    ("joel", 3),
    ("amos", 9),
    ("obadiah", 1),
    ("jonah", 4),
    ("micah", 7),
    ("nahum", 3),
    ("habakkuk", 3),
    ("zephaniah", 3),
    ("haggai", 2),
    ("zechariah", 14),
    ("malachi", 4),
    ("matthew", 28),
    ("mark", 16),
    ("luke", 24),
    ("john", 21),
    ("acts", 28),
    ("romans", 16),
    ("1corinthians", 16),
    ("2corinthians", 13),
    ("galatians", 6),
    ("ephesians", 6),
    ("philippians", 4),
    ("colossians", 4),
    ("1thessalonians", 5),
    ("2thessalonians", 3),
    ("1timothy", 6),
    ("2timothy", 4),
    ("titus", 3),
    ("philemon", 1),
    ("hebrews", 13),
    ("james", 5),
    ("1peter", 5),
    ("2peter", 3),
    ("1john", 5),
    ("2john", 1),
    ("3john", 1),
    ("jude", 1),
    ("revelation", 22),
]


def clean_verse_text(text: str) -> str:
    s = text
    for _ in range(12):
        prev = s
        s = re.sub(r"([a-zA-Z])(\d+:\d+\s.+?\.\s)", r"\1 ", s, flags=re.DOTALL)
        s = re.sub(r'(?<=[a-zA-Z,.;:"\u201d\u2019])(\d+:\d+\s.+?\.\s)', " ", s, flags=re.DOTALL)
        if s == prev:
            break
    return re.sub(r"\s+", " ", s).strip()


def _row_fingerprint(row: dict) -> tuple[int, str]:
    return (int(row["verse"]), (row.get("text") or "").strip())


def dedupe_repeated_chapter_cycles(rows: list[dict]) -> list[dict]:
    """wldeh/bible-api en-web often repeats the entire chapter 2–3× identically; keep one copy."""
    n = len(rows)
    if n < 2:
        return rows
    keyed = [_row_fingerprint(r) for r in rows]
    for period in range(1, n // 2 + 1):
        if n % period != 0:
            continue
        head = tuple(keyed[:period])
        if all(tuple(keyed[i : i + period]) == head for i in range(period, n, period)):
            return rows[:period]
    return rows


def merge_duplicate_verse_numbers(rows: list[dict]) -> list[dict]:
    """WEB JSON repeats the same verse number for poetic lines; one row per verse."""
    merged: dict[int, str] = {}
    for row in rows:
        n = int(row["verse"])
        t = clean_verse_text(row["text"])
        if n in merged:
            merged[n] += " " + t
        else:
            merged[n] = t
    return [{"n": n, "t": merged[n]} for n in sorted(merged.keys(), key=int)]


def fetch_chapter_json(slug: str, chapter: int) -> dict:
    url = f"{BASE}/{slug}/chapters/{chapter}.json"
    req = urllib.request.Request(url, headers={"User-Agent": "BIBLE-TODO-build-script"})
    with urllib.request.urlopen(req, timeout=90) as resp:
        return json.loads(resp.read().decode("utf-8"))


def main() -> int:
    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    chapters_out: list[dict] = []

    for slug, max_ch in BOOKS:
        book_name = ""
        for ch in range(1, max_ch + 1):
            try:
                payload = fetch_chapter_json(slug, ch)
            except Exception as e:
                print(f"FAIL {slug} chapter {ch}: {e}", file=sys.stderr)
                return 1
            rows = payload.get("data") or []
            if not rows:
                print(f"EMPTY {slug} chapter {ch}", file=sys.stderr)
                return 1
            if not book_name:
                book_name = rows[0].get("book") or slug
            rows = dedupe_repeated_chapter_cycles(rows)
            verses = merge_duplicate_verse_numbers(rows)
            chapters_out.append({"book": book_name, "chapter": ch, "verses": verses})
            time.sleep(0.005)
        print(f"OK {slug} → {book_name} ({max_ch} ch)")

    doc = {
        "translationId": "WEB",
        "translationName": "World English Bible",
        "copyright": "World English Bible is Public Domain. https://worldenglish.bible/",
        "source": "https://github.com/wldeh/bible-api (en-web)",
        "chapters": chapters_out,
    }

    OUT_PATH.write_text(json.dumps(doc, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(f"Wrote {OUT_PATH} ({OUT_PATH.stat().st_size // 1024} KB)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
