# Unified Customer Experience Platform

A Salesforce Sales Cloud + Service Cloud + Experience Cloud project connecting sales, support, and customer self-service into one system — with SLA automation and a live external integration.

## Problem it solves

Sales and Service typically run as disconnected systems: agents have no visibility into what a customer bought, SLAs go untracked, and customers have no way to self-serve. This project closes those gaps in one connected platform.

## What's built so far

- **Data model:** Custom `Shipment__c` object, Order↔Opportunity and Case↔Order lookups, standard Order/Product2/Entitlement objects
- **Security:** Permission Sets (Sales Rep, Service Agent, Portal Customer), Org-Wide Defaults, sharing rules
- **Sales Cloud automation:** Flow auto-creates an Order when an Opportunity is marked Closed Won
- **Service Cloud SLA:** Entitlement Process with Milestones (First Response, Resolution), auto-populated on new Cases via Flow, with a scheduled escalation Flow for breached SLAs
- **Omni-Channel:** Service Channel, Queues, and Routing Configuration for real-time case routing. Live agent presence activation hit an environment-specific limitation in the Developer Edition trial org; the full routing configuration is in place and would activate in a standard Sales/Service Cloud license
- **Integration:** A mock external order/shipment API (Node/Express, deployed on Render), called via a bulk-safe Apex class with 97%+ test coverage, a Platform Event for real-time updates, a Scheduled Apex job (using the Scheduler→Queueable pattern to work around Salesforce's callout-from-scheduled-Apex restriction), and a manual "Sync Now" button (Screen Flow + Quick Action)
- **Experience Cloud:** A live customer portal (Customer Community Plus license) with authenticated login and sharing rules granting customers visibility into their own Cases and Orders

## Tech stack

Apex, Lightning Flow, Lightning Web Components, Experience Cloud, Platform Events, Named Credentials, Node.js/Express, SFDX, Git/GitHub

## In progress

- Customer 360 LWC (agent-facing)
- Order-tracking LWC (customer portal)
- Reports & dashboards
- CI/CD via GitHub Actions

## Setup

1. Clone this repo
2. Authenticate to a Salesforce org: `sf org login web --alias devorg --set-default`
3. Deploy: `sf project deploy start`