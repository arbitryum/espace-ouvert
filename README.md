# Espaces Ouverts

Web application that lets care homes (EHPAD) publish the spaces they open to
nonprofit organizations, and lets those organizations browse them. A second
track, coworking, lists projects hosted in care homes.

Rails 8.1, PostgreSQL, Hotwire (Turbo + Stimulus, importmap), Tailwind CSS 4
with daisyUI 5, Active Storage, and [Madmin](https://github.com/excid3/madmin)
for the back office.

## Domain

| Model | What it is |
| --- | --- |
| `CareHome` | A care home; its address is geocoded into an `Address` (`address_details`). |
| `Address` | Geocoded address with coordinates and a normalized `search_text`. |
| `Space` | A space offered by a care home, with `images` (`SpaceImage`) and weekly `recurring_availabilities`. |
| `CoworkingProject` | A coworking project, optionally hosted by a care home. |
| `User` / `EhpadProfile` | An establishment account. It can sign in once an admin approves its profile; admins (`users.admin`) can always sign in. |
| `NonprofitOrganization` | Not used by any page yet. |

Notable code:

- `SpaceSearch` (app/models): filters of the space directory (care home, free-text location, distance around a point).
- `Geocoder` (app/services): Nominatim (OpenStreetMap) client used for care home addresses and the location autocomplete.
- `EhpadRegistration` (app/models): sign-up form creating the user and its pending profile.
- Stimulus controllers (app/javascript/controllers): carousel, Leaflet map, location filter, password visibility and rules.

## Pages

| Path | Page |
| --- | --- |
| `/` | Home, choose between the two tracks |
| `/spaces`, `/spaces/:id` | Space directory (list or map) and detail |
| `/coworking`, `/coworking/projets` | Coworking home and published projects |
| `/coworking/guide` | Coworking guide, readable after requesting access by email |
| `/comptes/inscription`, `/comptes/connexion` | Establishment sign-up and sign-in |
| `/admin` | Back office (admins only) |

## Coworking guide

The guide's pages (`GuidePage`) are imported from a Notion "HTML" export, which
replaces all of them:

```sh
bin/rails guide:import DIR="path/to/Notion export"
```

The guide isn't public. Visitors give their email (saved as a `GuideReader`) and
receive a link, valid 7 days, that lets their browser read the guide; signed-in
users can read it directly. Images are served through `GuideImagesController`,
which checks access and redirects to storage URLs that expire after 5 minutes.
The emails readers gave are listed in the admin (`/admin/guide_readers`).

In development, emails are written to `tmp/mails/` instead of being sent.
Production sends them through Brevo's SMTP relay, configured in `.env.example`.

## Setup

Requirements: Ruby (see `.ruby-version`), PostgreSQL running locally. No Node.js:
Tailwind runs through `tailwindcss-rails` and daisyUI is vendored in
`app/assets/tailwind/daisyui.mjs`.

```sh
bin/setup        # installs gems, prepares the database, starts the server
bin/dev          # web server + Tailwind watcher on http://localhost:3000
```

Create an admin to use `/admin`:

```sh
bin/rails runner 'User.create!(email_address: "admin@example.com", password: "…", admin: true)'
```

## Data

Sample data: `bin/rails db:seed`, or one part at a time:

- `bin/rails seed:spaces`: **replaces** all care homes and spaces with `lib/seeds/spaces.yml`, geocodes them, and attaches the photos found in `SEED_IMAGES_DIR` (default `tmp/seed_images`, not versioned).
- `bin/rails seed:coworking`: creates or updates three coworking projects.
- `bin/rails seed:availability`: adds weekly slots to some spaces.
- `bin/rails geocode:care_homes` (`FORCE=1` to redo all): geocodes care homes without coordinates.
- `bin/rails images:variants`: generates the resized WebP versions of space photos (new uploads get them automatically).

## Tests

```sh
bin/ci           # Standard, audits, Brakeman and tests: the same checks as CircleCI
bin/rails test
```

CircleCI runs them on every push (`.circleci/config.yml`).

## Deployment

Deployed on Scalingo with the APT and Ruby buildpacks (`.buildpacks`; the APT one
installs libvips from `Aptfile` for image variants). `Procfile`: Puma, and migrations
on `postdeploy`. Uploaded photos go to Scaleway Object Storage through Active
Storage (`scaleway` service in `config/storage.yml`). Environment variables are
listed in `.env.example`.
