// OpenAI Token Cost Calculator and Tracker
const Logger = require("./logger");

// OpenAI model pricing per 1,000,000 tokens (as of November 7, 2025)
// Prices in USD per 1M tokens
const MODEL_PRICING = {
  // GPT-5 Series
  "gpt-5": {
    input: 1.25, // $1.25 per 1M input tokens
    output: 10.0, // $10.00 per 1M output tokens
  },
  "gpt-5-mini": {
    input: 0.25, // $0.25 per 1M input tokens
    output: 2.0, // $2.00 per 1M output tokens
  },
  "gpt-5-nano": {
    input: 0.05, // $0.05 per 1M input tokens
    output: 0.4, // $0.40 per 1M output tokens
  },
  // GPT-4.1 Series
  "gpt-4.1": {
    input: 2.0, // $2.00 per 1M input tokens
    output: 8.0, // $8.00 per 1M output tokens
  },
  "gpt-4.1-mini": {
    input: 0.4, // $0.40 per 1M input tokens
    output: 1.6, // $1.60 per 1M output tokens
  },
  "gpt-4.1-nano": {
    input: 0.1, // $0.10 per 1M input tokens
    output: 0.4, // $0.40 per 1M output tokens
  },
  // GPT-4o Series
  "gpt-4o": {
    input: 5.0, // $5.00 per 1M input tokens
    output: 20.0, // $20.00 per 1M output tokens
  },
  "gpt-4o-mini": {
    input: 0.6, // $0.60 per 1M input tokens
    output: 2.4, // $2.40 per 1M output tokens
  },
  // Legacy models (if still available)
  "gpt-4-turbo": {
    input: 10.0, // $10.00 per 1M input tokens
    output: 30.0, // $30.00 per 1M output tokens
  },
  "gpt-3.5-turbo": {
    input: 0.5, // $0.50 per 1M input tokens
    output: 1.5, // $1.50 per 1M output tokens
  },
  // Fallback for unknown models (using gpt-4.1-nano pricing)
  default: {
    input: 0.1,
    output: 0.4,
  },
};

class TokenCostManager {
  constructor() {
    this.dailyCost = 0;
    this.dailyTokens = {
      input: 0,
      output: 0,
      total: 0,
    };
    this.costResetTime = this.getNextMidnight();
    this.totalCost = 0; // Lifetime total
    this.totalTokens = {
      input: 0,
      output: 0,
      total: 0,
    };
  }

  getNextMidnight() {
    const now = new Date();
    const tomorrow = new Date(now);
    tomorrow.setDate(tomorrow.getDate() + 1);
    tomorrow.setHours(0, 0, 0, 0);
    return tomorrow.getTime();
  }

  // Get pricing for a specific model
  getPricing(model) {
    // Normalize model name (handle variations)
    const normalizedModel = model?.toLowerCase() || "default";

    // Check for exact match
    if (MODEL_PRICING[normalizedModel]) {
      return MODEL_PRICING[normalizedModel];
    }

    // Check for partial matches
    // GPT-5 series
    if (normalizedModel.includes("5-nano")) {
      return MODEL_PRICING["gpt-5-nano"];
    }
    if (normalizedModel.includes("5-mini")) {
      return MODEL_PRICING["gpt-5-mini"];
    }
    if (normalizedModel.includes("5") && !normalizedModel.includes("4")) {
      return MODEL_PRICING["gpt-5"];
    }
    // GPT-4.1 series
    if (
      normalizedModel.includes("4.1-nano") ||
      normalizedModel.includes("4.1nano")
    ) {
      return MODEL_PRICING["gpt-4.1-nano"];
    }
    if (
      normalizedModel.includes("4.1-mini") ||
      normalizedModel.includes("4.1mini")
    ) {
      return MODEL_PRICING["gpt-4.1-mini"];
    }
    if (normalizedModel.includes("4.1")) {
      return MODEL_PRICING["gpt-4.1"];
    }
    // GPT-4o series
    if (normalizedModel.includes("4o-mini")) {
      return MODEL_PRICING["gpt-4o-mini"];
    }
    if (normalizedModel.includes("4o")) {
      return MODEL_PRICING["gpt-4o"];
    }
    // Legacy models
    if (normalizedModel.includes("4-turbo")) {
      return MODEL_PRICING["gpt-4-turbo"];
    }
    if (normalizedModel.includes("3.5")) {
      return MODEL_PRICING["gpt-3.5-turbo"];
    }

    // Default fallback
    Logger.warn(`Unknown model pricing for: ${model}, using default pricing`);
    return MODEL_PRICING.default;
  }

  // Calculate cost from usage data
  calculateCost(usage, model) {
    if (!usage) {
      Logger.warn("No usage data provided for cost calculation");
      return {
        inputTokens: 0,
        outputTokens: 0,
        totalTokens: 0,
        inputCost: 0,
        outputCost: 0,
        totalCost: 0,
      };
    }

    const promptTokens = usage.prompt_tokens || 0;
    const completionTokens = usage.completion_tokens || 0;
    const totalTokens = usage.total_tokens || promptTokens + completionTokens;

    const pricing = this.getPricing(model);
    // Pricing is per 1M tokens, so divide by 1,000,000
    const inputCost = (promptTokens / 1000000) * pricing.input;
    const outputCost = (completionTokens / 1000000) * pricing.output;
    const totalCost = inputCost + outputCost;

    return {
      inputTokens: promptTokens,
      outputTokens: completionTokens,
      totalTokens: totalTokens,
      inputCost: inputCost,
      outputCost: outputCost,
      totalCost: totalCost,
      model: model,
    };
  }

  // Record usage and calculate cost
  recordUsage(usage, model, operation = "unknown") {
    this.resetCostIfNeeded();

    const costData = this.calculateCost(usage, model);

    // Update daily totals
    this.dailyCost += costData.totalCost;
    this.dailyTokens.input += costData.inputTokens;
    this.dailyTokens.output += costData.outputTokens;
    this.dailyTokens.total += costData.totalTokens;

    // Update lifetime totals
    this.totalCost += costData.totalCost;
    this.totalTokens.input += costData.inputTokens;
    this.totalTokens.output += costData.outputTokens;
    this.totalTokens.total += costData.totalTokens;

    // Log the cost
    Logger.info(`[Token Cost] ${operation} - Model: ${model || "unknown"}`, {
      tokens: {
        input: costData.inputTokens,
        output: costData.outputTokens,
        total: costData.totalTokens,
      },
      cost: {
        input: `$${costData.inputCost.toFixed(6)}`,
        output: `$${costData.outputCost.toFixed(6)}`,
        total: `$${costData.totalCost.toFixed(6)}`,
      },
      daily: {
        cost: `$${this.dailyCost.toFixed(4)}`,
        tokens: this.dailyTokens.total,
      },
      lifetime: {
        cost: `$${this.totalCost.toFixed(4)}`,
        tokens: this.totalTokens.total,
      },
    });

    return costData;
  }

  // Reset daily cost at midnight
  resetCostIfNeeded() {
    if (Date.now() >= this.costResetTime) {
      Logger.info(
        `[Token Cost] Daily reset - Previous day cost: $${this.dailyCost.toFixed(
          4
        )}, Tokens: ${this.dailyTokens.total}`
      );
      this.dailyCost = 0;
      this.dailyTokens = {
        input: 0,
        output: 0,
        total: 0,
      };
      this.costResetTime = this.getNextMidnight();
    }
  }

  // Get cost status
  getCostStatus() {
    this.resetCostIfNeeded();
    return {
      daily: {
        cost: this.dailyCost,
        costFormatted: `$${this.dailyCost.toFixed(4)}`,
        tokens: this.dailyTokens,
      },
      lifetime: {
        cost: this.totalCost,
        costFormatted: `$${this.totalCost.toFixed(4)}`,
        tokens: this.totalTokens,
      },
      resetTime: new Date(this.costResetTime).toISOString(),
    };
  }
}

// Create singleton instance
const tokenCostManager = new TokenCostManager();

module.exports = tokenCostManager;
