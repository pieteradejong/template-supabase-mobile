/**
 * Simple logger utility for React Native / Expo apps.
 *
 * Usage:
 *   import { createLogger } from '../lib/logger';
 *   const log = createLogger('MyComponent');
 *   log.info('Something happened', { detail: 'value' });
 *
 * Log levels:
 *   - debug: Detailed info for troubleshooting (dev only)
 *   - info: Normal operations worth recording
 *   - warn: Something unexpected but handled
 *   - error: Something broke, needs attention
 *
 * See LOGGING.md for full logging standards.
 */

type LogLevel = "debug" | "info" | "warn" | "error";

const LEVELS: Record<LogLevel, number> = {
  debug: 0,
  info: 1,
  warn: 2,
  error: 3,
};

// In development, show all logs. In production, only warn and above.
const MIN_LEVEL: LogLevel = __DEV__ ? "debug" : "warn";

function shouldLog(level: LogLevel): boolean {
  return LEVELS[level] >= LEVELS[MIN_LEVEL];
}

function formatMessage(level: LogLevel, context: string, message: string): string {
  const timestamp = new Date().toISOString().slice(11, 23);
  return `[${timestamp}] [${level.toUpperCase()}] [${context}] ${message}`;
}

export interface Logger {
  debug: (message: string, data?: object) => void;
  info: (message: string, data?: object) => void;
  warn: (message: string, data?: object) => void;
  error: (message: string, error?: Error | object) => void;
}

/**
 * Create a logger with a specific context (usually component or module name).
 */
export function createLogger(context: string): Logger {
  return {
    debug: (msg: string, data?: object) => {
      if (shouldLog("debug")) {
        console.log(formatMessage("debug", context, msg), data ?? "");
      }
    },
    info: (msg: string, data?: object) => {
      if (shouldLog("info")) {
        console.info(formatMessage("info", context, msg), data ?? "");
      }
    },
    warn: (msg: string, data?: object) => {
      if (shouldLog("warn")) {
        console.warn(formatMessage("warn", context, msg), data ?? "");
      }
    },
    error: (msg: string, error?: Error | object) => {
      if (shouldLog("error")) {
        console.error(formatMessage("error", context, msg), error ?? "");
      }
    },
  };
}

// Default app-level logger
export const logger = createLogger("App");
