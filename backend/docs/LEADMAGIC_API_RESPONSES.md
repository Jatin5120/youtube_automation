# Lead Magic API Response Analysis

## Test Results Summary

Based on testing with various email addresses, here's what we found:

## Response Statuses

### 1. **Valid Email** (`email_status: "valid"`)

- **Example**: `hello@linear.app`
- **Response**: `"email_status": "valid"`, `"message": "Email is valid."`
- **Credits**: 0.05 consumed
- **Action**: ✅ **ACCEPT** - Email is confirmed valid

### 2. **Catch-All Domain** (`email_status: "catch_all"`)

- **Example**: `info@google.com`
- **Response**: `"email_status": "catch_all"`, `"message": "Domain accepts all emails (catch-all)."`
- **Credits**: 0 consumed (free check)
- **Action**: ⚠️ **DECISION NEEDED** - Domain accepts all emails, but we can't confirm if this specific address exists

### 3. **Invalid Email** (`email_status: "invalid"`)

- **Examples**:
  - `test@gmail.com` - "Email address is invalid."
  - `test@nonexistentdomain12345xyz.com` - "Domain has no valid MX records"
- **Response**: `"email_status": "invalid"`, various messages
- **Credits**: 0.05 consumed
- **Action**: ❌ **REJECT** - Email is invalid

### 4. **Malformed Email** (HTTP 400)

- **Examples**: `invalid-email`, `notanemail@`, `@domain.com`, empty string
- **Response**: HTTP 400 with error structure:
  ```json
  {
    "success": false,
    "errors": [
      {
        "type": "invalid_request",
        "message": "Invalid email address",
        "code": "validation_error",
        "param": ["email"]
      }
    ]
  }
  ```
- **Credits**: 0 consumed
- **Action**: ❌ **REJECT** - Not even a valid email format

## Response Structure

### Successful Response (HTTP 200)

```json
{
  "email": "hello@linear.app",
  "email_status": "valid" | "invalid" | "catch_all",
  "credits_consumed": 0.05,
  "message": "Email is valid." | "Email address is invalid." | "Domain accepts all emails (catch-all).",
  "is_domain_catch_all": false,
  "mx_record": "linear.app",
  "mx_provider": "Google Workspace",
  "mx_security_gateway": false,
  "company_name": "linear",
  "company_industry": "computer software",
  "company_size": "51-200",
  "company_founded": 2019,
  "company_location": { ... },
  "company_linkedin_url": "linkedin.com/company/linearapp",
  "company_linkedin_id": "29309454",
  "company_facebook_url": null,
  "company_twitter_url": "twitter.com/linear_app",
  "company_type": "private"
}
```

### Error Response (HTTP 400)

```json
{
  "success": false,
  "errors": [
    {
      "type": "invalid_request",
      "message": "Invalid email address",
      "code": "validation_error",
      "param": ["email"]
    }
  ],
  "meta": {
    "request_id": "...",
    "timestamp": "2025-11-19T20:56:37.319Z"
  }
}
```

## Key Fields for Filtering

1. **`email_status`**: Primary field for validation

   - `"valid"` - ✅ Accept
   - `"catch_all"` - ⚠️ Decision needed
   - `"invalid"` - ❌ Reject

2. **`credits_consumed`**:

   - Valid/Invalid emails: 0.05 credits
   - Catch-all emails: 0 credits (free)
   - Malformed emails (400): 0 credits

3. **`message`**: Human-readable status message

4. **Company Information**: Available when domain is recognized (even for invalid emails)

## Recommendations for Implementation

### Option 1: Strict Filtering (Recommended)

- ✅ Accept: `email_status === "valid"`
- ❌ Reject: `email_status === "invalid"` or HTTP 400
- ❌ Reject: `email_status === "catch_all"` (too uncertain)

### Option 2: Lenient Filtering

- ✅ Accept: `email_status === "valid"` OR `email_status === "catch_all"`
- ❌ Reject: `email_status === "invalid"` or HTTP 400

### Option 3: Configurable Filtering

- Allow configuration of whether to accept catch-all emails
- Default to strict (reject catch-all)

## Rate Limits

- API allows up to 1,000 requests per minute
- Each valid/invalid check costs 0.05 credits
- Catch-all checks are free (0 credits)

## Error Handling

- HTTP 400: Malformed email format - reject immediately
- HTTP 200 with `email_status: "invalid"`: Reject
- HTTP 200 with `email_status: "catch_all"`: Decision needed
- HTTP 200 with `email_status: "valid"`: Accept
- Network errors: Retry with exponential backoff
