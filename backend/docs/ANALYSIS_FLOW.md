# Complete Analysis Flow Documentation

## Overview

This document traces the complete analysis flow from receiving channel data to generating the final report with analyzed names, titles, validated emails, and personalized email messages.

## Flow Diagram

```
Request → Controller → Service → [Fetch Emails → Filter Emails → Analyze Name+Title → Generate Email → Return Report]
```

## Step-by-Step Flow

### 1. Entry Point: Analysis Controller

**File**: `backend/src/controllers/analysisController.js`

**Method**: `analyzeStream(req, res)`

**Input**:

```json
{
  "channels": [
    {
      "channelId": "UC...",
      "userName": "...",
      "videoTitle": "...",
      "channelName": "...",
      "videoDescription": "...",
      "channelDescription": "..."
    }
  ],
  "batchSize": 5
}
```

**Process**:

- Sets up Server-Sent Events (SSE) stream
- Calls `analysisService.analyzeBatchWithSSE()`
- Handles progress updates, batch results, completion, and errors via SSE

---

### 2. Batch Processing: Analysis Service

**File**: `backend/src/services/analysisService.js`

**Method**: `analyzeBatchWithSSE()`

**Process**:

- Splits channels into batches (default: 5 channels per batch)
- Checks cache for each batch
- Processes non-cached batches sequentially
- Sends progress updates via SSE callbacks

**For each batch**, calls: `analyzeChannelsBatch(batch)`

---

### 3. Core Analysis: Analyze Channels Batch

**File**: `backend/src/services/analysisService.js`

**Method**: `analyzeChannelsBatch(channels)`

#### Step 3.1: Fetch Emails

**Method**: `_getEmailsFromChannels(channels)`

**Implementation**:

```javascript
// Line 124-139
async _getEmailsFromChannels(channels) {
  const emailPromises = channels.map((channel) =>
    this.emailsService.fromChannelIds([channel.channelId])
  );
  const emailsArray = await Promise.all(emailPromises);
  return emailsArray.map((arr) => arr[0] || "");
}
```

**Service**: `EmailsService.fromChannelIds()`

- **File**: `backend/src/services/emailsService.js`
- Converts channel IDs to YouTube URLs
- Calls Apify actor (`exporter24/youtube-email-bulk-scraper`)
- Returns array of email strings (comma-separated if multiple)

**Output**: Array of email strings, one per channel

```javascript
["email1@example.com,email2@example.com", "contact@channel.com", ...]
```

**Attaches emails to channels**:

```javascript
const channelsWithEmails = channels.map((ch, idx) => ({
  ...ch,
  rawEmails: emails[idx] || "",
}));
```

---

#### Step 3.2: Filter Emails (Validation)

**Method**: `_validateAndFilterChannels(channelsWithEmails)`

**Implementation**:

```javascript
// Line 146-264
async _validateAndFilterChannels(channelsWithEmails) {
  // 1. Extract all emails from channels
  // 2. Build email-to-channel mapping
  // 3. Validate emails using LeadMagic API
  // 4. Filter channels: keep only those with at least one valid email
  // 5. Return validChannels, emailValidationMap, originalIndices
}
```

**Service**: `LeadMagicService.validateEmails()`

- **File**: `backend/src/services/leadMagicService.js`
- Validates emails in parallel batches (concurrency: 10)
- Checks email status: `valid`, `catch_all`, or `invalid`
- Returns validation results with status

**Filtering Logic**:

- Channels with **no emails** → **KEPT** (pass through, will be analyzed)
- Channels with **at least one valid email** → **KEPT** (will be analyzed)
- Channels with **only invalid emails** → **FILTERED OUT** (will NOT be analyzed)

**Important**: Filtered channels are excluded from AI analysis (no name/title analysis, no email generation) and are **NOT included in the final response**. Only channels that passed email validation are returned.

**Output**:

```javascript
{
  validChannels: [...],           // Channels that passed validation
  emailValidationMap: {            // email -> {valid, status}
    "email1@example.com": {valid: true, status: "valid"},
    "email2@example.com": {valid: false, status: "invalid"}
  },
  originalIndices: [0, 2, 3, ...]  // Indices mapping back to original array
}
```

**Early Return**: If no valid channels remain, returns empty results array `{ results: [] }`.

---

#### Step 3.3: Analyze Name + Title

**Method**: `_getAnalysisResponseFromOpenAI(validChannels)`

**Important**: Only channels that passed email validation (or have no emails) are analyzed. Channels with only invalid emails are excluded from this step.

**Implementation**:

```javascript
// Line 357-433
async _getAnalysisResponseFromOpenAI(channels) {
  const prompt = await getNameTitlePrompts(channels);
  const response = await this.openai.chat.completions.create({
    model: "gpt-4.1-nano",
    messages: [
      { role: "system", content: prompt.systemPrompt },
      { role: "user", content: prompt.userPrompt }
    ],
    response_format: {
      type: "json_schema",
      json_schema: {
        name: "channel_analysis",
        schema: RESPONSE_SCHEMA
      }
    }
  });
  // Parse and validate response
}
```

**Prompts**: `getNameTitlePrompts(channels)`

- **File**: `backend/src/utils/prompts.js`
- **System Prompt**: Extracts `analyzedTitle` (3-6 words) and `analyzedName` (2-20 letters)
- **User Prompt**: Contains channel data in TOON format
- **Security**: Treats all channel data as untrusted plain text

**Output Schema**:

```json
{
  "results": [
    {
      "channelId": "UC...",
      "userName": "...",
      "analyzedTitle": "SaaS Growth",
      "analyzedName": "John"
    }
  ]
}
```

**Validation**:

- Checks response structure matches schema
- Validates all required fields present
- Ensures result count matches channel count

---

#### Step 3.4: Generate Email Message (Currently Skipped)

**Method**: `_getEmailResponseFromOpenAI(analysisResults, channels)`

**Status**: This method is **kept intact for future use** but is **currently skipped** in the implementation flow.

**Implementation**:

```javascript
// Line 451-462
async _getResponseFromOpenAI(channels) {
  const result = await this._getAnalysisResponseFromOpenAI(channels);

  // Skip AI email message generation - return empty emailMessage for all results
  // Keep _getEmailResponseFromOpenAI method intact for future use
  result.results = result.results.map((r) => ({
    ...r,
    emailMessage: "", // Empty email message
  }));

  return result;
}
```

**Note**: The `_getEmailResponseFromOpenAI` method (lines 542-639) is preserved for future use but is not called in the current flow. All results are returned with `emailMessage: ""`.

**Future Implementation** (when re-enabled):

The method would:

1. Prepare email inputs (merge analysis results with channel context)
2. Generate prompts using `getEmailPrompts(emailInputs)`
3. Call OpenAI with email generation schema
4. Merge email messages into results

**Email Inputs Structure** (for future reference):

```javascript
{
  channelId: result.channelId,
  analyzedName: result.analyzedName,
  analyzedTitle: result.analyzedTitle,
  videoDescription: channel?.latestVideoDescription || "",
  channelDescription: channel?.channelDescription || "",
  subscriberCount: channel?.subscriberCount || 0,
  viewCount: channel?.viewCount || 0,
  keywords: channel?.keywords || "",
  uploadFrequency: channel?.uploadFrequency || ""
}
```

---

#### Step 3.5: Map Results to Original Channels

**Method**: `_mapResultsToOriginalChannels()`

**Implementation**:

```javascript
// Line 397-432
_mapResultsToOriginalChannels(
  originalChannels,
  validChannels,
  aiResult,
  emailValidationMap,
  originalIndices
) {
  // 1. Create results array with only valid channels (filtered channels excluded)
  // 2. Map valid channels with AI results
  // 3. Filter emails to only valid ones
  // IMPORTANT: Only valid channels are included in the response
}
```

**Email Filtering**:

- Only includes emails that passed validation
- Filters out invalid emails from comma-separated strings

**Output Structure**:

```javascript
{
  results: [
    {
      channelId: "UC...",
      userName: "...",
      analyzedTitle: "SaaS Growth",
      analyzedName: "John",
      email: "valid@example.com", // Only valid emails
      emailMessage: "Hey John, saw your video...",
    },
    // Note: Filtered channels (no valid email) are NOT included in results
  ];
}
```

---

### 4. Final Report Structure

**Complete Result Object**:

```javascript
{
  results: [
    {
      channelId: "UC...", // Original channel ID
      userName: "...", // Original username
      analyzedTitle: "SaaS Growth", // Extracted from video title (3-6 words)
      analyzedName: "John", // Extracted from channel info (2-20 letters)
      email: "valid@example.com", // Validated emails only (comma-separated)
      emailMessage: "", // Empty (email generation currently skipped)
    },
  ];
}
```

**Note**: Only channels that passed email validation are included in the results array. Filtered channels (channels with only invalid emails) are excluded.

**Returned via SSE**:

- `started` event: Analysis started
- `progress` event: Progress updates
- `batch` event: Batch results (contains full result structure)
- `complete` event: Analysis complete
- `error` event: Error occurred

---

## Key Components

### Services

1. **EmailsService** (`emailsService.js`)

   - Fetches emails from YouTube channels using Apify
   - Returns comma-separated email strings

2. **LeadMagicService** (`leadMagicService.js`)

   - Validates emails via LeadMagic API
   - Filters valid/invalid emails
   - Handles catch-all domains (configurable)

3. **AnalysisService** (`analysisService.js`)
   - Orchestrates entire analysis flow
   - Manages caching and batch processing
   - Handles OpenAI API calls

### Prompts

1. **Name/Title Analysis** (`getNameTitlePrompts`)

   - Extracts business theme from video title
   - Extracts personal name from channel info
   - Security-hardened against injection attacks

2. **Email Generation** (`getEmailPrompts`)
   - Generates personalized cold emails
   - 4-part structure: Greeting, Personalization, Bridge, Close
   - Unique for each channel

### Configuration

**File**: `backend/src/config/analysis.js`

- **OpenAI**: Model, temperature, max tokens, timeout
- **Cache**: TTL (7 days), max entries (5000)
- **Batch**: Channels per batch (5), rate limit delay (500ms)
- **Schemas**: Response schemas for JSON mode

---

## Error Handling

### Email Fetching Errors

- **Apify API failures**: Retry with exponential backoff
- **Empty results**: Returns empty string for that channel
- **Network errors**: Logged and propagated

### Email Validation Errors

- **API failures**: Fail-safe mode (proceeds with all channels if enabled)
- **Invalid emails**: Filtered out, channel removed from analysis
- **Timeout**: Retry with backoff

### OpenAI Errors

- **Timeout**: AbortError caught, re-thrown as AnalysisError (handled by outer catch)
- **Parse errors**: Logged with detailed context, throws AnalysisError
- **Validation errors**: Logged with channel counts and IDs, throws AnalysisError with details
- **AI Analysis Failure**: Caught in inner try-catch, generates fallback results for valid channels only

### Fallback Results

- **Method**: `_generateFallbackResults(channels)`
- **Important**: Only generates fallback for `validChannels` (channels that passed email validation)
- Extracts basic info from channel data (title from videoTitle, name from userName/channelName)
- Provides safe defaults when AI analysis fails
- Results are mapped back using `_mapResultsToOriginalChannels` to maintain consistency

### Batch Processing Errors

- **Batch-level errors**: Caught and logged, processing continues with remaining batches
- **Fatal errors**: Caught by outer try-catch, sent via SSE error event and stream ends
- **Error logging**: Enhanced with detailed context (error message, batch size, stack trace)

---

## Caching

**Cache Key Generation**:

- Based on channel IDs, video titles, and channel names
- MD5 hash of normalized channel data

**Cache Strategy**:

- Check cache before processing
- Store results after successful analysis
- TTL: 7 days
- Mutex prevents race conditions

---

## Performance Optimizations

1. **Batch Processing**: Processes multiple channels in single AI call
2. **Parallel Email Fetching**: Uses `Promise.all()` for concurrent requests
3. **Parallel Email Validation**: Batched with concurrency limit (10)
4. **Cache Pre-check**: Checks all batches before processing
5. **Rate Limiting**: 500ms delay between batches

---

## Data Flow Summary

```
Input Channels
    ↓
[1] Fetch Emails (Apify) → rawEmails attached
    ↓
[2] Validate Emails (LeadMagic) → Filter invalid channels
    ↓
[3] Analyze Name+Title (OpenAI) → analyzedTitle, analyzedName (only for valid channels)
    ↓
[4] Generate Email (OpenAI) → emailMessage (only for valid channels)
    ↓
[5] Map to Original Structure → Filter valid emails, exclude filtered channels
    ↓
Final Report (SSE stream) - Only contains channels that passed email validation
```

---

## Testing the Flow

### Manual Test

```bash
curl -X POST http://localhost:3000/api/analyze/stream \
  -H "Content-Type: application/json" \
  -d '{
    "channels": [
      {
        "channelId": "UC_x5XG1OV2P6uZZ5FSM9Ttw",
        "userName": "example",
        "videoTitle": "How to Build a SaaS Business",
        "channelName": "Example Channel",
        "videoDescription": "Learn how to build...",
        "channelDescription": "Tech entrepreneur..."
      }
    ],
    "batchSize": 5
  }'
```

### Expected SSE Events

```
event: started
data: {"current":0,"total":1,"message":"Starting batch analysis..."}

event: progress
data: {"current":1,"total":1,"message":"Analyzed 1 of 1 channels"}

event: batch
data: {"data":[{"channelId":"UC...","userName":"...","analyzedTitle":"SaaS Growth","analyzedName":"John","email":"valid@example.com","emailMessage":""}]}

event: complete
data: {"success":true}
```

---

## Notes

1. **Email Validation**: Channels without emails are kept (pass through and analyzed)
2. **Filtered Channels**:
   - Channels with only invalid emails are **NOT analyzed** (no name/title extraction, no email generation)
   - Filtered channels are **excluded from the response** (not included in results array)
   - Only channels that passed email validation are returned
3. **Email Filtering**: Only validated emails included in final result
4. **Security**: All channel data treated as untrusted plain text
5. **Error Recovery**:
   - Fallback results generated only for valid channels when AI analysis fails
   - Batch-level errors are logged but don't stop processing
   - Only fatal errors stop the entire process
6. **SSE Streaming**: Real-time progress updates to frontend
7. **Error Handling**: Enhanced error logging with detailed context for debugging

---

## FAQ

### Q: If an email is filtered as invalid, do we still analyze the names and title for that channel?

**A: No.** Channels with only invalid emails are filtered out **before** AI analysis. They do not receive:

- Name/title analysis (`analyzedTitle`, `analyzedName` will be empty)
- Email message generation (`emailMessage` will be empty)

**Code Reference**:

- Line 722: `_getResponseFromOpenAI(validChannels)` - Only valid channels are analyzed
- Line 397-432: `_mapResultsToOriginalChannels()` only includes valid channels in results

### Q: Are filtered channels removed from the response or do they remain with empty data?

**A: They are removed from the response.** Only channels that passed email validation are included in the results array. Filtered channels (channels with only invalid emails) are completely excluded.

**Code Reference**:

- Line 404-405: `_mapResultsToOriginalChannels()` creates results array with only valid channels
- Line 706-712: Early return if no valid channels returns empty results array `{ results: [] }`

### Q: What happens if AI analysis fails for a batch?

**A: Fallback results are generated for valid channels only.** The error is caught in an inner try-catch block, and `_generateFallbackResults()` is called with `validChannelsForErrorHandling`. The fallback extracts basic information from channel data (title from videoTitle, name from userName/channelName) and provides safe defaults. Processing continues normally after fallback generation.

**Code Reference**:

- Line 721-747: AI analysis wrapped in try-catch, fallback generated for valid channels on error
- Line 778-832: `_generateFallbackResults()` extracts basic info from channel data

### Q: What happens if a batch fails during processing?

**A: The error is logged and processing continues with remaining batches.** Batch-level errors are caught in the batch processing loop, logged with detailed context, and the loop continues to the next batch. Only fatal errors (caught by outer try-catch) stop the entire process and send an error event via SSE.

**Code Reference**:

- Line 932-970: Batch processing wrapped in try-catch, errors logged but processing continues
- Line 985-988: Outer try-catch handles fatal errors and sends error event via SSE
