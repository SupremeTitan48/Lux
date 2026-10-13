"""Generates maps/evening_prayer.json.

Evening Prayer occupies extraction pages 18-23, where each PDF page carries
two book pages whose lines the extractor interleaved. The reading order below
is reconstructed editorially, following the order of the 1662 office (which
matches the order of Morning Prayer printed on pages 9-17), and every unit is
marked for review against the PDF page images. All wording is taken from the
source; fragments only select and order it.

Run: python3 maps/build_evening_prayer_map.py
"""

import json
from pathlib import Path

U = []


def unit(id, kind, fragments, **kw):
    d = {"id": id, "kind": kind, "fragments": fragments}
    d.update(kw)
    U.append(d)


def L(raw, frm=None, to=None, join=None):
    f = {"raw": raw}
    if frm is not None:
        f["from"] = frm
    if to is not None:
        f["to"] = to
    if join is not None:
        f["join"] = join
    return f


def R(a, b, join=None):
    f = {"raw": [a, b]}
    if join is not None:
        f["join"] = join
    return f


unit("ep.title", "title", [L(1268, "The O R D E R for", "for"), L(1269, "EVENING PRAYER,"), L(1270, "Daily throughout", "the Year.")])
unit("ep.sentences.rubric", "rubric", [R(1274, 1275), L(1276, "Sentences.", "Sentences.")])
unit("ep.sentence.ezek-18-27", "sentence", [L(1277, "W tified", "W"), L(1277, "H E N the wicked", join=""), L(1278, None, "Ezek. 18. 27.")], role="minister", citation="Ezek. 18. 27.", closeUp=True)
unit("ep.sentence.ps-51-3", "sentence", [R(1281, 1282)], role="minister", citation="Pſalm 51. 3.")
unit("ep.sentence.ps-51-9", "sentence", [R(1283, 1284)], role="minister", citation="Pſalm 51. 9.")
unit("ep.sentence.ps-51-17", "sentence", [R(1289, 1289)], role="minister", citation="Pſalm 51. 17.")
unit("ep.sentence.joel-2-13", "sentence", [R(1290, 1291)], role="minister", citation="Joel 2. 13.")
unit("ep.sentence.dan-9-9", "sentence", [R(1292, 1293)], role="minister", citation="Dan. 9. 9, 10.")
unit("ep.sentence.jer-10-24", "sentence", [L(1269, "O Lord, correct me", "Pſalm 6.1.")], role="minister", citation="Jer. 10. 24. Pſalm 6.1.")
unit("ep.sentence.matt-3-2", "sentence", [L(1270, "Repent ye;", "is at"), L(1270, "hand.", "S. Matt. 3.2.")], role="minister", citation="S. Matt. 3.2.")
unit("ep.sentence.luke-15-18", "sentence", [R(1271, 1273)], role="minister", citation="S. Luke 15. 18, 19.")
unit("ep.sentence.ps-143-2", "sentence", [L(1276, "Enter not", "O"), L(1277, "Lord;", "juſ"), L(1277, "tified.", "Pſalm 143. 2.", join="")], role="minister", citation="Pſalm 143. 2.")
unit("ep.sentence.1john-1-8", "sentence", [R(1279, 1280)], role="minister", citation="1 S. John 1. 8, 9.")
unit("ep.exhortation", "exhortation", [R(1285, 1288), R(1297, 1299)], role="minister", closeUp=True)
unit("ep.confession.rubric", "rubric", [R(1309, 1310)])
unit("ep.confession", "prayer", [R(1311, 1316)], role="all")
unit("ep.absolution.rubric", "rubric", [R(1300, 1300)])
unit("ep.absolution", "prayer", [R(1302, 1308)], role="priest", closeUp=True)
unit("ep.lordsprayer.rubric", "rubric", [R(1317, 1318)])
unit("ep.lordsprayer", "prayer", [L(1319, "OUR Father", "Hal"), L(1319, "lowed be", join=""), R(1320, 1322)], role="all")
unit("ep.preces.rubric", "rubric", [L(1327)])
unit("ep.preces", "versicles", [L(1328, "O Lord, open thou our lips;", "lips;"), L(1329, "Anſw. And our mouth", "praiſe."), R(1332, 1333)], speaker="priest")
unit("ep.gloria.rubric", "rubric", [L(1334, "¶ Here all standing up", "ſhall ſay,")])
unit("ep.gloria", "versicles", [L(1335), L(1337, "Anſw. As it was", "is now, and"), L(1338, "ever ſhall be:", "Amen."), L(1338, "Priest. Praiſe ye the Lord.", "Lord."), L(1339, "Anſw. The Lord’s Name", "praiſed.")], speaker="priest")
unit("ep.psalms-lesson.rubric", "rubric", [L(1340, "¶ Then ſhall be ſaid or ſung the Pſalms"), L(1341, "as followeth.", "as followeth.")])
unit("ep.magnificat.title", "heading", [L(1341, "Magnificat", "LUKE 1. 46")], latin="Magnificat", reference="Luke 1:46")
unit("ep.magnificat", "canticle", [
    L(1341, "M the nations", "M"), L(1341, "Y ſoul doth magnify", "my Saviour.", join=""),
    L(1341, "For he hath regarded:", "of his"), L(1342, None, "hand-maiden.", join=" "),
    L(1343, "For, behold,", "genera"), L(1343, "tions ſhall call me bleſſed.", "bleſſed.", join=""),
    L(1343, "For he that is mighty", "his name."),
    L(1344, "And his mercy is on them", "generations."),
    L(1345, "He hath ſhowed strength", "imagination of"), L(1346, join=" "),
    L(1325),
    L(1328, "He hath filled the hungry", "good things:"), L(1329, "and the rich", "empty away.", join=" "),
    L(1329, "He remembering of his mercy", "holpen"), L(1330, join=" "), L(1331, join=" "),
    L(1334, "Glory be to the Father and to the Son: and", "Son: and"), L(1336, "to the Holy Ghost;", "Ghost;", join=" "),
    L(1336, "As it was in the beginning, is now, and ever", "and ever"), L(1337, "ſhall be: world without end. Amen.", "Amen.", join=" "),
])
unit("ep.cantate.rubric", "rubric", [L(1338, "¶ Or elſe this Pſalm: Except it be on the nineteenth", "month,"), L(1338, "when it is read", "courſe of Pſalms.")])
unit("ep.cantate.title", "heading", [L(1339, "Cantate Domino.", "PſAL. 98.")], latin="Cantate Domino.", reference="Psalm 98")
unit("ep.cantate", "canticle", [
    L(1340, "OSing unto the Lord", "marvellous things."),
    L(1341, "With his own right hand", "the victory."),
    L(1341, "The Lord declared his ſalvation:", "in the ſight of"), L(1341, "the nations.", "the nations.", join=" "),
    L(1342, "He hath remembered his mercy", "all the ends of"), L(1343, "the world have ſeen", "of our God.", join=" "),
    L(1343, "Shew yourſelves joyful", "give thanks."),
    L(1343, "Praiſe the Lord upon the harp:", "ſing to the"), L(1344, "harp with a pſalm", "thankſgiving.", join=" "),
    L(1344, "With trumpets alſo", "O ſhew"), L(1345, "yourſelves joyful", "the King.", join=" "),
    R(1349, 1350),
    R(1353, 1354),
    R(1360, 1361, join=" "),
    R(1362, 1363),
    L(1366),
], replace=[["OSing", "O Sing"]])
# R(1360,1361) is joined as a verse break below: see fix_verse_joins.
unit("ep.nt-lesson.rubric", "rubric", [L(1369, "¶ Then a Leſſon of the New Testament", "And after"), L(1370)])
unit("ep.nuncdimittis.title", "heading", [L(1374, "Nunc dimittis", "2.29")], latin="Nunc dimittis", reference="Luke 2:29")
unit("ep.nuncdimittis", "canticle", [
    L(1374, "LO R D , now lettest", "thy Word."),
    L(1375), L(1378, "or mine eyes have ſeen:", "thy ſalvation,", join=""),
    L(1378, "Which thou hast", "Which thou hast"), L(1378, "prepared:", "all peoples;", join=" "),
    L(1379, "To be a light", "Iſrael."),
    R(1380, 1381), L(1386),
], closeUp=True)
unit("ep.deus.rubric", "rubric", [L(1388)])
unit("ep.deus.title", "heading", [L(1389)], latin="Deus miſereatur.", reference="Psalm 67")
unit("ep.deus", "canticle", [
    L(1390), L(1391, join=" "),
    L(1351),
    R(1355, 1356),
    L(1357), L(1358, join=" "), L(1359, join=" "),
    R(1364, 1365),
    L(1368), L(1369, "and God, even our own God", "his bleſſing.", join=" "),
    R(1371, 1372),
    R(1373, 1373), L(1374, "to the Holy Ghost;", "Ghost;", join=" "),
    L(1376),
], closeUp=True)
unit("ep.creed.rubric", "rubric", [L(1378, "¶ Then ſhall be ſaid or ſung the Apostles Creed", "Minister and the"), L(1378, "people standing.", "standing.")])
unit("ep.creed", "creed", [L(1379, "IBelieve", "heaven and earth:"), R(1382, 1385), L(1394, "I believe in the Holy Ghost;", "The holy Ca"), L(1395, join=""), L(1396)], role="all", replace=[["IBelieve", "I Believe"]])
unit("ep.prayers.rubric", "rubric", [R(1402, 1403)])
unit("ep.salutation", "versicles", [R(1406, 1407)], speaker="minister")
unit("ep.letuspray.rubric", "rubric", [L(1408, "¶ Mini", "Mini"), L(1408, "ster.", "ster.", join="")])
unit("ep.letuspray", "versicles", [L(1409, "Let us pray.", "pray.")], speaker="minister")
unit("ep.kyrie", "lines", [L(1412), L(1413), L(1414)])
unit("ep.lordsprayer2.rubric", "rubric", [L(1415, "¶ Then the Minister, Clerks", "Lord’s Prayer"), L(1416, "with a loud voice.", "voice.")])
unit("ep.lordsprayer2", "prayer", [L(1421, "OU R Father", "Hal"), L(1421, "lowed be", join=""), R(1422, 1423)], role="all", closeUp=True)
unit("ep.suffrages.rubric", "rubric", [L(1424)])
unit("ep.suffrages", "versicles", [
    L(1425, "O Lord, ſhow thy mercy upon us;", "upon us;"), L(1426, "Anſw. And grant us", "ſalvation."),
    R(1429, 1431), L(1432),
    L(1394, "Anſw. And make thy choſen", "joyful."),
    R(1397, 1401),
    L(1404), L(1405),
    L(1408, "Anſw. And take not", "from us."),
], speaker="priest")
unit("ep.collects.rubric", "rubric", [L(1409, "¶ Then ſhall follow three Collects", "ſecond for"), L(1410), L(1411)])
unit("ep.collect.peace.title", "heading", [L(1415, "¶ The Second Collect at Evening Prayer.", "Evening Prayer.")])
unit("ep.collect.peace", "prayer", [L(1416, "OGod, from whom"), R(1417, 1420)], role="minister", replace=[["OGod", "O God"]])
unit("ep.collect.aid.title", "heading", [L(1425, "¶ The Third Collect", "Perils.")])
unit("ep.collect.aid", "prayer", [L(1426, "LI G H T E N our darkneſs"), R(1427, 1428)], role="minister", closeUp=True)
unit("ep.anthem.rubric", "rubric", [L(1435, "¶ In Quires", "the Anthem.")])
unit("ep.prayer.king.title", "heading", [L(1439)])
unit("ep.prayer.king", "prayer", [R(1440, 1445)], role="minister", replace=[["OLord", "O Lord"]])
unit("ep.prayer.royalfamily.title", "heading", [L(1451)])
unit("ep.prayer.royalfamily", "prayer", [R(1452, 1455)], role="minister")
unit("ep.prayer.clergy.title", "heading", [L(1435, "¶ A Prayer for the Clergy", "People.")])
unit("ep.prayer.clergy", "prayer", [R(1436, 1438)], role="minister", closeUp=True)
unit("ep.prayer.chrysostom.title", "heading", [L(1446)])
unit("ep.prayer.chrysostom", "prayer", [R(1447, 1450)], role="minister")
unit("ep.grace.reference", "heading", [L(1456)], reference="2 Corinthians 13:14")
unit("ep.grace", "prayer", [R(1457, 1458)], role="minister", closeUp=True)
unit("ep.colophon", "colophon", [L(1459)])

IGNORE = [
    {"raw": 1268, "text": "EVENING PRAYER.", "reason": "running head of the facing book page"},
    {"raw": 1277, "text": "-", "reason": "line-end hyphen of the printed page (juſ-tified)"},
    {"raw": 1319, "text": "-", "reason": "line-end hyphen of the printed page (Hal-lowed)"},
    {"raw": 1343, "text": "-", "reason": "line-end hyphen of the printed page (genera-tions)"},
    {"raw": 1394, "text": "-", "reason": "line-end hyphen of the printed page (Ca-tholick)"},
    {"raw": 1421, "text": "-", "reason": "line-end hyphen of the printed page (Hal-lowed)"},
]

# Verses that continue across interleaved lines are joined with a space; the
# Cantate verse "With righteousneſs..." is a new verse.
for u in U:
    if u["id"] == "ep.cantate":
        for f in u["fragments"]:
            if f.get("raw") == [1360, 1361]:
                f.pop("join")

spec = {
    "schemaVersion": 1,
    "id": "evening-prayer",
    "title": "The Order for Evening Prayer, Daily throughout the Year.",
    "section": {"start": "The O R D E R for EVENING PRAYER.", "end": "Here endeth the Order of Evening Prayer throughout the Year."},
    "readingOrder": "reconstructed",
    "units": U,
    "ignore": IGNORE,
}
out = Path(__file__).resolve().parent / "evening_prayer.json"
out.write_text(json.dumps(spec, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
