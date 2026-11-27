#!/usr/bin/env python3
"""Build App/Resources/World/coastlines.json from Natural Earth. Standard library only."""
import json
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
URL = ("https://raw.githubusercontent.com/nvkelso/natural-earth-vector/"
       "v5.1.2/geojson/ne_110m_coastline.geojson")
CACHE = ROOT / "tools/cache/ne_110m_coastline.geojson"
OUTPUT = ROOT / "App/Resources/World/coastlines.json"


def build(source, output):
    features = json.loads(source.read_text())["features"]
    lines = [[[round(lon, 2), round(lat, 2)] for lon, lat in feature["geometry"]["coordinates"]]
             for feature in features]
    data = {"source": "Natural Earth ne_110m_coastline v5.1.2 (public domain)",
            "scale": "110m", "lines": lines}
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(data, separators=(",", ":")) + "\n")


def main():
    if not CACHE.exists():
        CACHE.parent.mkdir(parents=True, exist_ok=True)
        urllib.request.urlretrieve(URL, CACHE)
    build(CACHE, OUTPUT)


if __name__ == "__main__":
    main()
