# MBTI Roles — Design Lock

**Status:** LOCKED (P3 sandbox + type XP)  
**Date:** 2026-08-15  
**Target:** Project Zomboid B42  
**Mod id:** `MBTIRoles`  
**Impl version:** 0.4.3 (P3 Type XP + sandbox 0–25%; trait tooltips = defaults only)

---

## 1. Chargen flow (locked)

1. Player picks **one Role** (exclusive):  
   **Analyst** · **Diplomat** · **Sentinel** · **Explorer**
2. Player picks **one Type** from the **four types in that role** (exclusive).
3. Character always ends with exactly **one Role + one Type** → full MBTI code.

No free mix of E/I S/N T/F outside this flow.  
No second type. Role and type are permanent for MVP (sandbox option later for mid-game change).

---

## 2. Role → type map (locked)

| Role | Pattern | Types |
|------|---------|--------|
| **Analyst** | ·NT· | **INTJ**, **INTP**, **ENTJ**, **ENTP** |
| **Diplomat** | ·NF· | **INFJ**, **INFP**, **ENFJ**, **ENFP** |
| **Sentinel** | ·SJ | **ISTJ**, **ISFJ**, **ESTJ**, **ESFJ** |
| **Explorer** | ·SP | **ISTP**, **ISFP**, **ESTP**, **ESFP** |

### Letter meaning (reference only)

| Letter | Meaning |
|--------|---------|
| E / I | Extraversion / Introversion |
| S / N | Sensing / Intuition |
| T / F | Thinking / Feeling |
| J / P | Judging / Perceiving |

---

## 3. Effect layers (locked)

| Layer | Scope | Strength |
|-------|--------|----------|
| **Role** | Shared by all 4 types in the group | Medium (2–3 effects) |
| **Type** | Fine-tune within the role | Small (1–2 effects) |

Total power should stay mild — personality, not a free profession.

---

## 4. Role bonuses (locked MVP)

Effects are **directional**; exact numbers live in sandbox (defaults below).

### Analyst (INTJ / INTP / ENTJ / ENTP)
- **+** Electrical / Mechanics / Tailoring *or* Reading XP (abstract/systems)
- **+** Faster **recipe research** timed action (vanilla `ISResearchRecipe`)
- **+** Literature XP bias (books / learning feel)
- **−** Slightly worse Foraging XP (less “present-moment” sensing)

*Default MVP numbers:*  
+15% XP Electrical & Mechanics · +10% Literature XP · −10% Foraging XP · **research duration ×0.85** · **research mood** (−6 unhappiness / −8 boredom / −4 stress, 0.25h CD)

### Diplomat (INFJ / INFP / ENFJ / ENFP)
- **+** First Aid / Lightfoot *or* Literature XP (people/meaning)
- **+** **Mood boost from pictures/photos** (look-at picture / picture books) — live
- **+** **Mood boost from mementos** (greeting cards, keepsakes; hold or read) — live
- **+** Mild unhappiness reduction when helping (first aid on others) — *later if hard*
- **−** Slightly more panic from gore *or* slower panic recovery (empathy cost)

*Default MVP numbers:*  
+15% First Aid XP · +10% Literature XP  
· pictures: **−8 unhappiness, −5 boredom, −3 stress** (0.5h CD)  
· mementos: **−7 unhappiness, −5 boredom, −4 stress** (0.5h CD; equip/hold or read non-picture mementos)

### Sentinel (ISTJ / ISFJ / ESTJ / ESFJ)
- **+** Farming / Maintenance / Cooking XP (sustain, duty)
- **+** **Mood from harvesting crops** (garden payoff) — live
- **+** Mild unhappiness reduction when well-fed + rested (routine OK) — later
- **−** Mild boredom increase when starving/exhausted prolonged (routine broken) — later

*Default MVP numbers:*  
+15% Farming & Maintenance XP · harvest mood (−6 unhappiness / −4 boredom / −5 stress, 0.35h CD)

### Explorer (ISTP / ISFP / ESTP / ESFP)
- **+** Foraging / Trapping / Sprinting *or* Aiming XP (now, body, field)
- **+** **Mood from reading Brochures & Fliers** (primary) — live
- **+** **Small mood from forage finds** — live
- **+** Slight run endurance / less endurance drain when moving (small) — later
- **−** Slightly worse Literature / long craft book XP

*Default MVP numbers:*  
+15% Foraging XP · +10% Aiming XP · −10% Literature XP  
· brochure/flier mood (−7 unhappiness / −10 boredom / −4 stress, 0.35h CD)  
· forage mood small (−2 / −3 / −1, 0.5h CD)

---

## 5. Type tweaks (locked MVP)

One primary tweak per type. Keep tiny.

### Analysts
| Type | Tweak |
|------|--------|
| **INTJ** | +5% Mechanics XP; slightly less unhappiness alone |
| **INTP** | +5% Electrical XP; slightly more boredom in combat downtime |
| **ENTJ** | +5% Strength or Maintenance XP; slight noise/meta “leadership” later |
| **ENTP** | +5% short-action craft speed feel (or +5% Scrap/Metal XP); slight unhappiness from idle |

### Diplomats
| Type | Tweak |
|------|--------|
| **INFJ** | +5% First Aid; less unhappiness when reading |
| **INFP** | +5% Literature; more unhappiness when very bloody/gore (mild) |
| **ENFJ** | +5% First Aid; small happiness near other players (MP) / radio on (SP proxy) |
| **ENFP** | +5% Foraging or Nimble; more boredom when stuck indoors long |

### Sentinels
| Type | Tweak |
|------|--------|
| **ISTJ** | +5% Maintenance; unhappiness if inventory over capacity often (optional/hard) |
| **ISFJ** | +5% First Aid or Cooking; small heal to unhappiness when bandaging self |
| **ESTJ** | +5% Blunt or Strength XP; slight panic reduction in fights |
| **ESFJ** | +5% Cooking; small unhappiness reduction near planted crops / base |

### Explorers
| Type | Tweak |
|------|--------|
| **ISTP** | +5% Short Blade or Mechanics; less panic alone outdoors |
| **ISFP** | +5% Foraging; slight happiness from nature (outdoor daytime mild) |
| **ESTP** | +5% Aiming or Sprint; slight extra noise when running (optional) |
| **ESFP** | +5% Lightfoot; happiness from music/radio if New Music stack present (soft) |

*If an effect is awkward on B42 API, replace with XP bias of same flavor — do not block release.*

---

## 6. Trait / data model (locked)

### Role traits (4, exclusive) — B42.20 registry keys
- `MBTIRoles:Analyst`
- `MBTIRoles:Diplomat`
- `MBTIRoles:Sentinel`
- `MBTIRoles:Explorer`

### Type traits (16, exclusive; each grants its role)
- `MBTIRoles:INTJ` … `MBTIRoles:ESFP` (full list in `registries.lua` / `MBTIRoles_Traits.txt`)

**Rules:**
- Exactly one role, exactly one type (type alone is enough — `GrantedTraits` adds role).
- Type trait grants matching role; exclusive vs other types + non-matching roles.
- Cost: **1 point** each in P1 (B42 chargen only lists traits with cost > 0 or cost < 0; Cost=0 never appears). Sandbox point cost later.
- Mutually exclusive within roles and within types.
- Runtime sync: `MBTI_Player.syncFromTraits` → `player:getModData().MBTIRoles`.

### Derived display
```text
typeCode = e.g. "INTJ"
roleId   = e.g. "Analyst"
```
Stored in `player:getModData().MBTIRoles` for UI and saves.

---

## 7. Dependencies (locked)

| Dependency | Required? |
|------------|-----------|
| Vanilla B42 | **Yes** |
| More Traits | **No** (optional soft-compat later) |
| KillCount | **No** for MVP (dynamic type = phase 2) |
| Profession Framework | **No** for MVP |

MVP = standalone mod.

---

## 8. Sandbox (P3 — live)

Page **MBTI Roles** — all percent knobs **0–25**:

| Option | Default | Notes |
|--------|---------|--------|
| Enable MBTI system | true | Off = no XP/mood/research effects |
| Role XP bonus % | 15 | Primary role skill bonus; secondary scales with this |
| Role XP penalty % | 10 | Role debuffs (e.g. −Foraging) |
| Type XP bonus % | 5 | Per-type fine-tune skill |
| Analyst research speed % | 15 | Shorter research duration |
| Mood effect strength % | 15 | Scales all mood deltas (15 = design baseline) |

---

## 9. Out of scope (MVP)

- Dynamic type change from playstyle  
- Full dialogue / romance / NPC AI  
- 16 unique skill trees  
- Hard requirement on More Traits / UCWF  
- Changing vanilla professions  

---

## 10. Implementation phases

| Phase | Deliverable |
|-------|-------------|
| **P0 — Locked** | This document + data tables in code — **done** |
| **P1** | Traits + chargen validation + character info display — **done** |
| **P2** | Role XP modifiers live — **done** |
| **P3** | Type XP + sandbox 0–25% — **done (0.4.0)** |
| **P4** | Optional KillCount dynamic flavor |

---

## 11. File layout (mod)

```
MBTIRoles/
  42/mod.info + media/   (mirrored from common for B42 load)
  common/media/
    registries.lua
    scripts/MBTIRoles_Traits.txt
    lua/shared/MBTIRoles/MBTI_Data.lua
    lua/shared/MBTIRoles/MBTI_Player.lua
    lua/shared/MBTIRoles/MBTI_XP.lua   -- P2 Role XP
    lua/client/MBTIRoles/MBTI_CharacterInfo.lua
    ui/Traits/trait_*.png
  docs/DESIGN-LOCK.md
```

---

**Sign-off:** Role groups + four types each + role/type effect layers locked as above. Numbers may be tuned in sandbox without changing structure.
