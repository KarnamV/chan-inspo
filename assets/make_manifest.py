"""Builds assets/manifest.csv for phases M0-M4 (see design/assets.md). Re-running keeps existing statuses."""
import csv
import os
from collections import Counter

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "manifest.csv")
HB = "humanoid_base"
rows = []


def a(i, c, p, prompt, h="", t="", clips=""):
    rows.append(dict(id=i, category=c, phase=p, prompt=prompt, height=h, tris=t, clips=clips, status="", notes=""))


# M0
a("hero", "character", "M0", "young East Asian martial arts stuntman, original character, short black hair, confident grin, "
  "red sleeveless kung fu vest over white t-shirt, black loose trousers, cloth wrist wraps, black kung fu shoes", "1.8", "30000", HB)
a("chair", "prop", "M0", "old wooden chair with a slightly cracked leg", "0.9", "5000")
a("icon_talisman_sheep", "icon", "M0", "sheep zodiac talisman, round jade medallion with a sheep emblem, chinese style")

# M1
a("brute", "character", "M1", "hulking horned demon brute, grey-red skin, small glowing yellow eyes, torn dark trousers, "
  "iron wrist cuffs, bare chest, heavy build", "2.1", "30000", HB)
a("bench", "prop", "M1", "long wooden bench with four legs", "0.5", "5000")
a("crate", "prop", "M1", "wooden shipping crate with rope handles", "0.6", "5000")
a("barrel", "prop", "M1", "wooden barrel with iron hoops", "0.9", "5000")
a("pole", "prop", "M1", "long bamboo pole standing upright", "1.8", "3000")
for i, p, h in (("plank", "single broken wooden plank standing upright, splintered end", "0.9"),
                ("wood_leg", "single broken wooden table leg standing upright", "0.5"),
                ("stake", "thick chunky sharpened wooden stake, solid single piece, standing upright", "0.5"),
                ("barrel_stave", "single curved barrel stave with a bit of iron hoop, standing upright", "0.9")):
    a(i, "piece", "M1", p, h, "2000")
a("pillar", "decor", "M1", "red lacquered chinese temple pillar with golden dragon carving", "3.0", "8000")
a("room_door", "decor", "M1", "ornate chinese demon-realm gate door with glowing red talisman seal", "2.6", "8000")
a("floor_test", "texture", "M1", "dark stone tiles with red cracks")
a("wall_test", "texture", "M1", "dark red brick wall with paper talisman scraps")

# M2
for i, p, h in (("shield_demon", "armored demon soldier carrying a large round wooden door as a shield, dark blue skin, horned helmet", "1.9"),
                ("thief_imp", "small sneaky green imp demon with big ears, sack over shoulder, grinning", "1.3"),
                ("archer_demon", "lean demon with a bandolier of throwing knives and bottles, purple skin, hood", "1.8"),
                ("wraith", "ghostly wraith in tattered grey robes, glowing pale blue face, long sleeves", "1.9"),
                ("armored_ghoul", "undead ghoul covered in paper talisman wards and bronze armor plates, green-grey skin", "1.8")):
    a(i, "character", "M2", p, h, "30000", HB)
for i, p, h, t in (("lantern", "round red paper lantern with a candle glowing inside", "0.5", "3000"),
                   ("bucket", "sturdy wooden bucket with two iron bands, solid, opaque", "0.4", "3000"),
                   ("spirit_urn", "chunky ceramic urn painted deep blue with gold pattern and a glowing green lid, solid, opaque", "0.6", "4000"),
                   ("weapon_rack", "wooden weapon rack holding spears and staffs", "1.6", "6000"),
                   ("spear", "chinese spear with red tassel standing upright", "2.0", "3000"),
                   ("stool", "small sturdy round wooden stool with three thick legs, solid", "0.45", "3000"),
                   ("bun_basket", "bamboo steamer basket full of white steamed buns", "0.3", "4000"),
                   ("roast_duck", "glossy roast duck hanging on a hook", "0.35", "4000"),
                   ("fruit_cart", "small wooden fruit cart with oranges and melons", "1.2", "6000")):
    a(i, "prop", "M2", p, h, t)
a("pottery_shard", "piece", "M2", "thick chunky broken piece of a dark blue ceramic pot, solid", "0.25", "1500")
a("metal_scrap", "piece", "M2", "bent piece of iron hoop metal scrap", "0.3", "1500")
for i, p in (("icon_dmg_physical", "clenched fist emblem, physical damage symbol"),
             ("icon_dmg_magic", "glowing jade chi swirl emblem, magic damage symbol"),
             ("icon_elem_fire", "stylized flame emblem"), ("icon_elem_water", "stylized water droplet emblem")):
    a(i, "icon", "M2", p)

# M3: talisman icons (sheep is in M0)
for an, col in (("rat", "grey"), ("ox", "brown"), ("tiger", "orange"), ("rabbit", "white"), ("dragon", "red"),
                ("snake", "green"), ("horse", "chestnut"), ("monkey", "golden"), ("rooster", "red and gold"),
                ("dog", "tan"), ("pig", "pink")):
    a(f"icon_talisman_{an}", "icon", "M3", f"{an} zodiac talisman, round jade medallion with a {col} {an} emblem, chinese style")

# M4: realm 1 Ember Night Market
a("butcher_king", "boss", "M4", "giant demon butcher king, huge belly, bloodstained apron, crown made of meat cleavers, red skin, empty hands", "2.6", "30000", HB)
a("helper_stunt_coordinator", "character", "M4", "middle-aged stunt coordinator, headset, utility vest with many pockets, cargo pants, sneakers, friendly", "1.75", "30000", "helper")
a("helper_street_chef", "character", "M4", "cheerful plump street chef, white chef jacket, red bandana, apron, empty hands", "1.7", "30000", "helper")
for i, p, h, t in (("market_stall_cart", "wooden night market stall cart with red awning and hanging lanterns", "1.8", "6000"),
                   ("wok", "black iron wok with wooden handle", "0.25", "2000"),
                   ("hanging_lantern", "large round red silk lantern with gold top and bottom caps, solid, opaque", "0.6", "3000"),
                   ("crate_of_fish", "wooden crate full of fish on ice", "0.6", "4000")):
    a(i, "prop", "M4", p, h, t)
for i, p, h in (("stall_awning", "red and white striped market stall awning on wooden poles", "2.6"),
                ("noodle_stand", "steaming noodle stand counter with bowls and pots", "1.6"),
                ("paper_lantern_string", "thick wooden post with a crossbar and three round red lanterns hanging from it, solid", "2.4"),
                ("rice_sacks", "three plump burlap rice sacks stacked together, solid round shapes", "0.7"),
                ("market_gate", "ornate red chinese paifang market gate", "4.0"),
                ("incense_stand", "bronze incense burner stand with smoke", "1.2")):
    a(i, "decor", "M4", p, h, "8000")
a("market_floor", "texture", "M4", "worn night market stone pavement with puddles reflecting red lantern light")
a("market_wall", "texture", "M4", "old chinese market shop wall with red wooden panels and posters")
a("portrait_stunt_coordinator", "portrait", "M4", "middle-aged stunt coordinator with headset, friendly grin")
a("portrait_street_chef", "portrait", "M4", "cheerful plump street chef with red bandana")
for i, p in (("icon_door_talisman", "zodiac medallion on a door, talisman reward symbol"),
             ("icon_door_boon", "helping hand with sparkle, blessing reward symbol"),
             ("icon_door_draft", "martial arts scroll, new technique reward symbol"),
             ("icon_door_gold", "pile of gold coins"), ("icon_door_shop", "small shop stall with lantern"),
             ("icon_gold", "single chinese gold coin with square hole"),
             ("icon_shards", "glowing violet spirit crystal shard")):
    a(i, "icon", "M4", p)
for i, p in (("boon_combo_fill", "stopwatch with sparkles, combo variety symbol"), ("boon_prop_power", "wooden chair with power glow"),
             ("boon_stunt_dodge", "acrobat flip silhouette"), ("boon_double_throw", "two flying crates"),
             ("boon_extra_life", "heart with a stunt helmet"), ("boon_crowd_ko", "explosion of stars"),
             ("boon_food_fill", "steaming bun with chi swirl"), ("boon_spicy_dmg", "red chili pepper with flames"),
             ("boon_hearty_heal", "bowl of soup with heart"), ("boon_feast_shield", "wok used as a shield"),
             ("boon_chef_knife", "crossed chef knives"), ("boon_second_helping", "two bowls stacked, extra life symbol")):
    a("icon_" + i, "icon", "M4", p)

# keep statuses from an existing manifest
if os.path.exists(OUT):
    with open(OUT, newline="", encoding="utf-8") as f:
        old = {r["id"]: r for r in csv.DictReader(f)}
    for r in rows:
        if r["id"] in old:
            r["status"], r["notes"] = old[r["id"]]["status"], old[r["id"]]["notes"]
with open(OUT, "w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
    w.writeheader()
    w.writerows(rows)
print(len(rows), "rows")
print(sorted(Counter((r["phase"], r["category"]) for r in rows).items()))
