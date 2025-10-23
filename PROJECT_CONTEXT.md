# Project Context

## Overview

YouTube Automation is a full-stack system for YouTube channel discovery and analysis to support outreach. It combines batched AI analysis with real-time streaming and robust caching.

## Problem Statement

- Manual channel analysis is slow and inconsistent
- Processing large batches is operationally expensive
- Extracting accurate names and insights is error-prone

## Solution

- Batched AI analysis with OpenAI Chat Completions
- Real-time progress via Server-Sent Events (SSE)
- Intelligent caching with mutex-based deduplication and cleanup
- Request tracking, structured logging, and timeouts

## Architecture

### Frontend

- Flutter + GetX
- Cross-platform (Web, Mobile, Desktop)
- REST + SSE integration

### Backend

- Node.js + Express
- OpenAI Chat Completions (`gpt-4o-mini`) with JSON schema responses
- In-memory cache with 7-day TTL and mutex protection
- SSE for long-running analysis and streaming of channel batches

## Key Features

1. Channel discovery with YouTube Data API v3
2. Batched AI analysis (configurable batch size; default 5)
3. SSE-based progress and batch results
4. Caching and race-condition mitigation
5. CSV export from the UI

## Technology Stack

### Frontend

- Flutter, GetX, Material Design

### Backend

- Node.js, Express, OpenAI SDK, express-validator, helmet, rate limit

### External Services

- YouTube Data API v3
- OpenAI API
