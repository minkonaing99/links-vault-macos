# LinkVault

Native macOS and iOS client for [LinkVault](https://links.merxy.club) — a personal link bookmarking app backed by MongoDB Atlas.

Built with SwiftUI. No external dependencies.

## Requirements

- Xcode 16+
- macOS 15+ (for development)
- A running LinkVault backend (see backend setup below)

## Setup

1. Clone the repo and open `links-vault-macos.xcodeproj` in Xcode
2. Select the `links-vault-macos` scheme
3. Build and run (`⌘R`)

The app connects to `http://localhost:3080` in Debug and `https://links.merxy.club` in Release. To change the backend URL, edit `Config/AppConfig.swift`.

## Backend

The backend is a Node.js server + MongoDB Atlas. To run it locally:

```bash
cd "links-vault website"
cp .env.example .env   # fill in MONGODB_URI, JWT_SECRET, etc.
npm install
npm start              # listens on port 3080
```

## Features

- **Login** — JWT auth with auto token refresh; session restored from Keychain on launch
- **Home** — Quick Add (auto-fetches page title) + recent links
- **Browse** — Search, filter by status, sort, pin/delete/edit links, export JSON
- **Add Link** — Fetch title from URL and save
- **Menu bar** — Lives in the macOS menu bar; shows recent + pinned links with copy and open-in-browser actions
- **iOS** — Full TabView UI sharing the same codebase via `#if os(iOS)`

## Architecture

| Layer | Details |
|-------|---------|
| State | `@Observable LinksStore` owned at app level, shared via SwiftUI environment |
| API | `actor APIClient` — thread-safe, auto-refreshes expired tokens |
| Auth | Keychain via `KeychainService` (access token + refresh token) |
| Navigation | macOS: `NavigationSplitView` sidebar · iOS: `TabView` |

All mutations (pin, delete, create, update) are **optimistic** — the UI updates immediately and rolls back on API failure.

## Project Structure

```
links-vault-macos/
  Config/           AppConfig.swift — base URL per build config
  Models/           Link, LinksStore, APIModels, APIError
  Services/         APIClient (actor), KeychainService
  Views/
    Components/     LinkRowView, SurfaceCard, StatusDot
    MenuBarView     macOS menu bar popover
    LoginView
    MainView        NavigationSplitView (macOS) / TabView (iOS)
    HomeView
    BrowseView
    AddLinkView
    EditLinkView
  Colors.swift      Design tokens (dark terminal palette)
```
