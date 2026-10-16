"""Hand-built low-poly props for shapes TRELLIS.2 can't reconstruct (open, thin, shell-like).

  blender -b -P tools/blender_props.py -- [bucket stool pottery_shard]

Writes art/<category>s/<id>/prepped.glb (same place the asset runner puts its output, so
tools/sync_assets.py picks them up). The failed TRELLIS meshes stay in git history.
Style per design/art-bible.md: flat-shaded facets, one dominant colour per prop, chunky.
"""
import math
import pathlib
import random
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector

ROOT = pathlib.Path(__file__).resolve().parent.parent
ART = ROOT / "art"


def mat(name, rgb, rough=0.75, metal=0.0):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*rgb, 1.0)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metal
    return m


def obj_from_bm(name, bm, mats):
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    for m in mats:
        me.materials.append(m)
    for p in me.polygons:
        p.use_smooth = False
    o = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(o)
    return o


def ring(bm, n, r, z, phase=0.0, jitter=0.0, rng=None):
    out = []
    for i in range(n):
        a = phase + 2 * math.pi * i / n
        rr = r + (rng.uniform(-jitter, jitter) if rng else 0.0)
        out.append(bm.verts.new((rr * math.cos(a), rr * math.sin(a), z)))
    return out


def bridge(bm, a, b, mat_of=lambda i: 0, flip=False):
    n = len(a)
    for i in range(n):
        j = (i + 1) % n
        q = (a[i], a[j], b[j], b[i]) if not flip else (b[i], b[j], a[j], a[i])
        f = bm.faces.new(q)
        f.material_index = mat_of(i)


def cap(bm, verts, mi, flip=False):
    f = bm.faces.new(list(reversed(verts)) if flip else verts)
    f.material_index = mi
    return f


def tube(name, n, r_in, r_out, z0, z1, mats, mi=0):
    """Closed ring band (iron hoop)."""
    bm = bmesh.new()
    a0, a1 = ring(bm, n, r_out[0], z0), ring(bm, n, r_out[1], z1)
    b0, b1 = ring(bm, n, r_in[0], z0), ring(bm, n, r_in[1], z1)
    bridge(bm, a0, a1, lambda i: mi)
    bridge(bm, b1, b0, lambda i: mi)
    bridge(bm, a1, b1, lambda i: mi)
    bridge(bm, b0, a0, lambda i: mi)
    return obj_from_bm(name, bm, mats)


# ------------------------------------------------------------------ bucket
def build_bucket():
    """Sturdy wooden bucket: 12 staves (two wood tones), two iron hoops, rope handle, water inside."""
    wood = mat("bucket_wood", (0.52, 0.30, 0.14))
    wood2 = mat("bucket_wood_dark", (0.42, 0.23, 0.10))
    iron = mat("bucket_iron", (0.16, 0.16, 0.17), rough=0.45, metal=0.8)
    water = mat("bucket_water", (0.12, 0.38, 0.55), rough=0.08)
    rope = mat("bucket_rope", (0.70, 0.58, 0.36))
    n, h, rb, rt, wall = 12, 0.40, 0.165, 0.205, 0.022
    bm = bmesh.new()
    rng = random.Random(3)
    ob, ot = ring(bm, n, rb, 0.0), ring(bm, n, rt, h)
    # stave tops jitter a little: hand-made, not a perfect cylinder
    for v in ot:
        v.co.z += rng.uniform(-0.008, 0.006)
    ib, it = ring(bm, n, rb - wall, 0.03), ring(bm, n, rt - wall, h - 0.004)
    stave = lambda i: i % 2
    bridge(bm, ob, ot, stave)
    bridge(bm, it, ib, stave)
    bridge(bm, ot, it, stave)
    cap(bm, ob, 1, flip=True)
    cap(bm, ib, 0)
    # water surface at 70%
    wz = h * 0.72
    rw = rb - wall + (rt - rb) * 0.72
    cap(bm, ring(bm, n, rw, wz), 2)
    o = obj_from_bm("bucket", bm, [wood, wood2, water])
    parts = [o]
    for z in (0.07, 0.31):
        k = z / h
        r = rb + (rt - rb) * k
        parts.append(tube("hoop", n, (r - 0.004, r + 0.006), (r - 0.002, r + 0.010), z - 0.022, z + 0.022, [iron]))
    # rope handle: arc of a thick 6-sided tube over the top
    bm = bmesh.new()
    seg, R, thick = 10, rt + 0.005, 0.014
    prev = None
    for s in range(seg + 1):
        a = math.pi * s / seg
        c = Vector((R * math.cos(a), 0.0, h + 0.01 + 0.10 * math.sin(a)))
        tan = Vector((-math.sin(a), 0.0, math.cos(a))).normalized()
        side = Vector((0, 1, 0))
        up = tan.cross(side).normalized()
        cur = [bm.verts.new(c + thick * (math.cos(t) * side + math.sin(t) * up))
               for t in (2 * math.pi * k / 6 for k in range(6))]
        if prev:
            bridge(bm, prev, cur)
        prev = cur
    parts.append(obj_from_bm("handle", bm, [rope]))
    return join(parts, "bucket")


# ------------------------------------------------------------------ stool
def build_stool():
    """Three-legged round stool: thick 10-sided seat with a chamfer, splayed square legs, a stretcher ring."""
    seat_m = mat("stool_seat", (0.50, 0.28, 0.12))
    leg_m = mat("stool_leg", (0.34, 0.18, 0.07))
    h, r, th, ch = 0.45, 0.20, 0.06, 0.014
    bm = bmesh.new()
    n = 10
    b = ring(bm, n, r - 0.01, h - th)
    m1 = ring(bm, n, r, h - th + 0.012)
    m2 = ring(bm, n, r, h - ch)
    t = ring(bm, n, r - ch, h)
    bridge(bm, b, m1)
    bridge(bm, m1, m2)
    bridge(bm, m2, t)
    cap(bm, t, 0)
    cap(bm, b, 0, flip=True)
    parts = [obj_from_bm("seat", bm, [seat_m])]
    # legs: tapered 4-sided posts from under the seat rim out to a wider foot circle
    for k in range(3):
        a = 2 * math.pi * k / 3 + math.pi / 6
        top = Vector((0.12 * math.cos(a), 0.12 * math.sin(a), h - th + 0.01))
        foot = Vector((0.19 * math.cos(a), 0.19 * math.sin(a), 0.0))
        parts.append(post(top, foot, 0.026, 0.021, leg_m))
    # stretcher: thin 3-sided ring linking the legs at 1/3 height
    z, rr = 0.15, 0.165
    pts = []
    for k in range(3):
        a = 2 * math.pi * k / 3 + math.pi / 6
        pts.append(Vector((rr * math.cos(a), rr * math.sin(a), z)))
    for k in range(3):
        parts.append(post(pts[k], pts[(k + 1) % 3], 0.012, 0.012, leg_m))
    return join(parts, "stool")


def post(p0, p1, w0, w1, m):
    """Square post between two points, half-widths w0 at p0 and w1 at p1."""
    bm = bmesh.new()
    d = (p1 - p0).normalized()
    s = d.cross(Vector((0, 0, 1)) if abs(d.z) < 0.9 else Vector((1, 0, 0))).normalized()
    u = d.cross(s).normalized()
    sq = lambda c, w: [bm.verts.new(c + w * (x * s + y * u)) for x, y in ((1, 1), (-1, 1), (-1, -1), (1, -1))]
    a, b = sq(p0, w0), sq(p1, w1)
    bridge(bm, a, b)
    cap(bm, a, 0, flip=True)
    cap(bm, b, 0)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return obj_from_bm("post", bm, [m])


# ------------------------------------------------------------------ pottery shard
def build_shard():
    """Thick curved piece of the spirit urn: glossy deep-blue glaze outside with a gold band, bare clay inside, jagged edges."""
    glaze = mat("shard_glaze", (0.04, 0.07, 0.42), rough=0.22)
    gold = mat("shard_gold", (0.85, 0.62, 0.18), rough=0.3, metal=0.9)
    clay = mat("shard_clay", (0.62, 0.40, 0.28))
    rng = random.Random(11)
    R, wall, cols, rows, span, hgt = 0.17, 0.028, 6, 3, math.radians(80), 0.17
    bm = bmesh.new()

    def grid(radius):
        g = []
        for j in range(rows + 1):
            row = []
            for i in range(cols + 1):
                a = -span / 2 + span * i / cols
                z = hgt * j / rows
                # jagged break line on all four borders
                if j == rows:
                    z += rng.uniform(-0.045, 0.02)
                if j == 0:
                    z += rng.uniform(0.0, 0.03)
                if i in (0, cols):
                    a += rng.uniform(-0.12, 0.12)
                bulge = 1.0 + 0.10 * math.sin(math.pi * j / rows)   # urn belly curve
                row.append((radius * bulge * math.cos(a), radius * bulge * math.sin(a), z))
            g.append(row)
        return g

    outer = grid(R)
    vo = [[bm.verts.new(p) for p in row] for row in outer]
    vi = [[bm.verts.new(Vector(p) * Vector(((R - wall) / R, (R - wall) / R, 1.0))) for p in row] for row in outer]
    for j in range(rows):
        for i in range(cols):
            f = bm.faces.new((vo[j][i], vo[j][i + 1], vo[j + 1][i + 1], vo[j + 1][i]))
            f.material_index = 1 if j == 1 else 0
            g = bm.faces.new((vi[j + 1][i], vi[j + 1][i + 1], vi[j][i + 1], vi[j][i]))
            g.material_index = 2
    # rim faces (broken edges show clay)
    edge = [(vo[0][i], vi[0][i]) for i in range(cols + 1)] + \
           [(vo[j][cols], vi[j][cols]) for j in range(1, rows + 1)] + \
           [(vo[rows][i], vi[rows][i]) for i in range(cols - 1, -1, -1)] + \
           [(vo[j][0], vi[j][0]) for j in range(rows - 1, 0, -1)]
    for k in range(len(edge)):
        (a, b), (c, d) = edge[k], edge[(k + 1) % len(edge)]
        f = bm.faces.new((a, c, d, b))
        f.material_index = 2
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    o = obj_from_bm("pottery_shard", bm, [glaze, gold, clay])
    # lay it on its side like a dropped piece: glazed side up, tilted
    o.matrix_world = Matrix.Rotation(math.radians(-75), 4, "Y") @ Matrix.Rotation(math.radians(-15), 4, "X")
    return join([o], "pottery_shard")


# ------------------------------------------------------------------ common
def join(parts, name):
    bpy.ops.object.select_all(action="DESELECT")
    for p in parts:
        p.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    if len(parts) > 1:
        bpy.ops.object.join()
    o = bpy.context.view_layer.objects.active
    o.name = name
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    # origin at the feet: centre in x/y, floor at z = 0
    bb = [o.matrix_world @ Vector(c) for c in o.bound_box]
    lo = Vector((min(v.x for v in bb), min(v.y for v in bb), min(v.z for v in bb)))
    hi = Vector((max(v.x for v in bb), max(v.y for v in bb), max(v.z for v in bb)))
    shift = Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, lo.z))
    o.data.transform(Matrix.Translation(-shift))
    return o


BUILDERS = {"bucket": ("props", build_bucket), "stool": ("props", build_stool),
            "pottery_shard": ("pieces", build_shard)}


def main():
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    for pid in args or list(BUILDERS):
        bpy.ops.wm.read_factory_settings(use_empty=True)
        folder, fn = BUILDERS[pid]
        o = fn()
        out = ART / folder / pid
        out.mkdir(parents=True, exist_ok=True)
        dst = out / "prepped.glb"
        bpy.ops.object.select_all(action="DESELECT")
        o.select_set(True)
        bpy.ops.export_scene.gltf(filepath=str(dst), use_selection=True, export_format="GLB", export_apply=True)
        d = o.dimensions
        print(f"ok    {pid}.glb: {len(o.data.polygons)} faces, size {d.x:.2f} x {d.y:.2f} x {d.z:.2f} m")


main()
