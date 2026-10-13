"""Generates maps/collects.json: the observances of the Collects, Epistles and
Gospels, in the order printed, with the raw line of each collect heading.

Run: python3 maps/build_collects_catalogue.py
"""

import json
from pathlib import Path

ORDER = [
    ("advent-1", 2863), ("advent-2", 3004), ("advent-3", 3114), ("advent-4", 3216),
    ("christmas", 3305, (3302, 3303)), ("stephen", 3410), ("john-evangelist", 3517), ("innocents", 3639),
    ("christmas-1", 3712), ("circumcision", 3803), ("epiphany", 3917, (3914, 3916)),
    ("epiphany-1", 4050), ("epiphany-2", 4160), ("epiphany-3", 4264), ("epiphany-4", 4377),
    ("epiphany-5", 4513), ("epiphany-6", 4593),
    ("septuagesima", 4732, (4729, 4731)), ("sexagesima", 4843, (4840, 4842)), ("quinquagesima", 4977, (4974, 4976)),
    ("ash-wednesday", 5124, (5120, 5122)),
    ("lent-1", 5227), ("lent-2", 5349), ("lent-3", 5449), ("lent-4", 5609), ("lent-5", 5744),
    ("palm-sunday", 5862), ("good-friday", 7521, None, 3), ("easter-even", 7899), ("easter", 8065, (8022, 8022)),
    ("easter-monday", 8172), ("easter-tuesday", 8357),
    ("easter-1", 8526), ("easter-2", 8625), ("easter-3", 8722), ("easter-4", 8863), ("easter-5", 8971),
    ("ascension", 9074), ("ascension-sunday", 9207), ("whitsunday", 9284), ("whit-monday", 9408), ("whit-tuesday", 9518),
    ("trinity", 9592),
    ("trinity-1", 9771), ("trinity-2", 9900), ("trinity-3", 10001), ("trinity-4", 10103), ("trinity-5", 10208),
    ("trinity-6", 10309), ("trinity-7", 10439), ("trinity-8", 10543), ("trinity-9", 10597), ("trinity-10", 10743),
    ("trinity-11", 10833), ("trinity-12", 10935), ("trinity-13", 11032), ("trinity-14", 11174), ("trinity-15", 11273),
    ("trinity-16", 11392), ("trinity-17", 11466), ("trinity-18", 11552), ("trinity-19", 11635), ("trinity-20", 11752),
    ("trinity-21", 11849), ("trinity-22", 11971, (11970, 11970)), ("trinity-23", 12091), ("trinity-24", 12179, (12178, 12178)),
    ("trinity-25", 12287),
    ("andrew", 12398), ("thomas", 12507), ("conversion-of-paul", 12605), ("purification", 12804, (12801, 12803)),
    ("matthias", 12970), ("annunciation", 13092, (13091, 13091)), ("mark", 13219), ("philip-and-james", 13334),
    ("barnabas", 13471), ("john-baptist", 13549), ("peter", 13732), ("james", 13862), ("bartholomew", 13967),
    ("matthew", 14042), ("michael", 14138), ("luke", 14241), ("simon-and-jude", 14347), ("all-saints", 14468),
]

observances = []
for row in ORDER:
    entry = {"id": row[0], "heading": row[1]}
    if len(row) > 2 and row[2]:
        entry["titleRaw"] = list(row[2])
    if len(row) > 3:
        entry["collects"] = row[3]
    observances.append(entry)

spec = {
    "schemaVersion": 1,
    "section": {"firstRaw": 2855, "lastRaw": 14630},
    "extraDropcapSites": [8024, 8031, 8045],
    "observances": observances,
    # Rubrics printed after an observance's Gospel that govern the collect,
    # and the general note at the head of the section.
    "notes": [{"id": "eve-rule", "raw": 2859}],
    "trailingRubrics": [{"observance": "circumcision", "raw": 3912}, {"observance": "trinity-25", "raw": 12391}],
}
out = Path(__file__).resolve().parent / "collects.json"
out.write_text(json.dumps(spec, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
