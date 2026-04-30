# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Development
bin/setup          # Install deps, prepare DB, start server
bin/dev            # Start Rails server (bin/rails server)

# Testing
bin/rails test                          # All tests
bin/rails test test/models/user_test.rb # Single test file
bin/rails test -n test_method_name      # Single test by name
bin/rails test:system                   # Capybara system tests

# Code quality
bin/rubocop                    # Lint
bin/brakeman --no-pager        # Security scan
bundler-audit check --update   # Gem vulnerability check

# Full CI locally
bin/ci

# Database
bin/rails db:migrate
bin/rails db:reset
bin/rails dbconsole            # SQLite console
```

## Architecture

**Rails 8.1**, Ruby 3.4.8, SQLite3 (all envs), Minitest, Propshaft + importmap (no Node/npm build step).

### Authentication

Custom session-based auth (no Devise) implemented in `app/controllers/concerns/authentication.rb`. Key patterns:
- `require_authentication` before action fires by default on all controllers
- Use `allow_unauthenticated_access` to open actions publicly (e.g., products#index/show)
- Use `unauthenticated_access_only` to redirect logged-in users (e.g., sessions, sign up)
- `Current.user` and `Current.session` are set per request via `app/models/current.rb`

### Core Models

- **User** — `has_secure_password`, `has_many :sessions`, email normalized on save
- **Product** — `has_rich_text :description`, `has_one_attached :featured_image`, `has_many :subscribers`, includes `Product::Notifications` concern
- **Subscriber** — belongs to a product, `generates_token_for :unsubscribe` for secure unsubscribe links
- **Session** — tracks `user_agent` and `ip_address` per login

### Back-in-Stock Notifications

`app/models/concerns/product/notifications.rb` hooks into `after_update_commit` to send `ProductMailer#in_stock` when `inventory_count` transitions from 0 to positive. Subscribers receive a one-click unsubscribe link via signed token.

### Solid Ecosystem (database-backed infrastructure)

- **solid_queue** — background jobs, runs inside Puma in production (`SOLID_QUEUE_IN_PUMA: true`)
- **solid_cache** — Rails cache store
- **solid_cable** — Action Cable adapter
- Production uses separate SQLite databases for each: `production_queue.sqlite3`, `production_cache.sqlite3`, `production_cable.sqlite3`

### Routes Summary

```
root → products#index
resource :session              # login/logout
resource :sign_up              # registration
resources :passwords           # password reset (param: :token)
resources :products do
  resources :subscribers, only: [:create]
end
resource :unsubscribe, only: [:show]
namespace :settings do
  resource :password, only: [:show, :update]
end
get "up" => "rails/health#show"
```

### Testing Conventions

Minitest with fixtures (`test/fixtures/`). Parallel test execution enabled. Custom `sign_in_as(user)` and `sign_out` helpers available in all tests via `test/test_helpers/session_test_helper.rb`.

### Deployment

Kamal (Docker). Single host at `192.168.0.24`, local Docker registry at `localhost:5555`. Persistent storage mounted at `/rails/storage` for SQLite databases and Active Storage files. Thruster runs as an HTTP caching proxy in front of Puma.
