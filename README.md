# Simple Budget

Simple Budget is a personal budgeting application for tracking account balances,
income, expenses, and transfers. Transactions are organized by month and category,
and the dashboard summarizes balances and monthly income and expenses.

## Features

- Sign up and manage a personal budget.
- Track multiple accounts and categorize income and expenses.
- Record transfers between accounts.
- Review monthly totals and category breakdowns.
- Store monetary amounts as integer minor units to avoid floating-point rounding.

New users receive a starter budget with a default account, categories, and sample
transactions.

## Requirements

- Ruby 4.0.9 (see `.ruby-version`)
- PostgreSQL
- Bundler
- PostgreSQL client development libraries for building the `pg` gem (for example,
  `libpq-dev` on Debian or Ubuntu)

## Getting started

Clone the repository, then run the setup script:

```sh
bin/setup
```

The script installs Ruby dependencies, prepares the database, and starts the
development server. The app is then available at <http://localhost:3000>.
Register an account to open your budget.

To prepare the environment without starting the server:

```sh
bin/setup --skip-server
bin/dev
```

By default, the development and test databases use the local PostgreSQL role
matching your operating-system username. Configure PostgreSQL access in
`config/database.yml` or set `DATABASE_URL` if your local setup differs.

## Running tests and checks

Run the RSpec test suite:

```sh
bundle exec rspec
```

Run the same style and security checks used in CI:

```sh
bin/rubocop
bin/brakeman --no-pager
bin/bundler-audit
bin/importmap audit
```

## Deployment

The included `Dockerfile` builds a production image. See its comments and
`config/deploy.yml` for the Docker and Kamal deployment configuration. Production
deployments need a PostgreSQL database and the Rails master key supplied through
`RAILS_MASTER_KEY`; the database password is read from
`SIMPLE_BUDGET_DATABASE_PASSWORD`.

### Render demo deployment

The root `render.yaml` defines a free Render web service and connects to an
existing PostgreSQL database. Create a Blueprint in Render from this repository
and provide `RAILS_MASTER_KEY` and the database's internal connection URL
(`DATABASE_URL`) when prompted. Get the master key from `config/master.key` in
a trusted local environment; do not commit or share it. The web service and
database must be in the same Render region.

This Blueprint is for temporary demos only: Render's free PostgreSQL database
expires after 30 days, and the free web service may spin down when idle. The
demo uses in-memory caching and async jobs/cable instead of the additional
Solid database connections configured for persistent deployments.
