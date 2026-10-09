# Music drop folder

`AudioManager.play_music(name)` plays `<name>.ogg` here (looped). Missing files
no-op. TestRoom requests a per-realm track and the Hub requests `hub`.

Expected tracks:

| name       | used by                          |
|------------|----------------------------------|
| `realm_0` … `realm_6` | one loop per realm (RealmDefs order) |
| `hub`      | the post-death hub screen        |
| `miniboss` | (optional) mini-boss encounter   |

Loopable `.ogg`, ~60–120s, target loudness ~-14 LUFS. See `docs/ASSET-PIPELINE.md`.
