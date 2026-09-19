# Petto project structure

The repository root contains project-level automation and the Flutter client.
Application code belongs under `petto_application`; generated output and local
debug artifacts must not be committed.

## Flutter application

```text
petto_application/
  lib/
    src/
      core/                 Shared configuration, networking, theme, and widgets
      features/
        <feature>/
          data/             API models, repositories, and remote services
          domain/           Business entities and policies when needed
          presentation/     Controllers, screens, and widgets
  test/
    unit/                   Controller and pure-logic tests
    widget/                 Screen and interaction tests
    integration/            Repository/API-boundary tests
```

Feature code should not be added to `core` unless it is reused by multiple
features. New screens should keep network access in repositories and state in a
controller rather than calling HTTP directly from widgets.

## Backend repository

The FastAPI backend is maintained separately at `../Petto-Backend`:

```text
app/
  routers/                  HTTP endpoints and request/response contracts
  services/                 Reusable business logic and external integrations
  models.py                 SQLAlchemy persistence models
  schemas.py                Shared API schemas
alembic/versions/           Ordered database migrations
tests/                      Unit, integration, security, and readiness tests
```

Large router functions should move reusable business rules into `app/services`
without changing their public API contract.

## Local-only material

Files beginning with `.codex_`, Flutter `build` directories, Python bytecode,
and tool caches are local artifacts. Document-generation scripts, diagrams, and
test evidence remain untracked until the team decides whether to keep them in a
separate documentation repository or under a reviewed `docs/` hierarchy.
