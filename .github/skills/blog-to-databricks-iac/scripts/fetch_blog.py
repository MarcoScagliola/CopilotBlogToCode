
#!/usr/bin/env python3

import json
import re
import sys
from html import unescape
from html.parser import HTMLParser
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


class ArticleParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.in_title = False
        self.in_h1 = False
        self.in_h2 = False
        self.in_h3 = False
        self.in_p = False
        self.in_code = False
        self.title = ""
        self.headings = []
        self.paragraphs = []
        self.code_blocks = []
        self._buf = []
        self.meta_description = ""

    def handle_starttag(self, tag, attrs):
        attrs_dict = dict(attrs)

        if tag == "title":
            self.in_title = True
            self._buf = []
        elif tag == "h1":
            self.in_h1 = True
            self._buf = []
        elif tag == "h2":
            self.in_h2 = True
            self._buf = []
        elif tag == "h3":
            self.in_h3 = True
            self._buf = []
        elif tag == "p":
            self.in_p = True
            self._buf = []
        elif tag in ("pre", "code"):
            self.in_code = True
            self._buf = []

        if tag == "meta" and attrs_dict.get("name", "").lower() == "description":
            self.meta_description = attrs_dict.get("content", "")

    def handle_endtag(self, tag):
        text = clean_text("".join(self._buf))
        if tag == "title" and self.in_title:
            self.title = text
            self.in_title = False
        elif tag == "h1" and self.in_h1:
            if text:
                self.headings.append({"level": 1, "text": text})
            self.in_h1 = False
        elif tag == "h2" and self.in_h2:
            if text:
                self.headings.append({"level": 2, "text": text})
            self.in_h2 = False
        elif tag == "h3" and self.in_h3:
            if text:
                self.headings.append({"level": 3, "text": text})
            self.in_h3 = False
        elif tag == "p" and self.in_p:
            if text:
                self.paragraphs.append(text)
            self.in_p = False
        elif tag in ("pre", "code") and self.in_code:
            if text:
                self.code_blocks.append(text)
            self.in_code = False

        if tag in {"title", "h1", "h2", "h3", "p", "pre", "code"}:
            self._buf = []

    def handle_data(self, data):
        if any([self.in_title, self.in_h1, self.in_h2, self.in_h3, self.in_p, self.in_code]):
            self._buf.append(data)


def clean_text(text: str) -> str:
    text = unescape(text)
    text = re.sub(r"\s+", " ", text)
    return text.strip()


def _error(code: str, reason: str, details: str = "") -> dict:
    err = {"error": True, "code": code, "reason": reason}
    if details:
        err["details"] = details
    return err


def fetch_html(url: str) -> str:
    req = Request(
        url,
        headers={
            "User-Agent": "Mozilla/5.0 (compatible; CopilotSkillFetcher/1.0)"
        },
    )
    try:
        with urlopen(req, timeout=30) as response:
            charset = response.headers.get_content_charset() or "utf-8"
            return response.read().decode(charset, errors="replace")
    except HTTPError as e:
        raise SystemExit(
            json.dumps(_error(f"HTTP_{e.code}", e.reason, f"URL returned HTTP {e.code}"))
        )
    except URLError as e:
        raise SystemExit(
            json.dumps(_error("URL_ERROR", str(e.reason), "Could not reach the URL — check network or DNS"))
        )
    except TimeoutError:
        raise SystemExit(
            json.dumps(_error("TIMEOUT", "Request timed out after 30 seconds"))
        )


def infer_cloud(text: str) -> str:
    t = text.lower()
    if "aws" in t or "s3" in t or "iam" in t or "vpc" in t:
        return "aws"
    if "azure" in t or "adls" in t or "vnet" in t or "entra" in t:
        return "azure"
    if "gcp" in t or "gcs" in t or "google cloud" in t:
        return "gcp"
    return "unknown"


def main():
    if len(sys.argv) != 2:
        print(json.dumps(_error("USAGE", "Expected exactly one argument", "usage: fetch_blog.py <url>")))
        sys.exit(1)

    url = sys.argv[1]

    if not url.startswith(("http://", "https://")):
        print(json.dumps(_error("INVALID_URL", "URL must start with http:// or https://", f"Got: {url}")))
        sys.exit(1)

    html = fetch_html(url)

    try:
        parser = ArticleParser()
        parser.feed(html)
    except Exception as e:
        print(json.dumps(_error("PARSE_ERROR", "Failed to parse HTML", str(e))))
        sys.exit(1)

    if not parser.paragraphs and not parser.headings:
        print(json.dumps(_error("EMPTY_CONTENT", "No paragraphs or headings found", "The page may require JavaScript or returned empty HTML")))
        sys.exit(1)

    joined = " ".join(
        [parser.title, parser.meta_description]
        + [h["text"] for h in parser.headings]
        + parser.paragraphs[:40]
        + parser.code_blocks[:20]
    )

    result = {
        "url": url,
        "title": parser.title,
        "meta_description": parser.meta_description,
        "headings": parser.headings[:50],
        "paragraphs": parser.paragraphs[:80],
        "code_blocks": parser.code_blocks[:50],
        "cloud_hint": infer_cloud(joined),
    }

    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()