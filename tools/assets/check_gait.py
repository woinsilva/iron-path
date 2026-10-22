"""Validate calibrated stance speeds against real imported skeletal samples."""
import json,sys
from pathlib import Path
root=Path(__file__).resolve().parents[2]
profile=json.loads((root/'data/presentation/rig_gaits.json').read_text(encoding='utf-8-sig'))
for clip in ['walk','run']:
    samples=json.loads((root/'test-results'/f'gait-{clip}.json').read_text(encoding='utf-8'))
    speeds=[]
    for side in ['left','right']:
        minimum=min(sample[side][1] for sample in samples)
        for before,after in zip(samples,samples[1:]):
            if before[side][1] < minimum+0.055:
                speeds.append(-(after[side][2]-before[side][2])/(after['time']-before['time']))
    actual=sum(speeds)/len(speeds)
    expected=float(profile[f'{clip}_stance_speed'])
    if abs(actual-expected)>0.08:
        raise RuntimeError(f'{clip} stride profile no longer matches animation: measured {actual}, configured {expected}')
    print(f'PASS: {clip} stance {actual:.3f} m/s matches configured {expected:.3f} m/s')
