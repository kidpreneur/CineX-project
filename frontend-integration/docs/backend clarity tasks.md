📦 Backend Tasks & Actions (Clarity + Clarinet + Vitest)
✅ Basic Tasks
Setup and boilerplate tasks needed to begin development.
Initialize Clarinet project (clarinet new)


Add Clarity smart contracts:


pool-tracker


pool


router


token


Write README documentation for each contract


Set up project structure inside /contracts/, /tests/, /settings/, etc.


Configure Clarinet.toml with correct contract declarations


Add VSCode tasks.json to simplify dev commands (clarinet check, npm test, etc.)



⚙️ Medium Tasks
Intermediate functionality, unit tests, and custom logic.
Implement Clarity logic:


pool contract: create pool, join pool, exit pool


router contract: route swaps, manage routing logic


token contract: SIP-010 standard token interface


pool-tracker: handle pool listing and metadata


Write Vitest unit tests for each contract


Setup vitest.config.js with Clarinet/Vitest integration


Add test coverage collection (--coverage, --costs)


Verify correct pool behavior and token balances in tests


Validate routing logic correctness via test simulations



🚀 Complex Tasks
Advanced features, error handling, optimizations, and integrations.
Add simulation scripts for stress-testing pool usage


Integrate custom Clarinet cost/coverage reports


Implement SIP-010 compliance tests


Build custom matchers with Vitest for Clarity values


Add edge-case tests for overflows, invalid routing, zero balances


Ensure deterministic test results across runs


Set up CI with Clarinet + Vitest test runner (e.g., GitHub Actions)


