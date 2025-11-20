# Email Fetching Implementation

## Overview

This implementation adds email fetching functionality using Apify's YouTube Email Bulk Scraper actor. The system allows fetching emails from YouTube channels using either channel IDs or usernames.

## Architecture

### Services

- **EmailsService** (`src/services/emailsService.js`): Core service for email fetching
  - `fromChannelIds(channelIds)`: Returns `string[]` (array of email strings)
  - `fromUsernames(usernames)`: Returns `string[]` (array of email strings)
  - `_getEmailsFromUrls(urls)`: Private method that calls Apify actor, returns `string[]`

### Controllers

- **EmailsController** (`src/controllers/emailsController.js`): HTTP request handlers
  - `getEmailsFromChannelIds(req, res)`: Handle channel ID requests
  - `getEmailsFromUsernames(req, res)`: Handle username requests

### Routes

- `POST /api/emails/channels`: Fetch emails from channel IDs
- `POST /api/emails/usernames`: Fetch emails from usernames

## Configuration

### Environment Variables

```bash
APIFY_API_KEY=your_apify_api_key_here
APIFY_TIMEOUT=300000  # Optional: 5 minutes default
APIFY_MAX_RETRIES=3   # Optional: 3 retries default
```

### Config Updates

- Added Apify configuration to `src/config/index.js`
- Added ApifyError class to `src/utils/errors.js`

## API Endpoints

### 1. Fetch Emails from Channel IDs

```bash
POST /api/emails/channels
Content-Type: application/json

{
  "channelIds": ["UC_x5XG1OV2P6uZZ5FSM9Ttw", "UCBJycsmduvYEL83R_U4JriQ"]
}
```

**Response:**

```json
{
  "success": true,
  "data": ["contact@example.com,business@example.com", "contact@abc.com"],
  "count": 1,
  "timestamp": "2025-10-23T19:30:00.000Z"
}
```

**Note**: The current implementation returns an array of email strings. Multiple emails per channel are joined with commas. There is no mapping between channelIds and the returned emails.

### 2. Fetch Emails from Usernames

```bash
POST /api/emails/usernames
Content-Type: application/json

{
  "usernames": ["mrbeast", "pewdiepie"]
}
```

**Response:**

```json
{
  "success": true,
  "data": [
    "business@mrbeast.com,collabs@mrbeast.com",
    "business@pewdiepie.com"
  ],
  "count": 1,
  "timestamp": "2025-10-23T19:30:00.000Z"
}
```

**Note**: The current implementation returns an array of email strings. Multiple emails per username are joined with commas. There is no mapping between usernames and the returned emails.

## Validation

### Channel IDs

- Must be array with 1-100 elements
- Each channelId must be valid YouTube channel ID format (UC...)
- Regex: `/^UC[a-zA-Z0-9_-]{22}$/`

### Usernames

- Must be array with 1-100 elements
- Each username must contain only alphanumeric characters, underscores, and hyphens
- Regex: `/^[a-zA-Z0-9_-]+$/`

## Error Handling

### Common Errors

- **400 Bad Request**: Validation errors (invalid input format)
- **500 Internal Server Error**: Service errors (Apify API issues, network problems)

### Error Response Format

```json
{
  "success": false,
  "error": "Error message",
  "timestamp": "2025-10-23T19:30:00.000Z"
}
```

## Service Injection

The EmailsService can be injected into other controllers using dependency injection:

```javascript
const { EmailsService } = require("../services");

// In another controller
class SomeController {
  constructor() {
    this.emailsService = new EmailsService();
  }

  async someMethod() {
    const emails = await this.emailsService.fromChannelIds([
      "UC_x5XG1OV2P6uZZ5FSM9Ttw",
    ]);
    // Use emails...
  }
}
```

## Implementation Details

### URL Format Conversion

- **Channel IDs**: `https://www.youtube.com/channel/{channelId}`
- **Usernames**: `https://www.youtube.com/@${username}`

**Important**: The service converts URLs to `{ url: url }` objects before sending to Apify actor.

### Apify Actor Integration

- Uses `exporter24/youtube-email-bulk-scraper` actor
- Implements retry logic with exponential backoff
- Handles pagination for large result sets
- Returns only successful results with emails
- **Response Format**: Array of objects with `{ email: string[], status: "succ" }` structure

### Response Processing

The Apify actor returns an array of objects where each object contains:

- `email`: Array of email strings found for the channel
- `status`: Success status (typically "succ")

**Example Response:**

```json
[
  {
    "email": ["airesearch.studio@gmail.com"],
    "status": "succ"
  },
  {
    "email": ["writetothinkschool@gmail.com", "collabs@thethinkschool.com"],
    "status": "succ"
  }
]
```

The service processes this response by:

1. Iterating through each result object
2. Extracting emails from the `email` array
3. Filtering out empty or invalid emails
4. Joining multiple emails with commas into a single string
5. Returning an array of email strings (not objects)
6. **No mapping**: The service does not map results back to original channelIds/usernames

**Current Implementation Issue**: The service currently returns just email strings without any mapping to the original input channelIds/usernames.

### Caching and Performance

- Uses existing retry mechanism from `utils/retry.js`
- Implements proper error handling with custom `ApifyError` class
- Logs all operations for debugging and monitoring

## Testing

### Manual Testing

```bash
# Test channel IDs
curl -X POST http://localhost:3000/api/emails/channels \
  -H "Content-Type: application/json" \
  -d '{"channelIds": ["UC_x5XG1OV2P6uZZ5FSM9Ttw"]}'

# Test usernames
curl -X POST http://localhost:3000/api/emails/usernames \
  -H "Content-Type: application/json" \
  -d '{"usernames": ["mrbeast"]}'

# Test validation
curl -X POST http://localhost:3000/api/emails/channels \
  -H "Content-Type: application/json" \
  -d '{"channelIds": ["invalid-id"]}'
```

## Dependencies

- `apify-client`: ^2.19.1 (installed)
- Existing project dependencies (express, dotenv, etc.)

## Files Modified/Created

### New Files

- `src/services/emailsService.js`
- `src/controllers/emailsController.js`

### Modified Files

- `src/config/index.js` - Added Apify configuration
- `src/utils/errors.js` - Added ApifyError class
- `src/middleware/validation.js` - Added email validation
- `src/controllers/index.js` - Export EmailsController
- `src/services/index.js` - Export EmailsService
- `src/routes/index.js` - Added email routes
- `package.json` - Added apify-client dependency

## Notes

1. **API Token Required**: The implementation requires a valid Apify API token to function
2. **Rate Limiting**: Subject to Apify's rate limits and pricing
3. **Error Handling**: Comprehensive error handling with proper HTTP status codes
4. **Validation**: Strict input validation to prevent invalid requests
5. **Logging**: All operations are logged for debugging and monitoring
6. **Dependency Injection**: EmailsService uses instance methods and can be injected into other controllers
7. **Multiple Emails**: The service can return multiple emails per channel if found (joined with commas)
8. **No Mapping**: Current implementation does not map emails back to original channelIds/usernames

## Future Enhancements

1. **Caching**: Add caching for frequently requested channels
2. **Batch Processing**: Implement batch processing for large requests
3. **Rate Limiting**: Add rate limiting specific to email endpoints
4. **Metrics**: Add metrics collection for email fetching operations
5. **Webhooks**: Add webhook support for async email fetching
