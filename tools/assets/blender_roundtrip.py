"""Run with Blender --background --python tools/assets/blender_roundtrip.py."""
import bpy
from pathlib import Path
root=Path(__file__).resolve().parents[2]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(root/'art/models/goblin.glb'))
armatures=[obj for obj in bpy.data.objects if obj.type=='ARMATURE']
assert len(armatures)==1
assert len(armatures[0].data.bones)==23
names=[action.name for action in bpy.data.actions]
assert any('walk' in name for name in names),names
bpy.ops.wm.save_as_mainfile(filepath=str(root/'source_assets/goblin_pipeline.blend'))
bpy.ops.export_scene.gltf(filepath=str(root/'test-results/goblin_roundtrip.glb'),export_format='GLB',export_animations=True,export_animation_mode='ACTIONS')
print('ROUNDTRIP_OK',len(armatures[0].data.bones),'bones',names)
