# Design: Umbau von `claude-base` zum Claude-Code-Plugin

## Zusammenfassung

`claude-base` wird von einem script-basierten Verteilungsmechanismus (`setup.sh` kopiert
Inhalte in das `.claude/` eines Zielprojekts) zu einem **Mono-Plugin** umgebaut, das über
einen **Marketplace** im selben Repo verteilt wird. Projekte installieren künftig mit
`/plugin install claude-base@open-elements` und aktualisieren per Version-Bump statt über
ein eigenes Copy-Script.

Der Umbau ersetzt die selbstgebaute Verteil-Maschinerie (Copy-/Flatten-/Path-Rewrite-Logik,
Git-Tag-Cloning) durch Standard-Plugin-Mechanik. **Bewusst nicht mehr abgebildet** werden
(auf Wunsch des Nutzers) das intelligente Mergen der Basis-`CLAUDE.md`, das Ergänzen der
Ziel-`.gitignore` und das Ausrollen von `settings.local.json` — diese kann ein Plugin
prinzipbedingt nicht leisten und sie entfallen ersatzlos.

Einziger UX-Tradeoff: Skills werden namespaced (`/spec-create` → `/claude-base:spec-create`).

---

## Ausgangslage

Das Repo enthält heute:

- **45 Skills** in 6 Kategorien (`coding/`, `information/`, `open-elements/`, `other/`,
  `tools/`, `workflows/`) unter `claude-project-base/skills/<kategorie>/<name>/SKILL.md`
  - davon 34 Open-Elements-Original-Skills, 11 aus Upstream-Repos vendored
- **2 Konventions-Dokumente** (`conventions/security.md`, `conventions/software-quality.md`),
  referenziert von 7 Skills über relative Pfade
- **`.mcp.json`** mit 3 Servern (hedera-docs, docker, maven-central)
- **Basis-`CLAUDE.md`** (`PROJECT_CLAUDE.md`) mit „Project Context"-Sektion → wird gemergt
- **`.gitignore`-Ergänzungen**, **`settings.local.json`**
- **`setup.sh`** — verteilt Inhalte in Projekte (flatten, path-rewrite, CLAUDE.md-merge)
- **`update-skills.sh`** — zieht vendored Skills aus deren Upstream-Repos *in* dieses Repo

### Wichtige Unterscheidung: zwei getrennte Datenflüsse

| Script | Richtung | Schicksal beim Umbau |
|:--|:--|:--|
| `setup.sh` | Repo → Zielprojekt (Verteilung) | **wird durch Plugin ersetzt** |
| `update-skills.sh` | Upstream → Repo (Vendoring) | **bleibt unverändert** — orthogonal zum Plugin |

`update-skills.sh` hat nichts mit der Verteilung zu tun und bleibt bestehen.

---

## Zielstruktur

Das Plugin liegt im Wurzelverzeichnis des Repos (Marketplace im selben Repo):

```
claude-base/
├── .claude-plugin/
│   ├── plugin.json          # Manifest (name, version, author, description, mcpServers-Pfad)
│   └── marketplace.json     # Katalog mit einem Eintrag → dieses Plugin
├── skills/                  # 45 Skills, FLACH (Kategorien aufgelöst)
│   ├── spec-create/
│   ├── java-best-practices/
│   └── ...
├── conventions/             # security.md, software-quality.md
├── .mcp.json                # 3 MCP-Server (aus altem claude-project-base/.mcp.json)
├── CHANGELOG.md             # SemVer-Historie
├── update-skills.sh         # bleibt (Vendoring)
├── docs/design/             # dieses Dokument
└── README.md                # Doku aktualisiert auf Plugin-Installation
```

### Entscheidungen im Detail

**Skills flach.** Plugins entdecken Skills unter `skills/<name>/`. Die Kategorie-Ebene
(`coding/`, `workflows/`, …) entfällt. Da Skill-Namen bereits eindeutig sind (Flatten
passiert heute schon in `setup.sh`), sind keine Kollisionen zu erwarten.

**Konventionen im Plugin gebündelt.** `conventions/` liegt im Plugin-Root. Skills
referenzieren sie über `${CLAUDE_PLUGIN_ROOT}/conventions/…`. Das **ersetzt das heutige
Path-Rewriting** (`../../../conventions/` → `../../conventions/`), das damit ersatzlos
entfällt. Die 7 referenzierenden SKILL.md-Dateien werden einmalig angepasst.

**MCP nativ.** `.mcp.json` wird zum Plugin-Root kopiert und automatisch geladen. Projekte,
die einen Server nicht wollen, deaktivieren ihn — kein manuelles Entfernen mehr nötig.

**`claude-plugin-builder-workspace` NICHT ausliefern.** Dieser Ordner ist Eval-/Dev-
Scaffolding und gehört nicht ins Plugin. Er verbleibt außerhalb von `skills/` bzw. wird
über den Skill-Discovery-Pfad ausgeschlossen.

---

## Marketplace & Versionierung

**Marketplace im selben Repo** (`.claude-plugin/marketplace.json`), Quelle des Plugins ist
der relative Pfad `./` (das Repo-Root ist das Plugin). Nutzer registrieren einmalig:

```bash
/plugin marketplace add OpenElementsLabs/claude-base
/plugin install claude-base@open-elements
```

**Versionierung:** explizite `version` in `plugin.json` nach SemVer. Updates werden nur bei
Version-Bump ausgeliefert → jede Release-PR muss `version` erhöhen und `CHANGELOG.md`
pflegen. (Alternative „version weglassen → Commit-SHA als Version" wird *nicht* gewählt,
da für ein geteiltes, versioniertes Setup explizite Releases besser sind.)

Die bestehenden Git-Tags (`vX.Y.Z`), die `setup.sh` heute für das Cloning nutzt, bleiben
als Release-Marker sinnvoll und passen zur `version` im Manifest.

---

## Migration von `setup.sh`

`setup.sh` wird **auf einen dünnen Hinweis reduziert**: statt der Copy-Maschinerie gibt es
nur noch eine kurze Nachricht, die auf die Plugin-Installation verweist (Marketplace
hinzufügen + `/plugin install`). So bricht ein bestehender `curl … | bash`-Aufruf nicht
hart, sondern leitet Nutzer auf den neuen Weg. Die bisher darin enthaltene Logik
verschwindet:

| `setup.sh`-Funktion | Nach Umbau |
|:--|:--|
| Skills kopieren + flatten | Plugin-Discovery (nativ) |
| Konventions-Pfade rewriten | entfällt (`${CLAUDE_PLUGIN_ROOT}`) |
| `.mcp.json` kopieren | Plugin lädt `.mcp.json` nativ |
| CLAUDE.md mergen | **entfällt** (bewusst verworfen) |
| `.gitignore` ergänzen | **entfällt** (bewusst verworfen) |
| `settings.local.json` ausrollen | **entfällt** (bewusst verworfen) |
| Git-Tag-Cloning | Marketplace-Install |

Das projektseitige Update (heute via `update-claude-base`-Skill) wird durch
`/plugin update` bzw. Version-Bump ersetzt.

---

## Offene Punkte / Risiken

1. **Namespacing-Umgewöhnung.** Alle Kommandos heißen künftig `/claude-base:<name>`.
   Doku (README, evtl. Skill-Querverweise) muss angepasst werden.
2. **Konventionen sind nicht mehr „always-on".** Sie werden nur noch von Skills
   referenziert, nicht als globaler Kontext geladen. Das ist Folge des Plugin-Modells und
   vom Nutzer akzeptiert.
3. **Skill-interne Querverweise** auf andere Skills/Pfade prüfen — nach dem Flatten müssen
   relative Verweise weiterhin stimmen (v. a. `_workflow-shared/`).
4. **`claude plugin validate --strict`** in CI aufnehmen, um Manifest/Frontmatter/Pfade
   dauerhaft grün zu halten.
5. **Repo-Layout-Bruch:** `claude-project-base/` als Zwischenordner entfällt; Inhalte
   wandern ins Repo-Root. Das ist ein größerer, aber einmaliger Umbau.

---

## Umsetzungsschritte (Vorschlag, nach Freigabe)

1. `plugin.json` + `marketplace.json` in `.claude-plugin/` anlegen.
2. `skills/` flach ins Repo-Root ziehen (Kategorien auflösen), `conventions/` und
   `.mcp.json` ins Root.
3. 7 SKILL.md-Konventions-Referenzen auf `${CLAUDE_PLUGIN_ROOT}/conventions/…` umstellen.
4. `claude-plugin-builder-workspace` aus dem Skill-Pfad ausschließen.
5. `setup.sh` auf einen dünnen Plugin-Hinweis reduzieren; `update-skills.sh` belassen.
6. `README.md` + `CHANGELOG.md` auf Plugin-Installation umschreiben.
7. `claude plugin validate --strict` lokal + in CI.
8. Ersten Release taggen und Marketplace-Install einmal durchtesten.

---

## Umsetzungsnotizen (Stand: durchgeführt auf `feature/convert-to-plugin`)

Konkrete Entscheidungen, teils leicht abweichend vom obigen Plan:

- **Plugin-Version:** `0.11.0` (nächster Minor nach Tag `v0.10`), gesetzt in `plugin.json`
  *und* im Marketplace-Eintrag.
- **Marketplace-Name:** `open-elements`; Plugin-Name `claude-base`; Source `"./"`
  (Repo-Root ist zugleich Plugin- und Marketplace-Root). `skills/` und `.mcp.json`
  werden automatisch entdeckt — keine expliziten Component-Felder nötig.
- **`.mcp.json`:** die 8-Server-Distributions-Config (vormals `claude-project-base/.mcp.json`)
  liegt jetzt am Root und dient sowohl als Plugin-MCP als auch als Dev-Config dieses Repos.
  Die frühere 3-Server-Dev-`.mcp.json` am Root wurde damit ersetzt. Server ohne
  gesetzte Env-Vars starten einfach nicht.
- **`automated-spec-implementation-prompt.md`:** ist eine Ressource von `roadmap-execute`
  und wurde in dessen Skill-Ordner verschoben; die Referenz zeigt jetzt auf
  `${CLAUDE_PLUGIN_ROOT}/skills/roadmap-execute/automated-spec-implementation-prompt.md`.
- **`dev/`:** `claude-plugin-builder-workspace` (Eval-Scaffolding) → `dev/`; die alte
  Basis-`CLAUDE.md`-Vorlage (`PROJECT_CLAUDE.md`) → `dev/legacy/` (Inhalt bewahrt, Feature
  entfällt). Nichts unter `dev/` ist als Skill auffindbar.
- **Aufgeräumte Alt-Inkonsistenzen:** Ordner `java-best-pratices` → `java-best-practices`
  (Tippfehler); Frontmatter-Name des `java-api-design`-Skills von `api-design` →
  `java-api-design` (passt jetzt zu Ordner und Doku).
- **Gelöscht:** `PROJECT_GITIGNORE_ADDITITIONS`, `settings.local.json`-Vorlage
  (Features entfallen).
- **`docs/workflow-skills.md`:** vormals `skills/workflows/README.md`; interner Link auf
  `_workflow-shared` korrigiert.
- **Repo-eigene `CLAUDE.md`** auf das Plugin-Layout aktualisiert.
- **Verifiziert:** `claude plugin validate ./ --strict` grün; `claude --plugin-dir ./`
  lädt alle 43 Skills korrekt namespaced (`/claude-base:<name>`).
