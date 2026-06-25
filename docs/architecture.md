# Architecture

## Current state — single-entity Hong Kong

The platform is live in Hong Kong. Every component embeds Hong Kong-specific constants: HKD currency, SFC regulator (with HKMA and PDPO obligations), en_HK locale, Hong Kong booking centre, 60 bps management fee, and a 1,000,000 HKD large-position threshold.

### Components

| Component | Location | Responsibility |
|-----------|----------|----------------|
| COBOL batch | `cobol/PORTVAL.cbl` | Nightly portfolio valuation, fee computation, disclosure flags |
| Java API | `java/AccountController.java` | REST endpoint `POST /api/account/value` for on-demand valuation |
| Python module | `python/risk_report.py` | Risk report generation with suitability and disclosure text |
| SQL schema | `sql/schema.sql` | Client, portfolio, and holding tables with HK defaults |

None of these components share a configuration layer today. Each hardcodes the same Hong Kong assumptions independently.

## Target state — entity-aware, single codebase

One codebase serves three legal-entity deployments:

| Entity | Code | Currency | Regulator | Azure region |
|--------|------|----------|-----------|--------------|
| Hong Kong (live) | HK | HKD | SFC (HKMA + PDPO) | East Asia |
| Singapore | SG | SGD | MAS | Southeast Asia |
| Switzerland | CH | CHF | FINMA | Switzerland North |

Entity configuration (currency, locale, regulator, fee schedule, thresholds, disclosure templates, data region) is injected at deploy time — not selected at runtime. Each entity runs in its own Azure VPC with a dedicated Key Vault.

The multi-agent refactoring workflow will:

1. Extract hardcoded constants into entity configuration.
2. Add an `entity` configuration record (or equivalent) consumed by all four components.
3. Introduce `entity_id` / entity-aware defaults in the SQL schema.
4. Preserve backward compatibility for the live Hong Kong deployment.
