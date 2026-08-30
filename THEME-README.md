# Jellyfin Container — Theme & Branding (Stand 2026-08-16)

## Aktuelles Theme: "Aurora Noir"

Cinematic Dark Theme (Aurora-Cyan -> Indigo auf #050810), ersetzt das alte
"Cyberpunk Neon"-Theme (das 2 MB Base64 inline im CSS transportierte).

## Dateien

| Pfad | Zweck |
|---|---|
| `web-assets/aurora_noir.css` | Quelldatei des Themes (SSOT zum Editieren) |
| `web-assets/custom_bg.webp` | Hintergrundbild 1920x1080, ~110 KB |
| `library/branding.xml` | Aktive Konfiguration (CSS XML-escaped eingebettet) |
| `library/branding.xml.bak-20260816` | Rollback des alten Themes |

## Deployment-Pfad

- docker-compose mountet `./web-assets` nach `/usr/share/jellyfin/web/custom-assets:ro`
- Assets sind erreichbar unter: `/web/custom-assets/<datei>` (nicht `/custom-assets/`!)
- CSS-Änderungen: `web-assets/aurora_noir.css` editieren -> XML-escape -> in
  `<CustomCss>` von `library/branding.xml` schreiben -> `docker restart jellyfin`

Regeneration des branding.xml aus der CSS-Datei:

```bash
cd /opt/containers/jellyfin
python3 - <<'PYEOF'
import xml.sax.saxutils as sx
css = open('web-assets/aurora_noir.css').read()
out = ('<?xml version="1.0" encoding="utf-8"?>\n<BrandingOptions>\n'
       '  <LoginDisclaimer>Private media cloud. Authorized access only.</LoginDisclaimer>\n'
       '  <CustomCss>%s</CustomCss>\n'
       '  <SplashscreenEnabled>false</SplashscreenEnabled>\n'
       '</BrandingOptions>\n') % sx.escape(css)
open('library/branding.xml', 'w').write(out)
print('written', len(out))
PYEOF
docker restart jellyfin
```

## Rollback auf altes Theme

```bash
cp /opt/containers/jellyfin/library/branding.xml.bak-20260816 /opt/containers/jellyfin/library/branding.xml
docker restart jellyfin
```

## Verifikation (2026-08-16)

6 UI-Pfade im Browser geprüft (Home, Bibliothek, Album-Detail, Wiedergabe,
Suche, Login): Theme aktiv, keine HTTP-Fehler, Container healthy.
Payload: 10.4 KB statt 2.02 MB (-99.5%).

## Admin-SPA-Theme-Fix (2026-08-16, final implementiert)

Jellyfin 10.11: Die React-Admin-Routen (#/dashboard, #/metadata) entfernen das
Custom-CSS beim Mount. Geloest via Traefik rewritebody-Plugin (router-scoped,
nur am jellyfin-Router, KEIN Eingriff in andere Services):

### Architektur

1. `traefik.yml`: Plugin `github.com/traefik/plugin-rewritebody v0.3.1` registriert
2. `dynamic_conf.yml`: Zwei Middlewares:
   - `jf-no-compress`: stript Accept-Encoding (Plugin überspringt komprimierte Bodies)
   - `jf-inject-theme`: injiziert Watcher-Script vor `</body>`
3. `docker-compose.yml` (jellyfin): Middlewares am Router `jellyfin` (nicht am Login-Router)

### Watcher-Script-Logik (bidirektionale Dedupe)

- Setzt `<link aurora_noir.css>`, wenn weder Link noch Inline-AURORA-style existieren (Admin-Routen)
- ENTFERNT den Link, sobald Legacy-Inline-style erscheint (Legacy-Routen wie Home)
- Re-Injection via MutationObserver + setInterval(1000ms) gegen React-Remounts

### CSS-Updates (wichtig)

Bei CSS-Aenderungen in `aurora_noir.css`:
1. Datei auf VPS aktualisieren + branding.xml regenerieren + `docker restart jellyfin`
2. Cache-Bust im Watcher erhoehen: in `dynamic_conf.yml` beim jf-inject-theme
   Script `aurora_noir.css?v=2` -> `?v=3` setzen + `docker restart traefik`
   (Browser-HTTP-Cache otherwise haelt alte CSS fest)

### MUI-Admin-Styling (2026-08-16, nachgeruestet)

Admin-SPA nutzt MUI-Komponenten - Legacy-Selektoren greifen dort nicht.
`aurora_noir.css` enthaelt eigene `.Mui*`-Override-Sektion (Papers, Cards,
Buttons, Inputs, Tables, Dialogs, Switches, Chips). Verifiziert: 25 MUI-Regeln
aktiv, Paper radius 14px + Aurora-Border, Buttons Aurora-Gradient.

### Verifikation (2026-08-16)

- Test A: Dashboard-Direktload -> Link aktiv, BG gestylt
- Test B: SPA Dashboard->Home -> deduped (nur Legacy-inline, 0 Links)
- Test C: SPA Home->Dashboard -> Link kehrt zurück, BG gestylt
- Test D: Login -> Legacy-Weg unberührt (blur 22px Panel)
- Link-Entfernungs-Angriff: Interval-Watcher stellt Link in <1.5s wieder her
- HTML-Overhead: +620B (Script), CSS nur auf Admin-Routen geladen
- Nachbar-Services: unberührt (gitea 200, home 302, traefik 302)

### Browser-Cache-Hinweis

Nach Änderungen am Watcher-Script: Browser-Cache UND Jellyfin-Service-Worker
leeren (about:reload genügt nicht immer), sonst altes HTML:
`caches.keys().then(ks=>ks.forEach(k=>caches.delete(k)))` + harte Reload-Nav
mit `?v=<timestamp>` Query.

### Rollback

```bash
# Theme-Injection entfernen:
cp /opt/containers/traefik3-crowdsec-stack/traefik/dynamic_conf.yml.bak-jftheme /opt/containers/traefik3-crowdsec-stack/traefik/dynamic_conf.yml
cp /opt/containers/traefik3-crowdsec-stack/traefik/traefik.yml.bak-jftheme /opt/containers/traefik3-crowdsec-stack/traefik/traefik.yml
# compose label zurücksetzen (middlewares-Zeile), dann:
docker restart traefik && cd /opt/containers/jellyfin && docker compose up -d
```
