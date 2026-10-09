# Art bible (locked 2026-10-09)

Style: **stylized low-poly**. Picked from 4 full-chain samples (low-poly, toon, painterly, chunky). Compared in 3D + Godot walk/run: `art/style_lock/chain/style_lineup_walk_run.mp4`.

**Why low-poly:**
- Retargets cleanly with no per-character fixes (normal proportions).
- Flat shading hides texture flaws.
- Reads well from the isometric camera.
- Chunky was rejected: arms clamp and stride is short on the animation library, so every clip would need proportion fixes. Painterly was rejected: dark areas merge with the floor.

## Prompt rules (klein concept stage)

- **3D style suffix (every character, prop, decor):** `stylized low-poly game art, flat shaded facets, bold colors`
- Pipeline prefixes still apply (`comfy_batch.py`): characters = front view, A-pose, arms clear of the body, white bg, no shadow/floor; props = centered three-quarter, white bg, no shadow/floor.
- klein ignores negative prompts (cfg 1). Exclusions go in the positive text.
- Proportions: **realistic-heroic**, not chibi. Normal limb lengths, so Quaternius clips fit. No oversized hands/heads.
- Hero: young East Asian martial arts stuntman, original character (no real name/likeness). Red sleeveless kung fu vest over white t-shirt, black loose trousers, cloth wrist wraps, black kung fu shoes.

## Palette

- Hero: red + white + black. He must pop against every realm floor.
- Realm accent colours (from v1 moods): Ember Night Market = amber/red; Frozen Teahouse = ice blue; Rotting Docks = sickly green; Ash Opera House = grey/white; Bone Temple = bone/ivory; Void Bamboo Forest = violet; Demon Palace = crimson.
- Enemies: darker, desaturated versions of the realm accent + one glowing demon colour (eyes, marks) for readability.
- Magic/chi effects: jade green + gold. Physical hits: white flash. Possession (Sheep): violet outline.

## Readability rules (isometric)

- Silhouette first: every character readable as a shape at gameplay distance.
- Avoid large black areas touching the floor (painterly sample lesson). Keep shoes/trousers lighter than the floor, or add a rim light/outline.
- Props: one clear dominant colour per prop. Breakable props show cracks before they break.

## Locked reference assets

- Hero: `art/characters/hero/`. Concept, textured mesh, rig (humanoid names), walk/run animated .glb.
- Chair: `art/props/chair/`. Concept + textured mesh.
- 2D icon style: still to lock (M0 task).
