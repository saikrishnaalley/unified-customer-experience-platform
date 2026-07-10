# Unified Customer Experience Platform

A Salesforce Sales Cloud + Service Cloud + Experience Cloud project connecting sales, support, and customer self-service into one system — with SLA automation, a live external integration, and a fully automated CI/CD pipeline.

## Problem it solves

Sales and Service typically run as disconnected systems: agents have no visibility into what a customer bought, SLAs go untracked, and customers have no way to self-serve. This project closes those gaps in one connected platform.

## What's built

**Data model:** Custom `Shipment__c` object, Order↔Opportunity and Case↔Order lookups, standard Order/Product2/Entitlement objects.

**Security:** Permission Sets (Sales Rep, Service Agent, Portal Customer), Org-Wide Defaults, sharing rules, and Apex-managed sharing (`Shipment__Share`) for cases where declarative role-based sharing didn't propagate reliably.

**Sales Cloud automation:** Flow auto-creates an Order (with real Order Products/line items) when an Opportunity is marked Closed Won.

**Service Cloud SLA:** Entitlement Process with Milestones (First Response — 240 min, Resolution — 960 min), auto-populated on new Cases via Flow, with a scheduled escalation Flow for breached SLAs.

**Omni-Channel:** Service Channel, Queues, and Routing Configuration for real-time case routing. Live agent presence activation hit an environment-specific limitation in the Developer Edition trial org; the full routing configuration is in place and would activate in a standard Sales/Service Cloud license.

**Integration:** A mock external order/shipment API (Node/Express, deployed on Render), called via a bulk-safe Apex service (`OrderSyncService`) with 95%+ test coverage, chunked to respect Salesforce's 100-callout-per-transaction governor limit via queueable chaining, a Platform Event for real-time updates, a Scheduled Apex job (using the Scheduler→Queueable pattern to work around Salesforce's callout-from-scheduled-Apex restriction), and a manual "Sync Now" button (Screen Flow + Quick Action).

**Experience Cloud:** A live customer portal (Customer Community Plus license) with authenticated login and sharing rules granting customers visibility into their own Cases, Orders, and Shipments.

**Agent-facing LWC:** `Customer360Controller` + `customer360` component on the Account page — shows Account, Opportunities, Orders, and Shipments, plus color-coded SLA Milestone countdowns and a **live Platform Event subscription** (via `lightning/empApi`) that auto-refreshes the view when an order status changes elsewhere in the system.

**Customer-facing LWC:** `PortalOrderController` + `myOrders` component on the portal Home page — shows each customer's Orders and Shipment tracking status, respecting all sharing rules.

**Reports & dashboards:** Pipeline by Stage, Case Resolution Time, SLA Compliance Rate, Cases by Origin, and a `UCE Platform Overview` dashboard — version-controlled in this repo, not just live in the org.

**CI/CD:** Fully automated via GitHub Actions. Every push to `main` authenticates to the org via JWT bearer flow (certificate-based, no interactive login), deploys the entire `force-app` source tree, and runs the full local Apex test suite — with results visible in the Actions tab. See [CI/CD Pipeline](#cicd-pipeline) below.

## CI/CD Pipeline

This project deploys and tests itself automatically. On every push to `main`:

1. GitHub Actions spins up a fresh runner and installs the Salesforce CLI
2. Authenticates to the org via **JWT bearer flow** — a self-signed certificate registered on a Salesforce External Client App, with the private key stored as a GitHub secret. No password is ever entered.
3. Deploys the full source tree (`sf project deploy start`)
4. Runs all local Apex tests (`sf apex run test --test-level RunLocalTests`)
5. Reports pass/fail results directly in the Actions tab

Workflow file: [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml)

This setup caught two real bugs before they could reach a "working" org silently:
- A scheduled-job naming collision in a test that only surfaced when running against an org with a live scheduled job already present
- A missing object/field permission (and a stale "In Development" deployment status) that silently blocked portal users from seeing their own Shipment records — invisible to admin testing, but caught immediately by a test that ran as the actual portal user

## Testing strategy

- Custom Apex classes average **95–97% coverage** (org-wide figure includes bundled Salesforce Experience Cloud controllers that aren't part of this project's code, which pulls the blended number down to ~80%)
- `HttpCalloutMock` used throughout — no test ever makes a real callout
- Bulk tests exercise governor-limit boundaries (100-record callout ceiling per transaction), not arbitrary small numbers
- Negative/edge cases covered: failed callouts, non-existent record Ids, empty input lists
- `OrderSyncQueueable` chunks any batch over 100 orders and chains itself via `System.enqueueJob` to stay within Salesforce's per-transaction callout limit — a bug the bulk tests surfaced directly, fixed as a result

## Known limitations

- **Omni-Channel live presence:** routing configuration is complete, but live agent presence activation is blocked by a Developer Edition trial org limitation — would work as-is on a standard license.
- **CI/CD deploys to a persistent dev org**, not a disposable scratch org per run, since this is a solo project without a team review/branch workflow. A team setting would typically add feature branches, pull request review, and per-PR scratch org validation before merging to `main`.

## Tech stack

Apex, Lightning Flow, Lightning Web Components, Experience Cloud, Platform Events, Named Credentials, Node.js/Express, GitHub Actions, JWT-based CI/CD authentication, SFDX, Git/GitHub

## Demo

- **Customer Portal:** `https://orgfarm-a1be47f661-dev-ed.develop.my.site.com/s/`
- Demo login username: `acme.contact@uceplatform.dev` (password available on request)

## Setup

1. Clone this repo
2. Authenticate to a Salesforce org: `sf org login web --alias devorg --set-default`
3. Deploy: `sf project deploy start`
4. Run tests: `sf apex run test --test-level RunLocalTests --code-coverage --result-format human`

To set up your own CI/CD pipeline against a different org, see the JWT auth setup steps in `.github/workflows/deploy.yml` and configure the four required repo secrets (`SF_CONSUMER_KEY`, `SF_USERNAME`, `SF_INSTANCE_URL`, `SF_JWT_KEY`).