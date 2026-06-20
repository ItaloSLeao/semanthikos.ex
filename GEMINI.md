# GEMINI.md - Event Manager Instructions

This file provides architectural context, development workflows, and coding standards for the **Event Manager** project.

## Project Overview

**Event Manager** is a simplified full-stack Elixir application using the Phoenix Framework. It manages academic events with a focus on simplicity and efficiency.

### Core Stack
- **Language:** Elixir 1.14+
- **Framework:** Phoenix 1.7
- **Database:** PostgreSQL 14+
- **Real-time:** LiveView & Phoenix Channels

## Architecture (Consolidated Contexts)

The project follows a "Gerentes de Departamento" (Consolidated Contexts) approach to reduce boilerplate and complexity.

### Directory Structure
- `lib/event_manager/`: Logic & Data.
    - `schemas/`: All database table definitions (User, Event, Registration, etc.).
    - `core.ex`: **Gerente Principal**. Handles Accounts (Auth, Users) and Events (CRUD, Registrations).
    - `services.ex`: **Gerente de Apoio**. Handles Chat, Certificates, and Reports.
    - `repo.ex`: Database engine.
    - `user_notifier.ex`: Email delivery logic.
- `lib/event_manager_web/`: User Interface.
    - `controllers/`: HTTP maestros. Includes an `api/` subfolder for REST endpoints.
    - `live/`: Intelligent views for real-time dashboards and chat.
    - `router.ex`: Centralized routes and RBAC rules.

### Key Patterns
1. **Simplified Logic:** Prefer adding functions to `Core` or `Services` instead of creating new contexts for every feature.
2. **Atomic Seats:** Seat reservation remains atomic in `Repo.reserve_seat/2`.
3. **RBAC:** Managed in `router.ex` through pipelines (`:require_admin`, `:require_speaker`).

## Development Workflow

### Key Commands
- **Setup:** `mix setup`
- **Server:** `mix phx.server`
- **Test:** `mix test`
- **Reset DB:** `mix ecto.reset`

## Coding Standards
- **Schemas:** Keep schemas in `EventManager.Schemas.*`.
- **Logic:** Context functions should be the primary entry point for the web layer.
- **Naming:** Follow Elixir conventions (snake_case for functions, PascalCase for modules).

## Unresolved Issues
- **LiveView Chat Websocket:** The chat page (`EventChatLive`) currently fails to connect its websocket after the initial HTTP render, rendering the chat unresponsive. Despite injecting the session token into the LiveSocket via `endpoint.ex`, the client browser does not establish the connection or trigger the `mount` lifecycle. A workaround or deeper debug is needed, as `AdminDashboardLive` websockets work correctly.
