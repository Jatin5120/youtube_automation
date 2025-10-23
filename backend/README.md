# YouTube Automation Backend

A Node.js backend service for YouTube channel analysis with AI-powered batch processing using OpenAI Chat Completions. Provides intelligent caching, real-time Server-Sent Events (SSE), and optimized batch workflows.

## Features

- **AI Batch Analysis**: Batched channel analysis via OpenAI Chat Completions
- **Real-time Streaming**: Server-Sent Events (SSE) for live progress updates and batch results
- **Intelligent Caching**: 7-day TTL LRU cache with mutex protection
- **Performance**: Race-condition mitigation, rate limiting, timeouts, and cleanup
- **Request Tracking**: Unique request IDs and structured logging
- **Validation & Security**: Input validation, helmet, CORS, rate limiting

## API Endpoints

Base path: `/api`

### Health & Info

- `GET /api/` — API info
- `GET /api/health` — Health check
- `GET /api/wakeup` — Keep-alive endpoint

### YouTube Data

- `PATCH /api/videos` — Get channel videos/metadata
  - Body: `{ ids: base64("id1,id2,..."), useId: boolean, variant: "development"|"production" }`
- `POST /api/videos/stream` — Stream channel details in batches (SSE)
  - Body: `{ ids: base64("id1,id2,..."), useId: boolean, variant: "development"|"production" }`
- `GET /api/search?query=...&pageToken=...&variant=development|production` — Search channels

### Analysis

- `POST /api/analyze/stream` — Batched AI analysis (SSE)
  - Body:
    ```json
    {
      "channels": [
        {
          "channelId": "UC...",
          "userName": "@user",
          "title": "...",
          "channelName": "...",
          "description": "..."
        }
      ],
      "batchSize": 5
    }
    ```
  - SSE events: `started`, `progress`, `batch`, `complete`, `error`

### Cache

- `GET /api/cache/stats` — Cache metrics
- `DELETE /api/cache` — Clear all caches
- `POST /api/cache/invalidate` — Invalidate a specific channel cache `{ channelId, variant }`

## Request/Response Notes

- SSE responses send events with `event:<name>` and `data:<json>` lines, terminated by double newlines.
- Validation uses `express-validator` with detailed error payloads on `400`.
- Timeouts: default (`REQUEST_TIMEOUT`), SSE (`SSE_TIMEOUT`).

## Configuration

Create `.env` with the following keys:

```env
OPENAI_API_KEY=sk-...
DEV_YOUTUBE_API_KEY=...
YOUTUBE_API_KEY=...
NODE_ENV=development
PORT=3000
TRUST_PROXY=false
CORS_ORIGIN=*
CORS_CREDENTIALS=false
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX=100
REQUEST_TIMEOUT=30000
ANALYSIS_TIMEOUT=120000
SSE_TIMEOUT=300000
YOUTUBE_DAILY_QUOTA=10000
YOUTUBE_QUOTA_LOW_THRESHOLD=0.8
YOUTUBE_BATCH_SIZE=50
LOG_LEVEL=info
LOG_REQUESTS=true
```

Analysis configuration (`src/config/analysis.js`):

- Model: `gpt-4o-mini`
- Max tokens: `800`
- Temperature: `0.1`
- Batch size: `5`
- Cache TTL: `7 days`
- Rate limit delay: `500ms`

## Project Layout

```
src/
├── config/
│   ├── analysis.js         # Analysis configuration
│   └── index.js            # Central config/env
├── controllers/
│   ├── analysisController.js
│   ├── healthController.js
│   ├── quotaController.js
│   └── videoController.js
├── middleware/
│   ├── apiLogger.js
│   ├── performance.js
│   ├── requestId.js
│   ├── timeout.js
│   └── validation.js
├── routes/
│   └── index.js
├── services/
│   ├── analysisService.js
│   ├── videoService.js
│   ├── youtubeService.js
│   └── index.js
└── utils/
    ├── apiErrorHandler.js
    ├── cache.js
    ├── errors.js
    ├── logger.js
    ├── prompts.js
    └── retry.js
```

## Scripts

```bash
npm start  # Starts server with nodemon
```

## Testing (manual)

```bash
# Health
curl http://localhost:3000/api/health

# Analysis stream
curl -N -X POST http://localhost:3000/api/analyze/stream \
  -H "Content-Type: application/json" \
  -d '{"channels":[{"channelId":"UC123","userName":"@u","title":"t","channelName":"c"}]}'
```

## License

Private project — All rights reserved.
