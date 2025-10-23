# YouTube Automation

A full-stack application for YouTube channel analysis and outreach using AI-powered content analysis with real-time streaming.

## Project Structure

```
youtube_automation/
├── backend/                 # Node.js + Express API (SSE, caching, quota)
├── frontend/                # Flutter cross-platform app (Web/Mobile/Desktop)
├── PROJECT_CONTEXT.md       # Architecture and key concepts
├── CONTRIBUTING.md          # Contribution workflow and standards
└── README.md                # This file
```

## Quick Start

### Backend

```bash
cd backend
npm install
# Create and configure environment
cp .env.example .env
# Required: OPENAI_API_KEY, DEV_YOUTUBE_API_KEY, YOUTUBE_API_KEY
npm start
```

- Default port: `3000`
- Base path: `/api`

### Frontend

```bash
cd frontend
flutter pub get
# Web
flutter run -d chrome
```

- The app is wired to a hosted backend by default (`Endpoints.baseUrl`). For local development, switch to `http://localhost:3000/api/` in `lib/data/remote/apis.dart`.

## Documentation

- [PROJECT_CONTEXT.md](./PROJECT_CONTEXT.md) — Architecture, flows, technology choices
- [CONTRIBUTING.md](./CONTRIBUTING.md) — Repo workflow, code standards, testing
- [Backend README](./backend/README.md) — Endpoints, env vars, usage
- [Frontend README](./frontend/README.md) — Setup, configuration, structure

## Features

- **YouTube Integration**: Channel search and metadata via YouTube Data API v3
- **AI Batch Analysis**: Batched channel analysis with OpenAI Chat Completions
- **Real-time Updates**: Server-Sent Events (SSE) for progress and batch results
- **Performance**: Request timeouts, caching (7-day TTL), and mutex-based deduplication
- **CSV Export**: Download analyzed data from the UI

## Technology Stack

- **Frontend**: Flutter, GetX, Material Design
- **Backend**: Node.js, Express, OpenAI SDK, express-validator, helmet, rate limiting
- **External APIs**: YouTube Data API v3, OpenAI API

## License

Private project — All rights reserved.
