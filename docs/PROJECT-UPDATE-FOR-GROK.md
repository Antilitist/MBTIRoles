# MBTI Roles — Project Update (for Grok / future brainstorming)

**Date:** 2026-08-15  
**Mod id:** `MBTIRoles`  
**Version:** 0.4.8 (first Workshop package ready)  
**Authors:** Nipsy / Antilitist  
**Target:** Project Zomboid **Build 42** (multi-folder `common/` + `42/`)  
**Source:** `F:\Grok\Nipsy\MBTIRoles\`  
**Local play:** `X:\Users\USER\Zomboid\mods\MBTIRoles\`  
**Workshop package:** `X:\Users\USER\Zomboid\Workshop\MBTIRoles\`  

Use this doc so another Grok session can invent **later-update features** that fit the design, code, and balance philosophy.

---

## 1. What the mod is

**MBTI Roles** is a **standalone B42 trait mod** (no More Traits / KillCount required).

**Chargen flow (locked):**
1. Player picks **one Role** (exclusive): Analyst · Diplomat · Sentinel · Explorer  
2. Player picks **one Type** from that Role’s four (or picks Type alone — Type **grants** matching Role)  
3. Character ends with **Role + Type** = full MBTI code (e.g. Diplomat + ENFP)

**Philosophy:** personality axes, **not** free professions. Effects stay mild. Numbers are sandbox-tunable **0–25%**.

---

## 2. Role → type map (locked structure — do not break)

| Role | Pattern | Types |
|------|---------|--------|
| **Analyst** | NT | INTJ, INTP, ENTJ, ENTP |
| **Diplomat** | NF | INFJ, INFP, ENFJ, ENFP |
| **Sentinel** | SJ | ISTJ, ISFJ, ESTJ, ESFJ |
| **Explorer** | SP | ISTP, ISFP, ESTP, ESFP |

Trait registry keys: `MBTIRoles:Analyst`, `MBTIRoles:INTJ`, etc.  
Cost: **1** each (B42 hides Cost=0 from trait lists). Free in spirit; mutual exclusivity via scripts.

---

## 3. What already shipped (v0.4.8)

### Chargen / identity
- 4 Role + 16 Type traits (`registries.lua` + `character_trait_definition` scripts)
- Types **GrantedTraits** → matching Role
- Mutual exclusivity (roles vs roles; types vs types + non-matching roles)
- Character screen line: `MBTI: Role · CODE (Name)`
- Custom **18×18** trait icons, **32×32** icon, **256×256** poster/preview
- Author string: `Nipsy/Antilitist`

### Role XP (Events.AddXP)
Sandbox **Role XP bonus %** (default 15) / **Role XP penalty %** (default 10):

| Role | Bonuses (scale with Role XP %) | Penalties (scale with Penalty %) |
|------|--------------------------------|----------------------------------|
| Analyst | Electrical, Mechanics; Literature as secondary | Foraging |
| Diplomat | First Aid (Doctor); Literature secondary | — |
| Sentinel | Farming, Maintenance | — |
| Explorer | Foraging; Aiming secondary | Literature |

Secondary bonuses scale as ~10/15 of primary (design: +10% when primary is +15%).

### Type XP (P3)
Sandbox **Type XP bonus %** (default 5) on one focus skill per type, e.g.:
- INTJ Mechanics, INTP Electrical, ENFP Foraging, ESTP Aiming, ESFP Lightfoot, etc.  
(Full map in `MBTI_Data.lua` → `TypeEffects`.)

### Analyst research
- Hooks `ISResearchRecipe:getDuration` — research **faster** by Research speed % (default 15)  
- Mood when completing research that had researchable recipes  

### Mood hooks (role-themed)
| Role | Source | Notes |
|------|--------|--------|
| Diplomat | Photos / picture books (`ItemTag.PICTURE` etc.); **mementos** (`ismemento` / DisplayCategory Memento); hold memento in hand | Brochures/Fliers excluded (Explorer) |
| Analyst | Finish researching new recipes | |
| Sentinel | Harvest crops (`ISHarvestPlantAction`) | |
| Explorer | **Brochures & Fliers** primary; **small** forage pickup secondary | |

Mood strength scales with sandbox **Mood strength %** (default 15 = design baseline). Cooldowns per source.

### UI / sandbox
- Sandbox page **MBTI Roles**: Enable, Role XP, Penalty, Type XP, Research speed, Mood strength, **Show start popup**  
- Start popup: opaque collapsable window, **X to close**, shows live sandbox-scaled stats for **this character**  
- Trait tooltips: **static defaults only** + note that Sandbox changes live numbers (live `setDescription` failed — `%` / formatting became `?`)

### Config layer
- `MBTI_Config.lua` reads `SandboxVars.MBTIRoles`  
- XP/research/mood all go through config scaling  

---

## 4. Key files (implementation map)

```
media/registries.lua
media/scripts/MBTIRoles_Traits.txt
media/sandbox-options.txt
media/lua/shared/MBTIRoles/
  MBTI_Data.lua      — roles, types, RoleEffects, TypeEffects
  MBTI_Config.lua    — sandbox 0–25%
  MBTI_Player.lua    — trait scan, modData.MBTIRoles
  MBTI_XP.lua        — Events.AddXP
  MBTI_Research.lua  — ISResearchRecipe duration
  MBTI_Mood.lua      — picture/memento/research/harvest/forage/brochure
media/lua/client/MBTIRoles/
  MBTI_CharacterInfo.lua  — char screen label
  MBTI_StartPopup.lua     — game-start summary window
media/lua/shared/Translate/EN/
  UI_EN.txt, UI.json, Sandbox_EN.txt, Sandbox.json
media/ui/Traits/trait_*.png
docs/DESIGN-LOCK.md
docs/PROJECT-UPDATE-FOR-GROK.md  (this file)
```

**Player modData:** `player:getModData().MBTIRoles`  
`{ roleId, typeCode, typeName, roleName, complete, ... }`

---

## 5. Hard constraints for future ideas

1. **Stay standalone** for core MVP — optional soft-compat only (More Traits, KillCount, New Music, etc.).  
2. **Mild power** — personality, not meta builds. Prefer mood / small XP / pacing over damage, free loot, or free skills.  
3. **B42 APIs:** `CharacterTrait.register`, `character_trait_definition`, `hasTrait(registry)`, `CharacterStat`, timed-action hooks. Cost 0 traits **do not show** in chargen.  
4. **UI text:** Prefer ASCII in translations. Use `%%` in getText strings for `%`. Avoid injecting live `%` into tooltips via `setDescription` (breaks → `?`). Start popup uses **“pct”** wording for safety.  
5. **Role identity:** new effects should feel like Analyst / Diplomat / Sentinel / Explorer — not random buffs.  
6. **Sandbox first:** new strengths should be 0–25% knobs or Off/Weak/Normal when possible.  
7. **MP:** Prefer authority-safe hooks; mood/XP already patterned after More Traits-style `AddXP` / complete hooks.

---

## 6. Design leftovers (good seeds for updates)

From original design lock, **not** fully built:

| Idea | Role | Notes |
|------|------|--------|
| Routine mood when well-fed + rested | Sentinel | Passive EveryTenMinutes |
| Stress/boredom when starving/exhausted long | Sentinel | Mild |
| Empathy: extra panic/unhappiness from gore/kills | Diplomat | Optional downside |
| Help others (bandaging others) happiness | Diplomat | MP-friendly if careful |
| Alone comfort / social comfort type flags | Types | INTJ aloneComfort, ENFJ socialComfort — data flags exist, little/no live logic |
| Music/radio happiness if New Music stack | ESFP soft | Soft-compat, no hard require |
| Outdoor daytime mild happiness | ISFP / Explorer | Passive |
| Mid-game Role/Type change | System | Sandbox + rare book/event |
| Dynamic type from playstyle (KillCount etc.) | P4 | Optional module |
| Custom Role→Type chargen UI | System | Still trait-list based |

---

## 7. Brainstorm lanes for later updates (ask Grok to expand these)

When brainstorming, group ideas into **lanes** and rate: *fit / fun / balance / B42 feasibility*.

### A. Deeper type identity (16 flavors)
- One **unique** micro-hook per type (mood trigger, small recipe freebee, dialogue flavor, context menu “reflect”)  
- Keep power tiny; emphasize *when* it procs over *how strong*  

### B. Passive / lifestyle mood
- Sentinel: tidy base, full fridge, generators online  
- Explorer: distance walked outdoors, new cells visited  
- Analyst: time spent reading skill books / researching  
- Diplomat: near other players, radio on, looking after animals  

### C. Soft system links (optional mods)
- New Music / True Music Jukebox  
- Lifestyle / hobbies  
- Farming expansions  
- Never hard-require  

### D. Progression / meta (careful)
- Unlock type rename or dual “mask” (cosmetic)  
- Memento collection goal → small permanent mood floor  
- Avoid power creep  

### E. Multiplayer / co-op flavor
- Diplomat aura near faction members  
- Sentinel “base duty” when repairing shared containers  
- Explorer “scout” bonus for first-to-zone  

### F. UX polish
- Keybind to reopen MBTI summary  
- Sandbox “show all 16 types reference” panel  
- Better start popup layout / icons next to Role  
- Workshop description / changelog automation  

### G. Balance tools
- Per-role enable/disable  
- Separate mood cooldowns in sandbox  
- Debug command to print effective mults  

---

## 8. What NOT to pitch (unless re-scoping)

- Full dialogue trees / romance systems as hard core  
- 16 unique skill trees  
- Replacing vanilla professions  
- Hard dependency on More Traits / UCWF  
- Strong combat meta traits  

---

## 9. Prompt you can paste to another Grok Project

```text
You are helping design FUTURE updates for Project Zomboid B42 mod "MBTI Roles" (id MBTIRoles).

Read this project update and DESIGN constraints carefully.

Current version 0.4.8 is playable:
- Role then Type chargen (4 roles x 4 types)
- Mild Role/Type XP, mood hooks, Analyst research speed
- Sandbox 0-25% knobs, start popup, custom icons
- Standalone, no hard deps

TASK: Propose a roadmap of 8–15 update ideas for later patches.
For each idea include:
1) Name / patch bucket (v0.5 / v0.6 / polish)
2) Which Role(s)/Type(s) it serves
3) Player fantasy (one sentence)
4) B42 implementation sketch (events/hooks/files)
5) Balance risk (low/med/high) and sandbox control
6) Why it fits "personality not superpowers"

Prefer mild mood/XP/pacing. Flag anything that needs optional mod soft-compat.
Do not redesign the Role→Type structure.
```

---

## 10. Status one-liner

**MBTI Roles 0.4.8 is a complete first release of the locked Role→Type system with sandbox-scaled XP/mood/research, start summary UI, and art. Next work is iterative content and identity depth, not re-architecture.**
