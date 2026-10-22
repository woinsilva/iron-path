"""Threat curve of every campaign wave. Fails when a wave is weaker than the one before it.

python tools/wave_curve.py            -> report and exit 1 on any drop or flat step
python tools/wave_curve.py --apply [stage_07] [--scale=0.95]
    -> one-time reshaping of authored waves onto a rising curve (run on the authored files, not twice)
Weights live in data/campaign/wave_curve.json.
"""
from pathlib import Path
import json, math, sys

ROOT = Path(__file__).resolve().parents[1]
CAMPAIGN = ROOT / "data" / "campaign"


def load(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


CURVE = load(CAMPAIGN / "wave_curve.json")
MAX_SHIFT = int(CURVE["max_shift"])
SCALE = next((float(argument.split("=", 1)[1]) for argument in sys.argv if argument.startswith("--scale=")), 1.0)
ENEMIES = load(CAMPAIGN / "core.json")["enemies"]


def enemy_threat(enemy_id: str) -> float:
    enemy = ENEMIES[enemy_id]
    health = float(enemy["hp"]) * (1 + float(enemy.get("armor", 0)) / CURVE["armor_divisor"])
    health /= 1 - CURVE["magic_resistance_weight"] * float(enemy.get("magic_resistance", 0))
    shield = enemy.get("shield") or {}
    health += float(shield.get("amount", 0)) * (1 + CURVE["shield_recharge_weight"] * float(shield.get("recharges", 0)))
    if "support" in enemy or "ability" in enemy:
        health *= CURVE["support_multiplier"]
    if enemy.get("layer") == "air":
        health *= CURVE["air_multiplier"]
    return health * (float(enemy["speed"]) / CURVE["reference_speed"]) ** CURVE["speed_exponent"]


def group_threat(group: dict) -> float:
    spacing = max(0.1, float(group.get("interval", CURVE["reference_interval"])))
    density = (CURVE["reference_interval"] / spacing) ** CURVE["density_exponent"]
    density = min(CURVE["density_max"], max(CURVE["density_min"], density))
    return enemy_threat(group["enemy"]) * int(group["count"]) * density


def wave_threat(wave: dict) -> float:
    return sum(group_threat(group) for group in wave["groups"])


def stage_paths() -> list[Path]:
    return sorted(CAMPAIGN.glob("stage_[0-9][0-9].json"))


def problems(waves: list[dict]) -> list[tuple[int, float, float]]:
    found = []
    for index in range(1, len(waves)):
        before, after = wave_threat(waves[index - 1]), wave_threat(waves[index])
        if after < before * (1 + CURVE["minimum_growth"]) - 1e-6:
            found.append((index + 1, before, after))
    return found


def isotonic(values: list[float]) -> list[float]:
    """Pool-adjacent-violators: the closest non-decreasing curve, keeping each pooled block's total."""
    blocks: list[list[float]] = []
    for value in values:
        blocks.append([value, 1])
        while len(blocks) > 1 and blocks[-2][0] / blocks[-2][1] > blocks[-1][0] / blocks[-1][1]:
            total, size = blocks.pop()
            blocks[-1][0] += total
            blocks[-1][1] += size
    curve: list[float] = []
    for total, size in blocks:
        curve.extend([total / size] * int(size))
    return curve


def _rescale(original: list[dict], targets: list[float]) -> list[dict]:
    waves = json.loads(json.dumps(original))
    for index, wave in enumerate(waves):
        factor = targets[index] / wave_threat(wave)
        for group in wave["groups"]:
            group["count"] = max(1, round(int(group["count"]) * factor))
        floor = wave_threat(waves[index - 1]) * (1 + CURVE["minimum_growth"]) if index else 0.0
        while wave_threat(wave) < floor - 1e-6:
            # Grow the cheapest group first so the step stays small and readable.
            cheapest = min(wave["groups"], key=lambda group: enemy_threat(group["enemy"]))
            cheapest["count"] = int(cheapest["count"]) + 1
    return waves


def apply(stage: dict) -> None:
    """Keep the authored order and composition; rescale group counts onto a rising curve."""
    original = stage["waves"]
    # First swap neighbouring wave contents (each moves at most MAX_SHIFT places). A wave never moves ahead of
    # the debut of any enemy it contains, so new types and flyers arrive exactly when authored and forecast;
    # ids and break intervals stay with their position.
    contents = [(index, wave["groups"]) for index, wave in enumerate(original)]
    changed = True
    while changed:
        changed = False
        for index in range(len(contents) - 1):
            (first_origin, first), (second_origin, second) = contents[index], contents[index + 1]
            seen = {group["enemy"] for _origin, groups in contents[:index] for group in groups}
            debuts_earlier = any(group["enemy"] not in seen for group in second)
            if not debuts_earlier and wave_threat({"groups": first}) > wave_threat({"groups": second}) and abs(index + 1 - first_origin) <= MAX_SHIFT and abs(index - second_origin) <= MAX_SHIFT:
                contents[index], contents[index + 1] = contents[index + 1], contents[index]
                changed = True
    for wave, (_origin, groups) in zip(original, contents):
        wave["groups"] = groups
    authored = [wave_threat(wave) for wave in original]
    # Every dip is lifted to the running peak, then the whole curve is scaled back to the authored total:
    # early waves get slightly easier, breathers disappear and the boss stays the peak.
    curve = list(authored)
    for index in range(1, len(curve)):
        curve[index] = max(curve[index], curve[index - 1] * (1 + CURVE["minimum_growth"]))
    # The rising curve keeps the stage's authored total threat, so overall difficulty stays where it was tested;
    # --scale trims a stage whose reference defenses needed a gentler curve after the reshaping.
    budget = sum(authored) * SCALE
    scale = budget / sum(curve)
    waves = original
    for _attempt in range(8):
        waves = _rescale(original, [value * scale for value in curve])
        scale *= budget / sum(wave_threat(wave) for wave in waves)
    stage["waves"] = waves


def main() -> int:
    applying = "--apply" in sys.argv
    only = [argument for argument in sys.argv[1:] if argument.startswith("stage_")]
    failed = False
    for path in stage_paths():
        if only and path.stem not in only: continue
        stage = load(path)
        if applying:
            apply(stage)
            path.write_text(json.dumps(stage, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        values = [wave_threat(wave) for wave in stage["waves"]]
        issues = problems(stage["waves"])
        failed = failed or bool(issues)
        curve = " ".join(str(round(value)) for value in values)
        print(("FAIL " if issues else "PASS ") + f"{stage['id']}: {len(values)} ondas, ameaça {round(values[0])} -> {round(values[-1])}")
        print("  curva: " + curve)
        for wave, before, after in issues:
            print(f"  onda {wave}: {round(after)} depois de {round(before)}")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
