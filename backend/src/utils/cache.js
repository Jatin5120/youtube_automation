// Enhanced in-memory cache implementation with monitoring
const Logger = require("./logger");

class MemoryCache {
  constructor(ttl = 3600000, maxSize = 10000, name = "MemoryCache") {
    this.cache = new Map();
    this.ttl = ttl;
    this.maxSize = maxSize;
    this.name = name;
    this.accessOrder = new Map(); // For LRU eviction

    // Statistics
    this.stats = {
      hits: 0,
      misses: 0,
      sets: 0,
      deletes: 0,
      evictions: 0,
    };
  }

  set(key, value, customTtl = null) {
    // Check if we need to evict entries
    if (this.cache.size >= this.maxSize) {
      this._evictLRU();
    }

    const expiry = Date.now() + (customTtl || this.ttl);
    this.cache.set(key, {
      value,
      expiry,
    });

    // Update access order
    this.accessOrder.set(key, Date.now());

    // Update statistics
    this.stats.sets++;

    // Logger.cache("set", key, true, { cacheName: this.name });
  }

  get(key) {
    const item = this.cache.get(key);

    if (!item) {
      this.stats.misses++;
      // Logger.cache("get", key, false, { cacheName: this.name });
      return null;
    }

    if (Date.now() > item.expiry) {
      this.cache.delete(key);
      this.accessOrder.delete(key);
      this.stats.misses++;
      // Logger.cache("get", key, false, {
      //   cacheName: this.name,
      //   reason: "expired",
      // });
      return null;
    }

    // Update access order for LRU
    this.accessOrder.set(key, Date.now());
    this.stats.hits++;
    // Logger.cache("get", key, true, { cacheName: this.name });
    return item.value;
  }

  has(key) {
    return this.get(key) !== null;
  }

  delete(key) {
    this.accessOrder.delete(key);
    const deleted = this.cache.delete(key);
    if (deleted) {
      this.stats.deletes++;
      // Logger.cache("delete", key, true, { cacheName: this.name });
    }
    return deleted;
  }

  clear() {
    this.cache.clear();
    this.accessOrder.clear();
  }

  // LRU eviction method
  _evictLRU() {
    if (this.cache.size === 0) return;

    // Find least recently used key
    let oldestKey = null;
    let oldestTime = Infinity;

    for (const [key, time] of this.accessOrder.entries()) {
      if (time < oldestTime) {
        oldestTime = time;
        oldestKey = key;
      }
    }

    if (oldestKey) {
      this.cache.delete(oldestKey);
      this.accessOrder.delete(oldestKey);
      this.stats.evictions++;
      // Logger.cache("evict", oldestKey, true, { cacheName: this.name });
    }
  }

  // Cleanup expired entries to prevent memory leaks
  _cleanupExpiredEntries() {
    const now = Date.now();
    const expiredKeys = [];

    for (const [key, item] of this.cache.entries()) {
      if (now > item.expiry) {
        expiredKeys.push(key);
      }
    }

    // Remove expired entries
    for (const key of expiredKeys) {
      this.cache.delete(key);
      this.accessOrder.delete(key);
      this.stats.evictions++;
    }

    if (expiredKeys.length > 0) {
      // Logger.cache(
      //   "cleanup",
      //   `Removed ${expiredKeys.length} expired entries`,
      //   true,
      //   {
      //     cacheName: this.name,
      //   }
      // );
    }
  }

  // Get cache statistics
  getStats() {
    // Cleanup expired entries before returning stats
    this._cleanupExpiredEntries();

    const now = Date.now();
    let validEntries = 0;
    let expiredEntries = 0;

    for (const [key, item] of this.cache.entries()) {
      if (now > item.expiry) {
        expiredEntries++;
      } else {
        validEntries++;
      }
    }

    const hitRate =
      this.stats.hits + this.stats.misses > 0
        ? (
            (this.stats.hits / (this.stats.hits + this.stats.misses)) *
            100
          ).toFixed(2)
        : 0;

    return {
      name: this.name,
      totalEntries: this.cache.size,
      validEntries,
      expiredEntries,
      memoryUsage: process.memoryUsage(),
      statistics: {
        hits: this.stats.hits,
        misses: this.stats.misses,
        sets: this.stats.sets,
        deletes: this.stats.deletes,
        evictions: this.stats.evictions,
        hitRate: `${hitRate}%`,
      },
    };
  }
}

// Create cache instances for different data types with optimized TTLs
const channelStaticCache = new MemoryCache(86400000, 10000, "ChannelStatic"); // 24 hours for static channel data
const channelStatsCache = new MemoryCache(21600000, 10000, "ChannelStats"); // 6 hours for channel statistics
const searchCache = new MemoryCache(900000, 5000, "Search"); // 15 minutes for search results
const usernameToIdCache = new MemoryCache(86400000, 10000, "UsernameToId"); // 24 hours for username->ID mapping

// Cache management utilities
class CacheManager {
  static getChannelStaticKey(channelId, variant) {
    return `channel_static_${channelId}_${variant}`;
  }

  static getChannelStatsKey(channelId, variant) {
    return `channel_stats_${channelId}_${variant}`;
  }

  static getUsernameKey(username, variant) {
    return `username_${username}_${variant}`;
  }

  // Cache invalidation methods
  static invalidateChannelData(channelId, variant) {
    const staticKey = this.getChannelStaticKey(channelId, variant);
    const statsKey = this.getChannelStatsKey(channelId, variant);

    channelStaticCache.delete(staticKey);
    channelStatsCache.delete(statsKey);
  }

  // Get cache statistics
  static getCacheStats() {
    return {
      channelStatic: channelStaticCache.getStats(),
      channelStats: channelStatsCache.getStats(),
      search: searchCache.getStats(),
      username: usernameToIdCache.getStats(),
    };
  }
}

module.exports = {
  channelStaticCache,
  channelStatsCache,
  searchCache,
  usernameToIdCache,
  MemoryCache,
  CacheManager,
};
