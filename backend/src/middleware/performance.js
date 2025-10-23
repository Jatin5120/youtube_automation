const Logger = require("../utils/logger");

// Performance monitoring middleware
function performanceMonitor(req, res, next) {
  const startTime = Date.now();
  const startMemory = process.memoryUsage();

  // Override res.end to capture performance metrics
  const originalEnd = res.end;
  res.end = function (...args) {
    const endTime = Date.now();
    const endMemory = process.memoryUsage();
    const responseTime = endTime - startTime;

    // Log performance metrics for slow requests
    if (responseTime > 1000) {
      // Log requests taking more than 1 second
      Logger.performance("Slow request", responseTime, {
        method: req.method,
        url: req.url,
        statusCode: res.statusCode,
        memoryDelta: {
          rss: endMemory.rss - startMemory.rss,
          heapUsed: endMemory.heapUsed - startMemory.heapUsed,
        },
      });
    }

    // Log memory usage for high memory requests
    const memoryIncrease = endMemory.heapUsed - startMemory.heapUsed;
    if (memoryIncrease > 10 * 1024 * 1024) {
      // More than 10MB increase
      Logger.warn("High memory usage request", {
        method: req.method,
        url: req.url,
        memoryIncrease: `${Math.round(memoryIncrease / 1024 / 1024)}MB`,
      });
    }

    originalEnd.apply(this, args);
  };

  next();
}

// Memory monitoring
function memoryMonitor() {
  const memory = process.memoryUsage();
  const memoryMB = {
    rss: Math.round(memory.rss / 1024 / 1024),
    heapTotal: Math.round(memory.heapTotal / 1024 / 1024),
    heapUsed: Math.round(memory.heapUsed / 1024 / 1024),
    external: Math.round(memory.external / 1024 / 1024),
  };

  // Log if memory usage is high
  if (memoryMB.heapUsed > 500) {
    // More than 500MB
    Logger.warn("High memory usage detected", memoryMB);
  }

  return memoryMB;
}

// CPU monitoring
function cpuMonitor() {
  const cpuUsage = process.cpuUsage();
  return {
    user: cpuUsage.user,
    system: cpuUsage.system,
  };
}

module.exports = {
  performanceMonitor,
  memoryMonitor,
  cpuMonitor,
};
