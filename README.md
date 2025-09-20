# 📚 Repetify - Learn words. Keep them forever.

Repetify ist ein moderner Vokabeltrainer, der mit Ruby on Rails entwickelt wurde.
Eine Rails-Anwendung zum Lernen von Vokabeln mit Bootstrap-Design und Benutzerauthentifizierung.

## Tech Stack

- Ruby on Rails 8
- Bootstrap 5
- Devise (Authentifizierung)
- SCSS für eigene Styles
- Postgres DB als Datenbank

# 🚀 Lokale Installation

## 1. Repository klonen

```bash
git clone https://github.com/lorenzboss/m223_repetify.git
cd m223_repetify
```

## 2. Dependencies installieren

```bash
# Ruby Gems
bundle install

# Node.js Dependencies (für CSS-Kompilierung)
npm install
```

## 3. Master Key, Credentials und Datenbank einrichten

### Option A: Bestehende Credentials verwenden

Stelle sicher, dass der Master-Key in der Datei `config/master.key` existiert und der Inhalt korrekt ist.

### Option B: Eigene API-Keys und Datenbank verwenden

Generiere einen neuen Master Key

```bash
rails credentials:edit
```

Füge deine API-Keys und Datenbank-URL im geöffneten Editor hinzu:

```text
neon:
  database_url: postgresql://YOUR_DB_URL_HERE

deepl:
  api_key: YOUR_DEEPL_API_KEY_HERE
```

Falls du die Datenbank neu erstellt hast, musst du sie migrieren:

```bash
rails db:migrate
```

# 🏃‍♂️ Server starten

### Development mit CSS-Watching (empfohlen):

Startet Rails-Server und überwacht SCSS-Änderungen automatisch.

```bash
bin/dev
```

### Nur Rails-Server:

Startet nur den Rails-Server ohne SCSS-Watching.

```bash
rails server
```

**SCSS-Änderungen übernehmen:** Wenn du nur `rails server` verwendest, musst du SCSS-Änderungen manuell kompilieren:

```bash
npm run build:css
```

**Anwendung läuft auf:** http://localhost:3000

# 📁 Wichtige Dateien

- `app/assets/stylesheets/app.scss` - Eigene SCSS-Styles
- `app/views/layouts/application.html.erb` - Haupt-Layout
- `config/routes.rb` - URL-Routing
- `Procfile.dev` - Development-Prozesse
