# ADR-001: Mobile is an independent platform

- Status: Accepted
- Date: 31-Jul-2026
- Decision: Mobile will be treated as an independent product with its own lifecycle, deployment, database, configuration, authentication, and APIs.

## Reason

Mobile has different business goals, deployment needs, and operational requirements from ERP. It must be able to evolve independently without tying itself to the ERP platform.

## Consequences

- Mobile must have its own deployment and database.
- Mobile must not depend on ERP infrastructure or ERP repositories.
- ERP remains stable and independent.
