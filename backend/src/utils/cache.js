// Simple in-memory cache implementation
class MemoryCache {
  constructor(ttl = 3600000) {
    // Default 1 hour TTL
    this.cache = new Map();
    this.ttl = ttl;
  }

  set(key, value, customTtl = null) {
    const expiry = Date.now() + (customTtl || this.ttl);
    this.cache.set(key, {
      value,
      expiry,
    });
  }

  get(key) {
    const item = this.cache.get(key);

    if (!item) {
      return null;
    }

    if (Date.now() > item.expiry) {
      this.cache.delete(key);
      return null;
    }

    return item.value;
  }

  has(key) {
    return this.get(key) !== null;
  }

  delete(key) {
    return this.cache.delete(key);
  }

  clear() {
    this.cache.clear();
  }

  // Get cache statistics
  getStats() {
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

    return {
      totalEntries: this.cache.size,
      validEntries,
      expiredEntries,
      memoryUsage: process.memoryUsage(),
    };
  }
}

// Create cache instances for different data types
const channelCache = new MemoryCache(1800000); // 30 minutes for channel data
const searchCache = new MemoryCache(900000); // 15 minutes for search results
const videoCache = new MemoryCache(300000); // 5 minutes for video data

module.exports = {
  channelCache,
  searchCache,
  videoCache,
  MemoryCache,
};
