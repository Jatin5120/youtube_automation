const { retryWithBackoff } = require("../utils/retry");
const { LeadMagicError } = require("../utils/errors");
const Logger = require("../utils/logger");
const config = require("../config");

/**
 * Service for validating emails using Lead Magic API
 */
class LeadMagicService {
  constructor() {
    this.apiKey = config.apiKeys.leadmagic || process.env.LEADMAGIC_API_KEY;
    this.apiUrl = "https://api.leadmagic.io/email-validate";
    this.timeout = config.leadmagic?.timeout || 10000;
    this.maxRetries = config.leadmagic?.maxRetries || 3;
    this.retryDelay = config.leadmagic?.retryDelay || 1000;
    this.concurrency = config.leadmagic?.concurrency || 10;
    this.acceptCatchAll = config.leadmagic?.acceptCatchAll !== false; // default: true
    this.failSafe = config.leadmagic?.failSafe !== false; // default: true
  }

  /**
   * Validate a single email address
   * @param {string} email
   * @returns {Promise<{valid: boolean, status: string, data: object}>}
   */
  async validateEmail(email) {
    if (!email || typeof email !== "string" || !email.trim()) {
      return {
        valid: false,
        status: "invalid",
        data: { error: "Empty or invalid email format" },
      };
    }

    if (!this.apiKey) {
      throw new LeadMagicError(
        "LeadMagic API key not configured. Please set LEADMAGIC_API_KEY environment variable."
      );
    }

    return retryWithBackoff(
      async () => {
        // Dynamic import for node-fetch v3 (ESM)
        const { default: fetch } = await import("node-fetch");

        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), this.timeout);

        try {
          const response = await fetch(this.apiUrl, {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              "X-API-Key": this.apiKey,
            },
            body: JSON.stringify({ email: email.trim() }),
            signal: controller.signal,
          });

          clearTimeout(timeoutId);

          // Handle HTTP 400 (malformed email)
          if (response.status === 400) {
            const errorData = await response.json().catch(() => ({}));
            return {
              valid: false,
              status: "invalid",
              data: {
                error: "Malformed email address",
                details: errorData,
              },
            };
          }

          if (!response.ok) {
            const errorText = await response.text();
            const error = new LeadMagicError(
              `LeadMagic API error: ${response.status} ${response.statusText}`,
              null,
              response.status
            );
            Logger.error(
              `LeadMagic API error: ${response.status} ${response.statusText}`,
              error,
              {
                email,
                response,
              }
            );
            throw error;
          }

          const data = await response.json();

          // Determine if email is valid based on status
          // valid: confirmed valid
          // catch_all: domain accepts all (configurable)
          // invalid: not valid
          const validStatuses = ["valid"];
          if (this.acceptCatchAll) {
            validStatuses.push("catch_all");
          }

          const isValid = validStatuses.includes(data.email_status);

          return {
            valid: isValid,
            status: data.email_status || "unknown",
            data: data,
          };
        } catch (error) {
          clearTimeout(timeoutId);

          if (error.name === "AbortError") {
            throw new LeadMagicError("Request timeout", error, 408);
          }

          if (error instanceof LeadMagicError) {
            throw error;
          }

          throw new LeadMagicError(
            `Failed to validate email: ${error.message}`,
            error
          );
        }
      },
      this.maxRetries,
      this.retryDelay
    );
  }

  /**
   * Validate multiple emails in parallel (with rate limiting)
   * @param {string[]} emails
   * @param {number} concurrency - Max concurrent requests (default: from config)
   * @returns {Promise<Array<{email: string, valid: boolean, status: string, data: object}>>}
   */
  async validateEmails(emails, concurrency = null) {
    if (!emails || !Array.isArray(emails) || emails.length === 0) {
      return [];
    }

    const maxConcurrency = concurrency || this.concurrency;
    const results = [];

    // Process in batches to respect rate limits
    for (let i = 0; i < emails.length; i += maxConcurrency) {
      const batch = emails.slice(i, i + maxConcurrency);
      const batchPromises = batch.map(async (email) => {
        try {
          const validation = await this.validateEmail(email);
          return {
            email,
            ...validation,
          };
        } catch (error) {
          Logger.error("Error validating email", error, {
            email,
            error,
          });

          // In fail-safe mode, treat errors as invalid (not throw)
          if (this.failSafe) {
            return {
              email,
              valid: false,
              status: "error",
              data: { error: error.message },
            };
          }

          throw error;
        }
      });

      const batchResults = await Promise.all(batchPromises);
      results.push(...batchResults);

      // Small delay between batches to avoid hitting rate limits
      if (i + maxConcurrency < emails.length) {
        await new Promise((resolve) => setTimeout(resolve, 100));
      }
    }

    return results;
  }

  /**
   * Filter valid emails from a list
   * @param {string[]} emails
   * @returns {Promise<string[]>} - Array of valid email addresses
   */
  async filterValidEmails(emails) {
    if (!emails || !Array.isArray(emails) || emails.length === 0) {
      return [];
    }

    // Handle comma-separated emails in strings
    const emailList = emails.flatMap((email) => {
      if (typeof email === "string" && email.includes(",")) {
        return email
          .split(",")
          .map((e) => e.trim())
          .filter(Boolean);
      }
      return email ? [email.trim()] : [];
    });

    const validationResults = await this.validateEmails(emailList);

    return validationResults
      .filter((result) => result.valid)
      .map((result) => result.email);
  }
}

module.exports = LeadMagicService;
