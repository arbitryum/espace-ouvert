# Working on Espace-ouvert

Rules and context for anyone changing this app, human or agent. The README
describes what the app does and how to run it; this file says how we work on it.

## The app in one paragraph

Rails 8.1 app for care homes (EHPAD). They publish spaces that nonprofit
organizations can browse (`/spaces`), and a coworking track lists projects and a
private guide (`/coworking`). Establishments get accounts that an admin
approves in the back office (Madmin, `/admin`). PostgreSQL, Hotwire (Turbo,
Stimulus, importmap), Tailwind 4 with daisyUI 5, Active Storage on Scaleway.
Hosted on Scalingo. The interface is in French.

## Commands

```sh
bin/dev                          # server + Tailwind watcher, http://localhost:3000
bin/rails test                   # tests (Minitest)
bundle exec standardrb           # Ruby style (--fix to apply)
bin/ci                           # everything CircleCI runs: Standard, audits, Brakeman, tests
```

Run `bin/ci` (or at least the tests and Standard) before opening a PR.

## Code rules

**Style is standardrb.** No RuboCop config of our own; `.standard.yml` only adds
`standard-rails` and one exemption for Madmin's `scope` declarations.

**Every interface text goes through i18n**, never a literal in Ruby, ERB or JS.
- Texts live in `config/locales/*.fr.yml`, one file per area: `accounts`,
  `spaces`, `coworking`, `guides`, `mailers`, `models`, and app-wide `fr.yml`.
- Views and controllers use lazy lookups: `t(".title")` in
  `spaces/index.html.erb` reads `fr.spaces.index.title`. Rails derives partial
  keys without the underscore (`spaces/_space_card` → `spaces.space_card`).
- Mailers don't pass `subject:`; Action Mailer reads `<mailer>.<action>.subject`.
- Enum labels come from `activerecord.enums.<model>.<attribute>.<value>`, through
  `Model.human_enum_name(:status, value)`, `record.human_enum_name(:status)` and
  `Model.human_enum_options(:status)` for selects (see `ApplicationRecord`).
- Validation messages are error keys (`message: :only_digits`) translated under
  `activerecord.errors` / `activemodel.errors`.
- Models don't hold UI text: `SpaceSearch` returns a warning key, and the
  controller translates it.
- Stimulus controllers receive their texts as a `messages` value built with
  `t(...)`; `%{name}` placeholders are filled in JS.
- Missing translations raise in development and test, so a forgotten key fails
  a test or the page.

**Controllers stay thin and read params with strong params.**
- `params.expect(:email_address)` for a single value,
  `params.expect(model: [...])` for a form. A missing parameter becomes a 400.
- Don't clean input by hand: models declare `normalizes` (emails are stripped
  and downcased), and Rails also applies it to finder arguments
  (`User.find_by(email_address:)`).
- Keep conditions simple. Don't assign, call several methods, or chain
  operations inside an `if`. Compute first, then branch:
  ```ruby
  user = User.find_by(email_address: params.expect(:email_address))
  PasswordsMailer.reset(user).deliver_later if user
  ```

**Where code goes:**
- Query and form objects: `app/models` (`SpaceSearch`, `EhpadRegistration`).
- Clients and importers: `app/services` (`Geocoder`, `Places`, `GuideImport`).
- One-off and seed tasks: `lib/tasks`; seed data and classes: `lib/seeds`.
- Shared controller behavior: concerns (`Authentication`, `GuideAccess`).

**Front end:** Tailwind and daisyUI classes in the views. There's no Node.js:
- daisyUI is vendored in `app/assets/tailwind/daisyui.mjs`;
- JavaScript is Stimulus controllers loaded with importmap; add packages with
  `bin/importmap pin`.

The `.agents/skills/daisyui` skill documents daisyUI components.

**Comments explain why**, not what. Match the surrounding code's density.

**Tests:**
- Minitest, with fixtures for users and EHPAD profiles; other records are
  created inline (helpers in `test/test_helper.rb`).
- Stub the network: `Geocoder.stub(:geocode, …)`.
- Tests must not need libvips; CI doesn't have it (see below).

## Things that bit us

- **The app must boot with an empty database.** Scalingo starts the new release
  *before* its `postdeploy` hook runs the migrations. Madmin resources read
  their table's columns when they load, so `config/initializers/madmin.rb`
  keeps them out of eager loading. CircleCI boots the app in production against
  an empty database to catch this kind of failure.
- **Generate image variants through the URL key.** Rails gives a variant's
  in-memory transformations a different digest from the same ones decoded from
  its URL. So `preprocessed: true` and `image.variant(:card).processed` create
  copies that pages never use. Always use `SpaceImage#page_variant` /
  `process_variants!` (what `bin/rails images:variants` and
  `SpaceImageVariantsJob` do).
- **libvips:**
  - production installs it with the APT buildpack (`Aptfile`, `.buildpacks`);
  - CI removes the cimg image's libvips 8.12, because Active Storage refuses
    libvips < 8.13 at boot.
- **`time` columns are wall-clock times**
  (`config.active_record.time_zone_aware_types = [:datetime]`). Weekly slots
  must not shift with the time zone.
- **The coworking guide is private.**
  - Its images go through `GuideImagesController`, which checks access and
    redirects to storage URLs expiring after 5 minutes. Never link a guide
    attachment directly.
  - Page bodies are sanitized at import and again at render, because admins can
    edit them.
- **Emails go through Brevo's SMTP relay** (`smtp-relay.brevo.com`, from
  `no-reply@arbitryum.fr`):
  - Brevo only accepts SMTP from allowlisted IPs, which include Scalingo's
    egress IPs;
  - it rejects unvalidated senders *after* accepting the message, so failures
    only show in Brevo, not in the app;
  - `deliver_later` runs in-process (async adapter);
  - in development, emails are written to `tmp/mails/`.
- **Geocoding** of care home addresses uses OpenStreetMap's Nominatim. Be
  gentle with it, and stub it in tests. Nominatim forbids autocomplete and
  searches the whole world, so the location box of `/spaces` uses
  geo.api.gouv.fr (`Places`) instead.

## Git, CI and deploys

- Branch from a freshly fetched `origin/main` and open a PR to `main`.
  PRs are squash-merged.
- Commit messages and PR titles follow Conventional Commits, in English
  (`feat:`, `fix:`, `refactor:`, `perf:`, `ci:`, `build:`, `docs:`).
- PR descriptions have a summary, then a test plan with what was actually run.
  List the production steps the change needs (environment variables, data
  tasks).
- CI is **CircleCI** (`.circleci/config.yml`): `lint` (Standard, Brakeman,
  bundler-audit, importmap audit), then `rails_test`. GitHub Actions aren't used.
- **Merging to `main` deploys production** (Scalingo app
  `espaces-ouverts-production`): migrations run on `postdeploy`. After a merge,
  check that the deploy succeeded and that `/up` returns 200. A failed deploy
  keeps the previous release running.

## Working with production

- Read configuration with `scalingo --app espaces-ouverts-production env-get VAR`.
  Never print secrets (SMTP key, S3 keys). Set them so they don't show up:
  `env-set VAR="$(pbpaste)" > /dev/null`.
- Run data tasks (imports, cleanups) from a local checkout through a database
  tunnel, using production's storage credentials. See "Production tasks" in the
  README.
- Before anything destructive in production (dropping tables, deleting files,
  purging records): inventory what will go, back it up locally, do a dry run,
  and get an explicit go-ahead.
