"""Renders CC0 Poly Haven models into camera-matched sprites for the fixed orthographic game camera.

Run with the portable Blender:
  blender -b -P tools/assets/render_sprites.py -- <slug> [<slug> ...]

For each model it writes art/sprites3d/<slug>.png (the model seen exactly from the game camera angle),
art/sprites3d/<slug>_shadow.png (its ground shadow seen from above) and <slug>.json with the sizes needed
to place both in Godot. Heavy source meshes (up to 1.6 M triangles) never enter the game this way.
"""
import bpy, json, math, sys
from mathutils import Vector, Matrix
from pathlib import Path
from bpy_extras.object_utils import world_to_camera_view

CACHE = Path('C:/Dev/Tools/AssetCache/polyhaven')
OUT = Path(__file__).resolve().parents[2] / 'art' / 'sprites3d'
# Game camera: Godot position (0, 33, 29) looking at the origin. Godot (x, y, z) -> Blender (x, -z, y).
VIEW = Vector((0.0, -29.0, 33.0)).normalized()
# Godot sun rotation_degrees (-58, -32, 0); same direction expressed in Blender axes.
SUN_EULER = (math.radians(32), math.radians(0), math.radians(-32))


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.samples = 48
    scene.cycles.use_denoising = True
    scene.render.film_transparent = True
    scene.view_settings.view_transform = 'Standard'
    world = bpy.data.worlds.new('World')
    world.use_nodes = True
    world.node_tree.nodes['Background'].inputs['Color'].default_value = (0.62, 0.72, 0.8, 1)
    world.node_tree.nodes['Background'].inputs['Strength'].default_value = 0.55
    scene.world = world
    sun = bpy.data.objects.new('Sun', bpy.data.lights.new('Sun', 'SUN'))
    sun.data.energy = 3.4
    sun.data.angle = math.radians(6)
    sun.rotation_euler = SUN_EULER
    scene.collection.objects.link(sun)
    return scene


def bounds(objects):
    lo = Vector((1e9, 1e9, 1e9)); hi = Vector((-1e9, -1e9, -1e9))
    for obj in objects:
        for corner in obj.bound_box:
            world = obj.matrix_world @ Vector(corner)
            lo = Vector(map(min, lo, world)); hi = Vector(map(max, hi, world))
    return lo, hi


def camera(scene, center, direction, scale, size):
    cam = bpy.data.objects.new('Camera', bpy.data.cameras.new('Camera'))
    cam.data.type = 'ORTHO'
    cam.data.ortho_scale = scale
    cam.data.clip_end = 500
    cam.location = center + direction * 60
    cam.rotation_euler = (-direction).to_track_quat('-Z', 'Y').to_euler()
    scene.collection.objects.link(cam)
    scene.camera = cam
    scene.render.resolution_x = size
    scene.render.resolution_y = size
    return cam


def render(slug, size):
    """Each mesh in the file is a variant (Poly Haven packs several per asset); each gets its own sprite."""
    scene = reset()
    gltf = next((CACHE / slug).glob('*.gltf'))
    bpy.ops.import_scene.gltf(filepath=str(gltf))
    meshes = [obj for obj in scene.objects if obj.type == 'MESH']
    OUT.mkdir(parents=True, exist_ok=True)
    infos = []
    # Trees are few and tall, so each is also rendered turned 120° and 240° for distinct silhouettes.
    turns = [0, 120, 240] if 'tree' in slug and len(meshes) == 1 else [0]
    jobs = [(index, target, turn) for index, target in enumerate(meshes) for turn in turns]
    for index, target, turn in jobs:
        name = slug if len(meshes) == 1 else f'{slug}_{index}'
        if len(turns) > 1: name = f'{slug}_r{turn}'
        target.rotation_mode = 'XYZ'
        target.rotation_euler.z = math.radians(turn)
        bpy.context.view_layer.update()
        for obj in meshes:
            obj.hide_render = obj is not target
            obj.visible_camera = True
        lo, hi = bounds([target])
        base = Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, lo.z))
        center = (lo + hi) / 2
        extent = max(hi.x - lo.x, hi.y - lo.y, hi.z - lo.z)
        scale = extent * 1.2
        cam = camera(scene, center, VIEW, scale, size)
        scene.render.filepath = str(OUT / f'{name}.png')
        bpy.ops.render.render(write_still=True)
        pivot = world_to_camera_view(scene, cam, base)
        # Shadow: top-down view of a shadow catcher; the model is hidden from that camera but still casts.
        bpy.ops.mesh.primitive_plane_add(size=extent * 5, location=(center.x, center.y, lo.z))
        plane = bpy.context.active_object
        plane.is_shadow_catcher = True
        target.visible_camera = False
        shadow_scale = extent * 2.6
        top = camera(scene, Vector((center.x, center.y, lo.z)), Vector((0, 0, 1)), shadow_scale, size // 2)
        scene.render.filepath = str(OUT / f'{name}_shadow.png')
        bpy.ops.render.render(write_still=True)
        shadow_pivot = world_to_camera_view(scene, top, base)
        for helper in (plane, cam, top): bpy.data.objects.remove(helper, do_unlink=True)
        info = {'name': name, 'source': f'https://polyhaven.com/a/{slug}', 'license': 'CC0',
                'height': hi.z - lo.z, 'ortho_scale': scale, 'pivot_uv': [pivot.x, 1 - pivot.y],
                'shadow_scale': shadow_scale, 'shadow_pivot_uv': [shadow_pivot.x, 1 - shadow_pivot.y]}
        (OUT / f'{name}.json').write_text(json.dumps(info, indent=2), encoding='utf-8')
        print('SPRITE', json.dumps(info), flush=True)


if __name__ == '__main__':
    slugs = sys.argv[sys.argv.index('--') + 1:]
    for slug in slugs:
        render(slug, 768 if 'tree' in slug else 512)
