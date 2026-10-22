"""Incremental P6 assets from the already licensed author-supplied CC0 packs."""
from pathlib import Path
import json,hashlib
import prepare_3d as pipeline
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'art/models'
manifest_path=OUT/'manifest.json'
manifest=json.loads(manifest_path.read_text(encoding='utf-8-sig'))
new=[]
for source,name in [('Knight','guardian'),('Barbarian','captain')]:
 info=pipeline.character(source,name,True)
 if name=='captain':
  data,blob=pipeline.read(OUT/(name+'.glb'))
  pipeline.merge_clips(data,blob,pipeline.locate('kaykit-character-animations','Rig_Medium_Simulation.glb'),{'Cheering':'rally'})
  pipeline.write(OUT/(name+'.glb'),data,blob)
  info['clips']=[a['name'] for a in data['animations']]
 new.append(info)
for name in ['sword_1handed','shield_square_color','axe_1handed']:
 data,blob=pipeline.read(pipeline.locate('kaykit-adventurers',name+'.gltf'))
 pipeline.write(OUT/(name+'.glb'),data,blob)
old=[v for v in manifest.get('characters',[]) if v['file'] not in {v['file'] for v in new}]
manifest['characters']=old+new
manifest['files']={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in OUT.glob('*.glb')}
manifest_path.write_text(json.dumps(manifest,indent=2),encoding='utf-8')
print(json.dumps(new,indent=2))
