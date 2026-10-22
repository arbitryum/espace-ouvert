# Espaces Ouverts

Web application that lets care homes (EHPAD) publish the spaces they open to
nonprofit organizations, and lets those organizations browse them. A second
track, coworking, lists projects hosted in care homes and offers establishments
a private guide.

Rails 8.1, PostgreSQL, Hotwire (Turbo + Stimulus, importmap), Tailwind CSS 4
with daisyUI 5, Active Storage on Scaleway, and
[Madmin](https://github.com/excid3/madmin) for the back office. Hosted on
Scalingo. The interface is in French.

**Before changing anything, read [AGENTS.md](AGENTS.md)**: code rules,
architecture, known pitfalls, Git and deploy workflow.

## Pages

| Path | Page |
| --- | --- |
| `/` | Home, choose between the two tracks |
| `/spaces`, `/spaces/:id` | Space directory (list or map, filters) and detail |
| `/coworking`, `/coworking/projets` | Coworking home and published projects |
| `/coworking/guide` | Coworking guide, readable after requesting access by email |
| `/comptes/inscription`, `/comptes/connexion` | Establishment sign-up and sign-in |
| `/comptes/mot-de-passe/oublie` | Password reset by emailed link |
| `/admin` | Back office (admins only) |

## Domain

| Model | What it is |
| --- | --- |
| `CareHome` | A care home; its address is geocoded into an `Address` (`address_details`). |
| `Address` | Geocoded address with coordinates and a normalized `search_text`. |
| `Space` | A space offered by a care home, with `images` (`SpaceImage`) and weekly `recurring_availabilities`. |
| `CoworkingProject` | A coworking project, optionally hosted by a care home. |
| `User` / `EhpadProfile` | An establishment account, which signs in with its email. It can sign in once an admin approves its profile; admins (`users.admin`) can always sign in. |
| `GuidePage` / `GuideReader` | Pages of the coworking guide, and the people who requested access by email. |
| `NonprofitOrganization` | Not used by any page yet. |

Notable code:

- `SpaceSearch` (app/models): filters of the space directory (care home, free-text location, distance around a point).
- `EhpadRegistration` (app/models): sign-up form creating the user and its pending profile.
- `Geocoder` (app/services): Nominatim (OpenStreetMap) client, for care home addresses.
- `Places` (app/services): geo.api.gouv.fr client for the location box of `/spaces`: suggests French communes and departments, and finds the commune of a typed place.
- `GuideImport` (app/services): imports the guide from a Notion export.
- `GuideAccess` (controller concern): who may read the guide.
- Stimulus controllers (app/javascript/controllers): carousel, Leaflet map, location filter, password visibility and rules.

## Setup

Requirements: Ruby (see `.ruby-version`) and PostgreSQL running locally. No
Node.js: Tailwind runs through `tailwindcss-rails` and daisyUI is vendored.
libvips is needed locally to resize photos (`brew install vips`).

```sh
bin/setup        # installs gems, prepares the database, starts the server
bin/dev          # web server + Tailwind watcher on http://localhost:3000
```

Create an admin to use `/admin`:

```sh
bin/rails runner 'User.create!(email_address: "admin@example.com", password: "…", admin: true)'
```

In development, emails are written to `tmp/mails/` instead of being sent.

## Data

Sample data: `bin/rails db:seed`, or one part at a time:

- `bin/rails seed:spaces`: **replaces** all care homes and spaces with `lib/seeds/spaces.yml`, geocodes them, and attaches the photos found in `SEED_IMAGES_DIR` (default `tmp/seed_images`, not versioned).
- `bin/rails seed:coworking`: creates or updates three coworking projects.
- `bin/rails seed:availability`: adds weekly slots to some spaces.
- `bin/rails geocode:care_homes` (`FORCE=1` to redo all): geocodes care homes without coordinates.
- `bin/rails spaces:parse_availability`: reads each space's free-text availability into weekly slots, the ones the directory filters by day and moment. Prints the proposals and the guesses it made ("à partir de 17h" ends at 22h, "toute la journée" is 9h–18h…); `APPLY=1` writes them, `REPLACE=1` also replaces spaces' existing slots.
- `bin/rails images:variants`: generates the resized WebP versions of space photos (new uploads get them automatically).
- `bin/rails guide:import DIR="path/to/Notion export"`: **replaces** the coworking guide with a Notion "HTML" export.

## Coworking guide

The guide isn't public:
- Visitors give their email, saved as a `GuideReader` and listed in
  `/admin/guide_readers`.
- They receive a link, valid 7 days, that lets their browser read the guide.
- Signed-in users can read it directly.
- Images are served through `GuideImagesController`, which checks access and
  redirects to storage URLs expiring after 5 minutes.

## Tests

```sh
bin/ci           # Standard, audits, Brakeman and tests: the same checks as CircleCI
bin/rails test
```

CircleCI runs them on every push (`.circleci/config.yml`).

## Deployment

Merging to `main` deploys the Scalingo app `espaces-ouverts-production`.

- **Build:** the APT buildpack installs libvips from `Aptfile`, then the Ruby
  buildpack runs (`.buildpacks`).
- **Run:** `Procfile` starts Puma and runs the migrations on `postdeploy`.
- **Photos:** stored on Scaleway Object Storage (Active Storage `scaleway`
  service, `config/storage.yml`).
- **Emails:** sent through Brevo's SMTP relay, from `no-reply@arbitryum.fr`.
  Brevo only accepts SMTP from allowlisted IPs, so Scalingo's egress IPs must
  stay authorized there.

Environment variables are listed in [.env.example](.env.example).

### Production tasks

Data tasks run from a local checkout against the production database, through a
tunnel. Open the tunnel in one terminal:

```sh
scalingo --app espaces-ouverts-production db-tunnel --port 10001 SCALINGO_POSTGRESQL_URL
```

Then run the task in another, reading credentials from Scalingo so none are
typed or printed. For example, to import the guide:

```sh
RAILS_ENV=production SECRET_KEY_BASE=dummy ACTIVE_STORAGE_SERVICE=scaleway AWS_STORAGE_BUCKET_NAME=espaces-ouverts-production DATABASE_URL="$(scalingo -a espaces-ouverts-production env-get SCALINGO_POSTGRESQL_URL 2>/dev/null | sed -E 's#@[^/]+/#@127.0.0.1:10001/#')" AWS_ACCESS_KEY_ID="$(scalingo -a espaces-ouverts-production env-get AWS_ACCESS_KEY_ID 2>/dev/null)" AWS_SECRET_ACCESS_KEY="$(scalingo -a espaces-ouverts-production env-get AWS_SECRET_ACCESS_KEY 2>/dev/null)" bin/rails guide:import DIR="path/to/Notion export"
```

Tasks that only need the app's own environment can run in a Scalingo container
instead:

```sh
scalingo --app espaces-ouverts-production run bin/rails images:variants
```
