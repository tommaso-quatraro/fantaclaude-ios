# Fantaclaude per iOS

Wrapper nativo minimo (SwiftUI + WKWebView) della web app Fantaclaude: stessa app, ma con una sua icona e senza barre di Safari.
Il codice dell'app sta nell'altro repository (`fantaclaude`); qui c'è solo la finestra nativa.

- **Indirizzo dell'app:** non è nel codice. Variabili del repository `FANTA_HOST` e `FANTA_PORT` (GitHub > Settings > Secrets and variables > Actions > Variables).
- **Compilazione:** GitHub Actions su un Mac (`macos-15`), senza firma, produce `Fantaclaude.ipa` (artifact e release `build-N`). Nessun Mac in casa.
- **Installazione:** SideStore sull'iPhone firma l'IPA con l'Apple ID gratuito e lo rinnova ogni 7 giorni.
- **Limiti noti:** le notifiche web della PWA non passano dentro il wrapper (restano quelle della PWA installata dalla Home); serve Tailscale attivo come per la PWA.
- **Mai in git:** firme, certificati, profili, password, Apple ID.
