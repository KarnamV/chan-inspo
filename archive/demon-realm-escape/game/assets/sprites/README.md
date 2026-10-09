# Sprite / animation drop folder

Pre-rendered 2.5D sprite sheets (Blender → PNG) and 2D art (image-gen AI) live
here. The game currently uses `PlaceholderTexture2D`; swapping to real art means
importing a `SpriteFrames` (for animated characters) or a `Texture2D` and
pointing the scene's `Sprite2D`/`AnimatedSprite2D` at it.

Suggested layout:

```
sprites/
  player/        # idle, walk, punch, kick, throw, dash, dodge, block, hurt, dead
  enemies/       # demon/, warrior/, beast/, miniboss/
  talismans/     # 10 icons (64x64)
  props/         # coins, doors, shrine, altar
  ui/            # panels, bars, buttons
  tiles/         # floor + wall tiles per realm theme
```

See `docs/ASSET-PIPELINE.md` for the full asset spec (sizes, states, counts) and
the Blender render-to-sprite + image-gen workflow.
