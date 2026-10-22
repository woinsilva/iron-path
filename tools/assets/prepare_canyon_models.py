"""P7 incremental CC0 Mage rig and staff from cached author packs."""
from pathlib import Path
import json,hashlib
import prepare_3d as pipeline
root=Path(__file__).resolve().parents[2]
out=root/'art/models'
info=pipeline.character('Mage','shaman',True)
for name in ['staff','shield_round_color']:
 data,blob=pipeline.read(pipeline.locate('kaykit-adventurers',name+'.gltf'))
 pipeline.write(out/(name+'.glb'),data,blob)
p=out/'manifest.json'
manifest=json.loads(p.read_text(encoding='utf-8-sig'))
manifest['characters']=[c for c in manifest['characters'] if c['file']!=info['file']]+[info]
manifest['files']={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in out.glob('*.glb')}
p.write_text(json.dumps(manifest,indent=2),encoding='utf-8')
print(json.dumps(info))
