# PowerShell Admin Toolkit

A practical collection of reusable PowerShell utilities for Windows administration, diagnostics, performance monitoring, software deployment, and operational troubleshooting.

## Executive Lens

This toolkit is less about individual scripts than about an operating principle: recurring administrative work should become standardized, observable, and reusable instead of remaining tribal knowledge. The scripts are intentionally generic so the techniques can travel between environments without exposing employer-specific details.

**Leadership questions this work addresses:**

- Which recurring support tasks should be automated rather than repeated manually?
- What output needs to be structured so another technician or reporting process can use it?
- How do we make scripts safe enough to hand to someone else?
- How do we separate reusable operations logic from environment-specific credentials and configuration?

This repository is built around a simple idea: operational scripts should be understandable, configurable, safe to run, and useful outside the environment where they were first conceived.

## Current Utilities

### Watch-SystemPerformance.ps1

Continuously samples:

- Network latency to configurable endpoints
- CPU utilization
- Committed memory utilization
- Disk read latency
- Disk write latency
- Disk transfer rate

Output is written to CSV so the data can be opened directly in Excel or consumed by another reporting pipeline.

Example:

```powershell
.\scripts\Watch-SystemPerformance.ps1 -Targets "1.1.1.1","8.8.8.8" -OutputDirectory "C:\Temp\PerfLogs" -IntervalSeconds 5 -DurationMinutes 15
```

Run indefinitely by omitting `-DurationMinutes`:

```powershell
.\scripts\Watch-SystemPerformance.ps1 -Targets "1.1.1.1","8.8.8.8"
```

## Design Goals

- No embedded credentials
- No employer- or customer-specific dependencies
- Sensible defaults
- Structured output
- Error-tolerant collection
- Clear parameters and help
- Useful as both a standalone tool and a starting point for automation

### Get-SystemHealth.ps1

Collects a structured health snapshot including OS details, uptime, physical memory, local disk capacity, active network adapters, and selected core Windows services.

```powershell
.\scripts\Get-SystemHealth.ps1 -OutputJson ".\reports\system-health.json"
```

## Planned Additions

- Disk cleanup and storage analysis
- Network diagnostics
- Windows service health checks
- Event log triage
- Software installation/update helpers
- Microsoft 365 / Entra ID examples
- JSON and HTML reporting
- Pester tests

## Repository Layout

```text
powershell-admin-toolkit/
├── scripts/
│   └── Watch-SystemPerformance.ps1
├── .gitignore
└── README.md
```

## Security

Never commit credentials, access tokens, tenant secrets, private keys, customer data, or production configuration files. Use environment variables or local configuration files excluded by `.gitignore`.

## Background

Several utilities in this repository are generalized from recurring infrastructure and operations problems encountered over years of enterprise IT work. Public versions are rewritten to remove proprietary details and make the underlying techniques reusable.


## Tradeoffs and Decisions

- **Readable scripts over compressed cleverness:** easier to review and hand off, even if the code is longer.
- **Structured output over console-only output:** more useful for reporting and automation, while adding some implementation overhead.
- **Configurable parameters instead of hard-coded environment values:** improves reuse and safety, but requires clearer documentation and validation.

## What I Would Improve Next

I would add Pester coverage, richer error categorization, HTML/JSON reporting, event-log triage, network diagnostics, service-health checks, and Microsoft 365 / Entra ID examples. The larger goal would be to turn the toolkit into a small operational automation framework rather than a loose script collection.

