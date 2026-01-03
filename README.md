# nxt-hospital-skeleton-project

## nxt-hospital-skeleton-project — Project README (Pitch & Technical Summary)

This repository is a compact, production-oriented Docker Compose skeleton for the NXT Hospital Management System (HMS). It is built for multi-tenant hospital deployments and automates common hospital operations — patient lifecycle, appointment booking, billing, printing, campaigns, and background processing — while providing secure file storage and tenant isolation.

This README highlights core architecture, major product features, the tenant-aware file upload system, developer quick start, and a short business pitch you can use when presenting the project.

**Why this repo?**
- Designed for multi-tenant SaaS: tenant-aware schemas, per-tenant file storage, and request-level tenant enforcement patterns.
- Built-in automation: scheduled jobs, messaging/campaign system, and background workers for asynchronous integrations (tax authority, notifications).
- Practical production patterns: cluster-aware server, BullMQ queues, Redis DB separation, and PM2-friendly process model.

**Audience:** technical reviewers, potential customers, and platform engineers evaluating an HMS foundation for multi-site hospital networks.

--

**Core components (quick)**
- `hms-backend/` — Node/Express API with controllers, services, BullMQ queues and workers. Key files: `server.js`, `bootstrap/index.js`, `config/`, `queues/`, `workers/`.
- `hospital-frontend/` — Angular admin UI (single HTTP surface at `src/app/services/http.service.ts`).
- `customer-portal/` — Patient portal + print templates under `src/assets/print/` (uses short-url pattern for secure printing).
- `appointment-ivr/` — FreeSWITCH Lua IVR integrations for phone-based appointment flows.
- `nxt-hospital-skeleton-project/` — Docker Compose orchestrator and example deployment for local/VM testing.

## Major HMS Features (detailed)

1) Multi-Tenancy (First-class)
- Schema: MySQL schema is multi-tenant ready — the majority of tables include `tenant_id` defaulting to `system_default_tenant`.
- Request flow: `X-Tenant-Id` header and `ensureTenant` middleware derive and validate tenant context. Pattern: controllers/services must include `tenant_id` in all queries.
- File storage: tenant-isolated host folders and tenant-scoped public URLs (see File Upload Mechanism below).
- Note: the repo includes an audit and docs for outstanding tenant isolation work; fix lists are in `docs/` for production hardening.

2) Automation & Background Processing
- Queues: BullMQ (Redis) for deferred work — campaign delivery, FBR tax sync, report generation.
- Scheduler: `scheduledJobsService.js` uses node-schedule for daily/recurring tasks; can run as standalone process for resilience.
- Workers: separate Node workers process jobs from queues; workers can be disabled via env flags during dev.

3) Patient Matching & Duplicate Prevention
- Service `PatientMatchingService` implements multi-factor matching (CNIC exact, mobile + fuzzy name, Levenshtein) to reduce duplicate MRIDs and improve front-desk workflow.

4) ID Generation System
- Structured, deterministic IDs (MRID, slips) with a reserve/commit pattern to avoid collisions across tenants. See `hms-backend/controllers/idGeneratorController.js` and frontend counterpart.

5) Print System (Secure)
- Short-URL flow: UI requests a short URL from the backend (tiny-url service). `customer-portal` print templates (A4/thermal) resolve hash → fetch print data → auto-print. Reduces leakage of sensitive query params.

6) Campaigns & Multi-channel Messaging
- Generic campaign service routes events (`new_patient`, `appointment_created`, etc.) into channel adapters (WhatsApp, Email, SMS) and enqueues jobs for delivery with telemetry.

7) IVR Integration
- FreeSWITCH Lua scripts under `appointment-ivr/ivr_scripts/` provide automated phone interactions and call flows that can use REST APIs and DB queries.

8) Bootstrap & Data Seeding
- Safe bootstrap: `hms-backend/bootstrap/index.js` provides idempotent seeding of baseline data (permissions, departments, lab tests). Always check with `npm run bootstrap:status` before making changes.

## File Upload Mechanism (Tenant-aware, secure)

This is a critical part of the HMS pitch: secure storage of patient files (images, reports, DICOM) with tenant isolation and scalable patterns.

How it works
- Upload flow: backend routes use `tenantMiddleware` to set `req.tenant_id`; file uploads are handled by `multer` (see `hms-backend/examples/tenant-aware-upload-example.js`).
-- Storage layout (host): `./images/<tenant_id>/<category>/<file>` (repo-relative bind mount) — this maps 1:1 to S3/MinIO keys if migrating later.
- Public URLs: served by `nginx` as `/images/<tenant_id>/...` with caching headers. Backend generates signed/validated URLs by verifying tenant ownership before returning paths.

Security rules (enforced)
- Never accept `tenant_id` from request body/query — always derive from JWT/subdomain or middleware.
- Validate file deletions and reads by confirming `req.tenant_id` matches the file path.
- Use read-only mounts in the `nginx` container to prevent direct writes.

Migration & scaling
- Small deployments: host filesystem with tenant folders.
- Scale: switch to MinIO/S3 with the same logical keys and enable CDN and lifecycle policies.

Backup & retention
- Example cron-based tar backups or disk snapshots; recommend lifecycle policies in object storage for large archives.

## Developer Quick Start (condensed)

1. Local dev (PowerShell on Windows recommended):
```powershell
cd hms-backend; npm install; npm start
cd hospital-frontend; npm install; npm start
cd customer-portal; npm install; npm start
```

2. Full stack (Docker Compose - VM):
```bash
cd nxt-hospital-skeleton-project
docker compose up -d
bash scripts/verify-deployment.sh
```

Health endpoints:
- API health: `http://localhost/api-server/health` (or mapped host port)

## Architecture & Integration Points

- MySQL (no ORM) — direct `mysql2` queries, connection pooling in `hms-backend/config/connection.js`.
- Redis: 4 logical DBs — DB0=queues, DB1=tiny-url cache, DB2=app cache, DB3=sessions.
- BullMQ job queues and BullBoard UI for monitoring at `/admin/queues`.
- PM2 or Docker process model: `server.js` supports cluster mode; recommended PM2 config provided in docs.

## Business Pitch (one-paragraph for stakeholders)

NXT HMS is a multi-tenant hospital management platform designed to accelerate digital transformation for hospital networks and clinic groups. It bundles patient lifecycle automation (intake, matching, slips, billing), secure per-tenant file handling, multi-channel patient communications, and modern background processing for compliance integrations (tax/FBR) — all deployable via Docker Compose or container orchestration. The platform's tenant-first design and secure print/file patterns make it ideal for SaaS deployments where data isolation, auditability, and automation are must-haves.

## Next steps / How we can present this repo

1. Create a 5-slide pitch deck: Problem → Solution (NXT HMS) → Architecture → Demo plan → Ask (pilot customers).
2. Prepare a short demo script: start the compose stack, create a tenant, upload a patient image, generate a print short-url, and show a queued campaign.
3. Harden tenant-isolation hotspots listed under `docs/` before production proposals.

## Where to look first (developer checklist)
- `hms-backend/server.js` — entry, cluster and health endpoints
- `hms-backend/bootstrap/index.js` — bootstrap & seed logic
- `hms-backend/controllers/idGeneratorController.js` — ID reservation/commit patterns
- `hms-backend/services/PatientMatchingService.js` — deduplication
- `hospital-frontend/src/app/services/http.service.ts` — single source of API endpoints
- `customer-portal/src/assets/print/` — print templates and short-url flow

---

If you want, I can also generate the 5-slide pitch deck and a short demo script from the repo. Tell me which audience to target (technical, product, or executive) and I'll draft it.
