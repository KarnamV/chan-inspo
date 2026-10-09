"""Render style-lock samples: hero + chair per style, isometric gameplay view + close front/back.

blender -b -P style_render.py -- <mesh_dir> <out_dir> lowpoly toon painterly chunky
"""
import math
import os
import sys

import bpy
from mathutils import Vector

args = sys.argv[sys.argv.index("--") + 1:]
mesh_dir, out_dir, styles = args[0], args[1], args[2:]
os.makedirs(out_dir, exist_ok=True)


def load(path, height, x):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    objs = [o for o in bpy.data.objects if o not in before and o.type == "MESH"]
    lo = Vector((1e9,) * 3)
    hi = Vector((-1e9,) * 3)
    for o in objs:
        for c in o.bound_box:
            w = o.matrix_world @ Vector(c)
            lo = Vector(map(min, lo, w))
            hi = Vector(map(max, hi, w))
    s = height / (hi.z - lo.z)
    for o in objs:
        o.location = (o.location - Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, lo.z))) * s + Vector((x, 0, 0))
        o.scale = o.scale * s
    return objs


def newest(prefix):
    fs = sorted(f for f in os.listdir(mesh_dir) if f.startswith(prefix) and f.endswith(".glb"))
    return os.path.join(mesh_dir, fs[-1])


for style in styles:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    load(newest(f"hero-{style}_"), 1.8, -0.5)
    load(newest(f"chair-{style}_"), 0.9, 0.6)
    bpy.ops.mesh.primitive_plane_add(size=30)
    floor = bpy.context.object
    fm = bpy.data.materials.new("floor")
    fm.diffuse_color = (0.18, 0.12, 0.12, 1)
    fm.use_nodes = True
    fm.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.16, 0.1, 0.1, 1)
    floor.data.materials.append(fm)
    sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN"))
    sun.data.energy = 3.0
    sun.rotation_euler = (math.radians(50), 0, math.radians(35))
    sc.collection.objects.link(sun)
    sc.world = bpy.data.worlds.new("w")
    sc.world.use_nodes = True
    bg = sc.world.node_tree.nodes["Background"]
    bg.inputs[0].default_value = (0.35, 0.3, 0.32, 1)
    bg.inputs[1].default_value = 0.8
    engines = [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
    sc.render.engine = "BLENDER_EEVEE" if "BLENDER_EEVEE" in engines else "BLENDER_EEVEE_NEXT"
    sc.view_settings.view_transform = "Standard"
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
    sc.collection.objects.link(cam)
    sc.camera = cam
    cam.data.type = "ORTHO"
    target = Vector((0, 0, 0.8))

    # isometric gameplay view: 45 deg yaw, ~35 deg elevation, room-sized framing
    cam.data.ortho_scale = 9.0
    d = Vector((1, -1, 1.0)).normalized()
    cam.location = target + d * 20
    cam.rotation_euler = (target - cam.location).to_track_quat("-Z", "Y").to_euler()
    sc.render.resolution_x, sc.render.resolution_y = 640, 360
    sc.render.filepath = os.path.join(out_dir, f"{style}_iso.png")
    bpy.ops.render.render(write_still=True)

    # close front / back
    cam.data.ortho_scale = 2.4
    sc.render.resolution_x, sc.render.resolution_y = 400, 400
    for name, dv in (("front", (0.25, -1, 0.15)), ("back", (-0.25, 1, 0.15))):
        d = Vector(dv).normalized()
        cam.location = target + d * 20
        cam.rotation_euler = (target - cam.location).to_track_quat("-Z", "Y").to_euler()
        sc.render.filepath = os.path.join(out_dir, f"{style}_{name}.png")
        bpy.ops.render.render(write_still=True)
print("STYLE RENDERS DONE")
