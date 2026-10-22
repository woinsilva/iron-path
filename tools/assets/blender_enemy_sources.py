"""Blender source checkpoints for the P6 rigged characters."""
import bpy
from pathlib import Path
root=Path(__file__).resolve().parents[2]
for name in ['guardian','captain','shaman']:
 bpy.ops.wm.read_factory_settings(use_empty=True)
 bpy.ops.import_scene.gltf(filepath=str(root/'art/models'/f'{name}.glb'))
 rigs=[o for o in bpy.data.objects if o.type=='ARMATURE']
 assert len(rigs)==1 and len(rigs[0].data.bones)==23
 bpy.ops.wm.save_as_mainfile(filepath=str(root/'source_assets'/f'{name}_pipeline.blend'))
 print('P6_SOURCE_OK',name,len(rigs[0].data.bones),[a.name for a in bpy.data.actions])
