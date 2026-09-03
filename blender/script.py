import bpy
import bmesh
from mathutils import Vector
from collections import defaultdict
import os

OUTPUT_PATH = os.path.join(bpy.path.abspath("//My Games//FarmingSimulator2025//mods//FS25_AnimalAuctions//placeables//animalMart"), "geometry.xml")

NAV_OBJ_NAME = "outer"
BLOCKED_OBJ_NAME = "blocked"
ROOM_NAMES = ["room_reception", "room_cafe", "room_carParkLeft"]

# -------------------------------------------------
# Helpers
# -------------------------------------------------
def get_object(name):
    obj = bpy.data.objects.get(name)
    if obj is None:
        print(f"WARNING: object '{name}' not found")
    return obj

def world_co(obj, local_co):
    return obj.matrix_world @ local_co

def xml_vertex(co, indent=4):
    return f'{" " * indent}<vertex x="{co.x:.6f}" y="{co.y:.6f}" z="{co.z:.6f}"/>\n'

def get_bmesh(obj):
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bm.verts.ensure_lookup_table()
    bm.edges.ensure_lookup_table()
    return bm

# -------------------------------------------------
# Perimeter walk (outer / blocked)
# -------------------------------------------------
def get_boundary_adj(bm):
    adj = defaultdict(list)
    for e in bm.edges:
        if not e.is_boundary:
            continue
        a, b = e.verts[0].index, e.verts[1].index
        if b not in adj[a]:
            adj[a].append(b)
        if a not in adj[b]:
            adj[b].append(a)
    return adj

def walk_loop(bm, adj, start):
    if start not in adj or not adj[start]:
        return []

    path = [start]
    prev = None
    current = start

    for _ in range(len(bm.verts) + 8):
        neighbours = adj[current]
        nxt = None
        for n in neighbours:
            if n != prev:
                nxt = n
                break
        if nxt is None:
            break
        if nxt == start:
            break
        path.append(nxt)
        prev = current
        current = nxt
    return path

def all_boundary_loops_world(obj):
    bm = get_bmesh(obj)
    adj = get_boundary_adj(bm)
    visited = set()
    loops = []

    for start in list(adj.keys()):
        if start in visited:
            continue
        loop = walk_loop(bm, adj, start)
        if len(loop) < 3:
            continue
        for i in loop:
            visited.add(i)
        world_loop = [world_co(obj, bm.verts[i].co.copy()) for i in loop]
        loops.append(world_loop)

    bm.free()
    return loops

def outer_loop_world(obj):
    bm = get_bmesh(obj)
    adj = get_boundary_adj(bm)

    start = None
    best = None
    for v in bm.verts:
        if v.index not in adj:
            continue
        w = world_co(obj, v.co)
        key = (w.x, w.y, w.z)
        if best is None or key < best:
            best = key
            start = v.index

    if start is None:
        bm.free()
        return []

    loop = walk_loop(bm, adj, start)
    world_loop = [world_co(obj, bm.verts[i].co.copy()) for i in loop]
    bm.free()
    return world_loop

# -------------------------------------------------
# Room cubes
# -------------------------------------------------
def export_room(obj):
    corners = [world_co(obj, Vector(c)) for c in obj.bound_box]

    min_c = Vector((
        min(c.x for c in corners),
        min(c.y for c in corners),
        min(c.z for c in corners),
    ))
    max_c = Vector((
        max(c.x for c in corners),
        max(c.y for c in corners),
        max(c.z for c in corners),
    ))
    center = (min_c + max_c) * 0.5
    size = max_c - min_c

    loc = obj.matrix_world.translation
    rot = obj.matrix_world.to_euler('XYZ')
    scale = obj.matrix_world.to_scale()

    xml = f'    <room name="{obj.name}" minX="{min_c.x:.4f}" minY="{min_c.y:.4f}" minZ="{min_c.z:.4f}" maxX="{max_c.x:.4f}" maxY="{max_c.y:.4f}" maxZ="{max_c.z:.4f}"/>\n'
    return xml

# -------------------------------------------------
# Main
# -------------------------------------------------
nav_obj = get_object(NAV_OBJ_NAME)
blocked_obj = get_object(BLOCKED_OBJ_NAME)

if nav_obj is None:
    raise RuntimeError(f"Required object '{NAV_OBJ_NAME}' is missing")

outer = outer_loop_world(nav_obj)
print(f"Outer polygon: {len(outer)} vertices")

blocked_loops = []
if blocked_obj is not None:
    blocked_loops = all_boundary_loops_world(blocked_obj)
    print(f"Blocked polygons found: {len(blocked_loops)}")
    for i, loop in enumerate(blocked_loops):
        print(f"  blocked[{i}]: {len(loop)} vertices")
else:
    print("Blocked polygons found: 0")

rooms = []
for name in ROOM_NAMES:
    obj = get_object(name)
    if obj is not None:
        rooms.append(obj)
        print(f"Room found: {name}")

xml = '<?xml version="1.0" encoding="utf-8"?>\n'
xml += '<navigation>\n'

xml += '  <outerPolygon>\n'
for v in outer:
    xml += xml_vertex(v, 4)
xml += '  </outerPolygon>\n'

xml += '  <blockedPolygons>\n'
for i, loop in enumerate(blocked_loops):
    xml += f'    <polygon id="{i}">\n'
    for v in loop:
        xml += xml_vertex(v, 6)
    xml += '    </polygon>\n'
xml += '  </blockedPolygons>\n'

xml += '  <rooms>\n'
for obj in rooms:
    xml += export_room(obj)
xml += '  </rooms>\n'

xml += '</navigation>\n'

with open(OUTPUT_PATH, "w", encoding="utf-8") as f:
    f.write(xml)

print(f"Exported: {OUTPUT_PATH}")