# Jellyfin Theme – Aurora Noir

Custom Cinematic Theme für Jellyfin ([stream.free-warez.win](https://stream.free-warez.win)).

---

## 📁 Struktur
- `web-assets/aurora_noir.css`: Quelldatei für das vollständige CSS-Theme (MUI Overrides, Glows, Glassmorphism).
- `web-assets/custom_bg.webp`: Hintergrundgrafik (1920x1080).
- `web-assets/custom_favicon.ico`: Benutzerdefiniertes Favicon.
- `branding.xml`: Jellyfin Server-Konfiguration mit eingebettetem XML-escaped CSS.
- `THEME-README.md`: Detaillierte Architektur & Historie (Traefik rewritebody Injection etc.).
- `deploy.sh`: Synchronisiert die Assets zum VPS, konvertiert CSS -> XML und startet den Jellyfin Container neu.

## 🚀 Deployment
```bash
./deploy.sh
```
