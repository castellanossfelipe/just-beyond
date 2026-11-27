import json
from pathlib import Path

OUTPUT = Path(__file__).resolve().parents[2] / "App/Resources/World/coastlines.json"


def load():
    return json.loads(OUTPUT.read_text())


def points():
    return [point for line in load()["lines"] for point in line]


def test_output_is_valid_json_with_source_scale_and_lines():
    data = load()
    assert data["source"]
    assert data["scale"] == "110m"
    assert isinstance(data["lines"], list)


def test_all_coordinates_in_range():
    assert points(), "no coordinates to check"
    for lon, lat in points():
        assert -180 <= lon <= 180
        assert -90 <= lat <= 90


def test_line_count_is_plausible():
    assert 100 <= len(load()["lines"]) <= 200  # [tune]


def test_coordinates_are_rounded_to_two_decimals():
    for lon, lat in points():
        assert lon == round(lon, 2)
        assert lat == round(lat, 2)
