const { EmailsService } = require("../services");
const { ApifyError } = require("../utils/errors");
const Logger = require("../utils/logger");

class EmailsController {
  constructor() {
    this.emailsService = new EmailsService();
  }

  /**
   * Get emails from YouTube channel IDs
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   */
  async getEmailsFromChannelIds(req, res) {
    try {
      const { channelIds } = req.body;

      const results = await this.emailsService.fromChannelIds(channelIds);

      res.status(200).json({
        success: true,
        data: results,
        count: results.length,
        timestamp: new Date().toISOString(),
      });
    } catch (error) {
      Logger.error("Error in getEmailsFromChannelIds", {
        error: error.message,
        channelIds: req.body.channelIds?.length || 0,
      });

      const statusCode = error instanceof ApifyError ? error.statusCode : 500;

      res.status(statusCode).json({
        success: false,
        error: error.message,
        timestamp: new Date().toISOString(),
      });
    }
  }

  /**
   * Get emails from YouTube usernames
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   */
  async getEmailsFromUsernames(req, res) {
    try {
      const { usernames } = req.body;

      const results = await this.emailsService.fromUsernames(usernames);

      res.status(200).json({
        success: true,
        data: results,
        count: results.length,
        timestamp: new Date().toISOString(),
      });
    } catch (error) {
      Logger.error("Error in getEmailsFromUsernames", {
        error: error.message,
        usernames: req.body.usernames?.length || 0,
      });

      const statusCode = error instanceof ApifyError ? error.statusCode : 500;

      res.status(statusCode).json({
        success: false,
        error: error.message,
        timestamp: new Date().toISOString(),
      });
    }
  }
}

module.exports = EmailsController;
