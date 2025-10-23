# Contributing

Thanks for your interest in contributing! This document outlines the project setup, standards, and workflow.

## Prerequisites

- Node.js v18+
- Flutter SDK 3.4+
- Git
- API keys (OpenAI, YouTube Data API v3)

## Repository Setup

1. Fork and clone the repo
2. Create a feature branch: `git checkout -b feat/short-description`
3. Keep your fork in sync: `git fetch origin && git rebase origin/main`

## Local Development

### Backend

```bash
cd backend
npm install
cp .env.example .env
# Populate OPENAI_API_KEY, DEV_YOUTUBE_API_KEY, YOUTUBE_API_KEY
npm start
```

- API served at `http://localhost:3000/api`
- Nodemon reloads on changes

### Frontend

```bash
cd frontend
flutter pub get
# Web
aflutter run -d chrome
```

- Update `lib/data/remote/apis.dart` to point at your backend if needed

## Code Standards

### Backend (Node.js)

- Use async/await with meaningful error propagation
- Centralize config in `src/config`
- Validate inputs with `express-validator`
- Use structured logging in `src/utils/logger.js`
- Keep controllers thin; put logic in services

Naming:

- Files: `camelCase.js`
- Classes: `PascalCase`
- Functions/variables: `camelCase`
- Constants: `UPPER_SNAKE_CASE`
- Private methods: `_camelCase`

### Frontend (Flutter)

- Follow Dart style guide; run `dart format`
- Enforce null safety
- Use GetX for state management
- Organize by feature (controllers, view_models, repositories, views)

Naming:

- Files: `snake_case.dart`
- Classes: `PascalCase`
- Variables/functions: `camelCase`

## Commit Messages

Use conventional commits:

- `feat:` new feature
- `fix:` bug fix
- `docs:` docs only changes
- `refactor:` neither fixes a bug nor adds a feature
- `style:` formatting, missing semi colons, etc.
- `test:` adding or correcting tests
- `chore:` tooling, deps, CI

## Pull Request Checklist

- Follows coding standards and naming
- Updates docs if behavior changes
- Includes tests or manual verification steps where applicable
- No linter/type errors

## Testing

### Backend

```bash
# Health
curl http://localhost:3000/api/health
# SSE analysis (uses -N to keep stream open)
curl -N -X POST http://localhost:3000/api/analyze/stream \
  -H "Content-Type: application/json" \
  -d '{"channels":[{"channelId":"UC123","userName":"@u","title":"t","channelName":"c"}]}'
```

### Frontend

```bash
flutter test
```

## Issue Reporting

Please include:

- Clear description and expected vs. actual behavior
- Steps to reproduce
- Environment (OS, Node, Flutter)
- Logs or screenshots

## Code of Conduct

- Be respectful and constructive
- Prefer evidence over opinion; include profiling numbers when discussing performance
- Review in good faith
