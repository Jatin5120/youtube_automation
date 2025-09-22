// YouTube API Quota Management
class QuotaManager {
  constructor() {
    this.dailyQuota = 10000; // Default YouTube API daily quota
    this.usedQuota = 0;
    this.quotaResetTime = this.getNextMidnight();
    this.operationCosts = {
      "channels.list": 1,
      "search.list": 100,
      "playlists.list": 1,
      "playlistItems.list": 1,
      "videos.list": 1,
    };
  }

  getNextMidnight() {
    const now = new Date();
    const tomorrow = new Date(now);
    tomorrow.setDate(tomorrow.getDate() + 1);
    tomorrow.setHours(0, 0, 0, 0);
    return tomorrow.getTime();
  }

  // Check if quota is available for operation
  canMakeRequest(operation) {
    this.resetQuotaIfNeeded();
    const cost = this.operationCosts[operation] || 1;
    return this.usedQuota + cost <= this.dailyQuota;
  }

  // Record quota usage
  recordUsage(operation) {
    this.resetQuotaIfNeeded();
    const cost = this.operationCosts[operation] || 1;
    this.usedQuota += cost;
    console.log(
      `Quota used: ${this.usedQuota}/${this.dailyQuota} (${operation}: ${cost})`
    );
  }

  // Reset quota at midnight
  resetQuotaIfNeeded() {
    if (Date.now() >= this.quotaResetTime) {
      this.usedQuota = 0;
      this.quotaResetTime = this.getNextMidnight();
      console.log("Daily quota reset");
    }
  }

  // Get quota status
  getQuotaStatus() {
    this.resetQuotaIfNeeded();
    return {
      used: this.usedQuota,
      total: this.dailyQuota,
      remaining: this.dailyQuota - this.usedQuota,
      percentage: (this.usedQuota / this.dailyQuota) * 100,
      resetTime: new Date(this.quotaResetTime).toISOString(),
    };
  }

  // Check if quota is critically low
  isQuotaLow() {
    this.resetQuotaIfNeeded();
    return this.usedQuota > this.dailyQuota * 0.8; // 80% threshold
  }

  // Check if quota is exhausted
  isQuotaExhausted() {
    this.resetQuotaIfNeeded();
    return this.usedQuota >= this.dailyQuota;
  }
}

// Create singleton instance
const quotaManager = new QuotaManager();

module.exports = quotaManager;
