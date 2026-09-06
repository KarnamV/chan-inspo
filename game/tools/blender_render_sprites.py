"""blender_render_sprites.py — render a Blender character into 2.5D sprite sheets.

Drives the "pre-rendered sprite" pipeline from docs/ASSET-PIPELINE.md: a fixed
3/4 top-down orthographic camera renders the character across N facing
directions and, per animation action, across its frame range, writing PNGs with
alpha to per-clip folders that import cleanly as a Godot SpriteFrames.

Run inside Blender (Text Editor > Run, or via the MCP execute_blender_code tool).
It parents the target under a Z-rotation pivot empty and steps that empty through
the directions, so the SAME camera/light rig is reused for every facing.

Conventions
-----------
- 8 directions: S, SE, E, NE, N, NW, W, SW  (screen-space, top-down).
  Godot picks a clip by facing_dir -> one of these suffixes (see ASSET-PIPELINE).
- Output: <out_root>/<char>/<action>_<DIR>/<frame:04>.png

Nothing here is game-specific beyond the defaults; point TARGET_NAME at your
rigged character (mesh + armature under one parent/collection) and set ACTIONS.
"""

import math
import os
import bpy

# ---------------------------------------------------------------------------
# Config — tune per character.
# ---------------------------------------------------------------------------
TARGET_NAME = "Player"        # object (or Empty root) to spin; its children render
OUT_ROOT    = "//sprites"     # '//' = relative to the .blend file
CHAR_NAME   = "player"

RENDER_SIZE   = 256           # square px; downscale in-engine to ~48-64 on import
CAMERA_TILT   = 58.0          # degrees from horizontal (3/4 top-down)
ORTHO_SCALE   = 3.2           # world units the camera frames; grow for taller rigs
SAMPLES       = 16            # EEVEE samples; low is fine for flat/toon look

# 8 facings, clockwise from South (toward camera), with the pivot Z angle each
# needs. Use the first 4 (S, E, N, W) for a cheaper first pass.
DIRECTIONS = {
    "S":  0.0,   "SE": 45.0,  "E":  90.0,  "NE": 135.0,
    "N":  180.0, "NW": 225.0, "W":  270.0, "SW": 315.0,
}

# action_name -> None renders the whole action's frame range; or (start, end).
ACTIONS = {
    "idle": None,
}


# ---------------------------------------------------------------------------
def setup_render():
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE" if "BLENDER_EEVEE" in \
        [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items] \
        else scene.render.engine
    scene.render.film_transparent = True
    scene.render.resolution_x = RENDER_SIZE
    scene.render.resolution_y = RENDER_SIZE
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    try:
        scene.eevee.taa_render_samples = SAMPLES
    except Exception:
        pass


def get_or_make_pivot():
    """Return a Z-rotation Empty; create one and parent TARGET under it if needed."""
    pivot = bpy.data.objects.get("SpriteRenderPivot")
    if pivot is None:
        pivot = bpy.data.objects.new("SpriteRenderPivot", None)
        bpy.context.scene.collection.objects.link(pivot)
    target = bpy.data.objects.get(TARGET_NAME)
    if target and target.parent is not pivot:
        # Keep world transform, then parent to the pivot.
        target.parent = pivot
    return pivot


def setup_camera():
    cam = bpy.data.objects.get("SpriteRenderCam")
    if cam is None:
        cam_data = bpy.data.cameras.new("SpriteRenderCam")
        cam = bpy.data.objects.new("SpriteRenderCam", cam_data)
        bpy.context.scene.collection.objects.link(cam)
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = ORTHO_SCALE

    # Place the camera on the -Y side, tilted down toward the origin.
    tilt = math.radians(CAMERA_TILT)
    dist = 10.0
    cam.location = (0.0, -dist * math.cos(tilt), dist * math.sin(tilt))
    cam.rotation_euler = (math.radians(90.0) - tilt, 0.0, 0.0)
    bpy.context.scene.camera = cam
    return cam


def render_all():
    setup_render()
    pivot = get_or_make_pivot()
    setup_camera()
    scene = bpy.context.scene
    base = bpy.path.abspath(OUT_ROOT)

    for action_name, frame_range in ACTIONS.items():
        start, end = _resolve_range(frame_range)
        for dir_name, z_deg in DIRECTIONS.items():
            pivot.rotation_euler = (0.0, 0.0, math.radians(z_deg))
            out_dir = os.path.join(base, CHAR_NAME, f"{action_name}_{dir_name}")
            os.makedirs(out_dir, exist_ok=True)
            for f in range(start, end + 1):
                scene.frame_set(f)
                scene.render.filepath = os.path.join(out_dir, f"{f:04d}.png")
                bpy.ops.render.render(write_still=True)


def _resolve_range(frame_range):
    if frame_range is not None:
        return int(frame_range[0]), int(frame_range[1])
    scene = bpy.context.scene
    return scene.frame_start, scene.frame_end


if __name__ == "__main__":
    render_all()
