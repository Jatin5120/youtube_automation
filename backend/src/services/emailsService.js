const { ApifyClient } = require("apify-client");
const { retryWithBackoff } = require("../utils/retry");
const { ApifyError } = require("../utils/errors");
const Logger = require("../utils/logger");
const config = require("../config");

/**
 * Service for fetching emails from YouTube channels using Apify's YouTube Email Bulk Scraper.
 */
class EmailsService {
  constructor() {
    this._apifyClient = null;
  }

  /**
   * Get or initialize Apify client
   * @returns {ApifyClient}
   */
  _getApifyClient() {
    if (!this._apifyClient) {
      if (!config.apiKeys.apify) {
        throw new ApifyError(
          "Apify API token not configured. Please set APIFY_API_KEY environment variable."
        );
      }
      this._apifyClient = new ApifyClient({
        token: config.apiKeys.apify,
      });
    }
    return this._apifyClient;
  }

  /**
   * Convert channel IDs to YouTube channel URLs
   * @param {string[]} channelIds
   * @returns {string[]}
   */
  _channelIdsToUrls(channelIds) {
    return channelIds.map(
      (channelId) => `https://www.youtube.com/channel/${channelId}`
    );
  }

  /**
   * Convert usernames to YouTube handle URLs
   * @param {string[]} usernames
   * @returns {string[]}
   */
  _usernamesToUrls(usernames) {
    return usernames.map((username) => `https://www.youtube.com/@${username}`);
  }

  /**
   * Fetch emails from a list of YouTube URLs using Apify actor
   * @param {string[]} urls
   * @returns {Promise<string[]>}
   */
  async _getEmailsFromUrls(urls) {
    if (!urls || urls.length === 0) {
      return [];
    }

    urls = urls.map((url) => {
      return {
        url: url,
      };
    });

    return retryWithBackoff(async () => {
      try {
        const client = this._getApifyClient();

        // Start the actor with the URLs
        const { defaultDatasetId } = await client
          .actor(config.apify.actorId)
          .call({
            urls: urls,
          });

        if (!defaultDatasetId) {
          throw new ApifyError("No dataset ID returned from Apify actor");
        }

        // Fetch results from the dataset
        const { items } = await client.dataset(defaultDatasetId).listItems();

        if (!items || !Array.isArray(items)) {
          Logger.warn("No items returned from Apify dataset");
          return [];
        }

        // Extract emails from results
        const emailResults = [];
        for (const item of items) {
          const email = Array.isArray(item.email)
            ? item.email
                .filter((e) => typeof e === "string" && e.trim().length > 0)
                .map((e) => e.trim())
                .join(",")
            : "";
          if (email && typeof email === "string" && email.trim().length > 0) {
            emailResults.push(email.trim());
          }
        }

        return emailResults;
      } catch (error) {
        Logger.error("Error fetching emails from Apify", {
          error: error.message,
          errorStack: error.stack,
          urlsCount: urls.length,
          urls: urls,
        });

        if (error instanceof ApifyError) {
          throw error;
        }

        throw new ApifyError(`Failed to fetch emails: ${error.message}`, error);
      }
    });
  }

  /**
   * Fetch emails from YouTube channel IDs
   * @param {string[]} channelIds
   * @returns {Promise<string[]>}
   */
  async fromChannelIds(channelIds) {
    if (!channelIds || channelIds.length === 0) {
      return [];
    }

    try {
      const patchedIds = channelIds.map((id) =>
        id.startsWith("UU") ? "UC" + id.slice(2) : id
      );
      const urls = this._channelIdsToUrls(patchedIds);
      const results = await this._getEmailsFromUrls(urls);

      return results;
    } catch (error) {
      Logger.error("Error in fromChannelIds", {
        error: error.message,
        channelIdsCount: channelIds.length,
      });
      throw error;
    }
  }

  /**
   * Fetch emails from YouTube usernames
   * @param {string[]} usernames
   * @returns {Promise<string[]>}
   */
  async fromUsernames(usernames) {
    if (!usernames || usernames.length === 0) {
      return [];
    }

    try {
      const urls = this._usernamesToUrls(usernames);
      const results = await this._getEmailsFromUrls(urls);

      return results;
    } catch (error) {
      Logger.error("Error in fromUsernames", {
        error: error.message,
        usernamesCount: usernames.length,
      });
      throw error;
    }
  }
}

module.exports = EmailsService;
