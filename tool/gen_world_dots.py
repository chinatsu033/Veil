import json, base64
from shapely.geometry import shape, Point
from shapely.prepared import prep
d = json.load(open('/workspace/tools/ne_50m.geojson'))
polys = []
for f in d['features']:
    p = f['properties']
    code = p.get('ISO_A2_EH') or p.get('ISO_A2')
    if not code or code == '-99':
        code = p.get('ISO_A2')
    if not code or code == '-99':
        continue
    if code == 'AQ':
        continue
    g = shape(f['geometry'])
    polys.append((code, prep(g), g.bounds, g))
STEP = 2.0
LON0, LAT0 = -180.0, 82.0
COLS, ROWS = 180, 69
codes = []
out = bytearray()
count = 0
for r in range(ROWS):
    lat = LAT0 - r * STEP
    for c in range(COLS):
        lon = LON0 + c * STEP + (STEP / 2 if r % 2 else 0) + STEP / 4
        pt = Point(lon, lat)
        hit = None
        for code, pg, b, g in polys:
            if b[0] - 0.8 <= lon <= b[2] + 0.8 and b[1] - 0.8 <= lat <= b[3] + 0.8:
                if pg.contains(pt) or g.distance(pt) < 0.45:
                    hit = code
                    break
        if hit:
            if hit not in codes:
                codes.append(hit)
            out += bytes([c, r, codes.index(hit)])
            count += 1
print(count, len(codes))
b64 = base64.b64encode(bytes(out)).decode()
lines = [b64[i:i+76] for i in range(0, len(b64), 76)]
with open('/workspace/veil/lib/glass/world_dots.dart', 'w') as f:
    f.write('// Generated from Natural Earth 1:50m admin-0 (public domain) by tool/gen_world_dots.py.\n')
    f.write('// Each dot is 3 bytes: column, row, index into worldDotCodes.\n\n')
    f.write(f'const worldDotStep = {STEP};\nconst worldDotLon0 = {LON0};\nconst worldDotLat0 = {LAT0};\n')
    f.write(f'const worldDotCols = {COLS};\nconst worldDotRows = {ROWS};\n\n')
    f.write('const worldDotCodes = <String>[\n')
    for i in range(0, len(codes), 12):
        f.write('  ' + ', '.join(f"'{x}'" for x in codes[i:i+12]) + ',\n')
    f.write('];\n\n')
    f.write('const worldDotData =\n')
    for i, l in enumerate(lines):
        f.write(f"    '{l}'" + (';\n' if i == len(lines) - 1 else '\n'))
