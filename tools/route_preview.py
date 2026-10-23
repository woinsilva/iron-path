"""Top-down preview of a stage layout for map design: roads, air route, river, build spots and the HUD
areas the camera covers. Optionally suggests build spots with the most road inside tower range.

    python tools/route_preview.py data/campaign/stage_02.json out.png [--suggest 9]

Curves follow StageSessionV2.curve_from_points (cubic Bezier, handles 0.17 x neighbour span)."""
from pathlib import Path
import json, math, sys
from PIL import Image, ImageDraw

SCALE = 22  # pixels per metre
X0, X1, Z0, Z1 = -24.0, 24.0, -14.0, 14.0
CLEARANCE = 1.9
RIVERS = {3: (0.0, 2.2), 5: (0.0, 2.2), 8: (0.0, 2.2), 6: (-20.3, 3.0), 7: (-20.3, 3.0)}


def bezier(points):
    """Baked polyline (about 0.12 m steps) of the curve through the control points."""
    pts = [(float(p[0]), float(p[2])) for p in points]
    out = []
    for i in range(len(pts) - 1):
        prev, nxt = pts[max(i - 1, 0)], pts[min(i + 1, len(pts) - 1)]
        prev2, nxt2 = pts[i], pts[min(i + 2, len(pts) - 1)]
        t0 = ((nxt[0] - prev[0]) * 0.17, (nxt[1] - prev[1]) * 0.17)
        t1 = ((nxt2[0] - prev2[0]) * 0.17, (nxt2[1] - prev2[1]) * 0.17)
        a, d = pts[i], pts[i + 1]
        b = (a[0] + t0[0], a[1] + t0[1])
        c = (d[0] - t1[0], d[1] - t1[1])
        steps = max(4, int(math.dist(a, d) / 0.12))
        for s in range(steps):
            t = s / steps
            u = 1 - t
            out.append((u**3 * a[0] + 3 * u * u * t * b[0] + 3 * u * t * t * c[0] + t**3 * d[0],
                        u**3 * a[1] + 3 * u * u * t * b[1] + 3 * u * t * t * c[1] + t**3 * d[1]))
    out.append(pts[-1])
    return out


def length(line):
    return sum(math.dist(line[i], line[i + 1]) for i in range(len(line) - 1))


def nearest(line, point):
    return min(math.dist(p, point) for p in line)


def px(x, z):
    return ((x - X0) * SCALE, (z - Z0) * SCALE)


def main():
    stage = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8-sig"))
    target = sys.argv[2]
    global CLEARANCE
    CLEARANCE = float(sys.argv[sys.argv.index("--clearance") + 1]) if "--clearance" in sys.argv else 1.9
    suggest = int(sys.argv[sys.argv.index("--suggest") + 1]) if "--suggest" in sys.argv else 0
    grounds = [bezier(stage["route_points"])] + [bezier(r) for r in stage.get("extra_route_points", [])]
    air = bezier(stage["air_route_points"]) if "air_route_points" in stage else None
    river = tuple(stage["river"]) if "river" in stage else RIVERS.get(int(stage.get("index", 0)), (19.3, 3.0))
    bounds = stage.get("bounds", [-20.0, 20.0, -11.0, 11.0])
    blocked = [tuple(z) for z in stage.get("blocked_zones", [])] or [(river[0] - river[1] / 2 - 0.7, -16, river[1] + 1.4, 32)]
    image = Image.new("RGB", (int((X1 - X0) * SCALE), int((Z1 - Z0) * SCALE)), (120, 150, 90))
    draw = ImageDraw.Draw(image)
    for x in range(int(X0), int(X1) + 1, 2):
        draw.line([px(x, Z0), px(x, Z1)], fill=(110, 138, 84))
    for z in range(int(Z0), int(Z1) + 1, 2):
        draw.line([px(X0, z), px(X1, z)], fill=(110, 138, 84))
    draw.rectangle([px(river[0] - river[1] / 2, Z0), px(river[0] + river[1] / 2, Z1)], fill=(60, 130, 150))
    for zone in blocked:
        draw.rectangle([px(zone[0], zone[1]), px(zone[0] + zone[2], zone[1] + zone[3])], outline=(200, 60, 60))
    draw.rectangle([px(bounds[0], bounds[2]), px(bounds[1], bounds[3])], outline=(255, 255, 255))
    # Approximate HUD: header top-left, controls top-right, cards bottom centre (16:9 view).
    for box in [(-22, -14, -9, -9.6), (12, -14, 22, -11), (-17.5, 10.6, 15, 14)]:
        draw.rectangle([px(box[0], box[1]), px(box[2], box[3])], outline=(40, 40, 40), width=2)
    for line in grounds:
        for p in line[::2]:
            draw.ellipse([px(p[0] - 1.05, p[1] - 1.05), px(p[0] + 1.05, p[1] + 1.05)], fill=(214, 186, 130))
    for index, line in enumerate(grounds):
        draw.text(px(*line[0]), "IN%d" % index, fill=(0, 0, 0))
        draw.text(px(*line[-1]), "OUT", fill=(160, 0, 0))
    if air:
        draw.line([px(*p) for p in air], fill=(240, 240, 255), width=2)

    def buildable(point, chosen):
        if not (bounds[0] <= point[0] <= bounds[1] and bounds[2] <= point[1] <= bounds[3]):
            return False
        if any(z[0] <= point[0] <= z[0] + z[2] and z[1] <= point[1] <= z[1] + z[3] for z in blocked):
            return False
        if any(nearest(line, point) < CLEARANCE for line in grounds):
            return False
        return all(math.dist(point, c) >= 3.2 for c in chosen)

    def coverage(point, radius=4.2):
        metres = 0.0
        for line in grounds:
            metres += sum(0.12 for p in line if math.dist(p, point) <= radius)
        return metres

    pads = [(float(p[0]), float(p[2])) for p in stage.get("pads", [])]
    report = []
    for index, pad in enumerate(pads):
        ok = buildable(pad, [])
        cov = coverage(pad)
        aircov = sum(0.12 for p in (air or []) if math.dist(p, pad) <= 4.9)
        report.append("pad %d %s road %.1fm air %.1fm%s" % (index, pad, cov, aircov, "" if ok else "  NOT BUILDABLE"))
        draw.ellipse([px(pad[0] - 1, pad[1] - 1), px(pad[0] + 1, pad[1] + 1)], outline=(255, 255, 255) if ok else (255, 0, 0), width=3)
        draw.text(px(pad[0] - 0.3, pad[1] - 0.4), str(index), fill=(255, 255, 255))
    if suggest:
        candidates = []
        z = bounds[2]
        while z <= bounds[3]:
            x = bounds[0]
            while x <= bounds[1]:
                if buildable((x, z), []):
                    candidates.append((coverage((x, z)), (x, z)))
                x += 0.5
            z += 0.5
        candidates.sort(reverse=True)
        chosen = []
        for cov, point in candidates:
            if len(chosen) >= suggest:
                break
            if buildable(point, chosen):
                chosen.append(point)
                report.append("suggest %s road %.1fm" % (point, cov))
                draw.rectangle([px(point[0] - 0.5, point[1] - 0.5), px(point[0] + 0.5, point[1] + 0.5)], outline=(255, 255, 0), width=2)
    report.append("road lengths: " + ", ".join("%.1f" % length(line) for line in grounds))
    image.save(target)
    print("\n".join(report))


if __name__ == "__main__":
    main()
