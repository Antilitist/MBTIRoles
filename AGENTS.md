# MBTI Roles — agent notes

## Paths (active)

| Role | Path |
|------|------|
| Source of truth | `F:\Grok\Nipsy\MBTIRoles\` |
| Local play mods | `X:\Users\USER\Zomboid\mods\MBTIRoles\` |
| Workshop package | `X:\Users\USER\Zomboid\Workshop\MBTIRoles\` |
| Zomboid cache | `X:\Users\USER\Zomboid\` (`-cachedir=X:\Users\USER\Zomboid`) |

**Do not deploy to `X:\Users\USER\Zomboid\`** for live play — user moved cache to F:.

After code changes, run:

```powershell
powershell -ExecutionPolicy Bypass -File "F:\Grok\Nipsy\MBTIRoles\package-workshop.ps1"
```

That syncs `common` → `42` → F: live mods → F: Workshop package.
