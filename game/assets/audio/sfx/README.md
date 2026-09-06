# SFX drop folder

`AudioManager` (autoload) plays these by key. Drop a file named `<key>.ogg`
(preferred) or `<key>.wav` here and it plays automatically — no code changes.

Expected keys (see `SFX_KEYS` in `scripts/AudioManager.gd`):

| key           | trigger                                   |
|---------------|-------------------------------------------|
| `hit`         | a player strike connects                  |
| `big_hit`     | counter / talisman-boosted hit (≥30 dmg)  |
| `enemy_death` | an enemy is destroyed                     |
| `player_hurt` | the player takes damage                   |
| `coin`        | a gold coin is collected                  |
| `talisman`    | a talisman is activated                   |
| `ui_open`     | shop / shrine / temptation opens          |
| `purchase`    | bought an item / took a pact              |
| `miniboss`    | a mini-boss appears                       |

Keep clips short (< 1s), mono, normalized. See `docs/ASSET-PIPELINE.md`.
