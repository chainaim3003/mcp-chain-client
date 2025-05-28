import winston from 'winston';
import path from 'path';
import { existsSync, mkdirSync } from 'fs';
export function setupLogger() {
    const logDir = process.env.LOG_DIR || './data/logs';
    const logLevel = process.env.LOG_LEVEL || 'info';
    // Ensure log directory exists
    if (!existsSync(logDir)) {
        mkdirSync(logDir, { recursive: true });
    }
    return winston.createLogger({
        level: logLevel,
        format: winston.format.combine(winston.format.timestamp(), winston.format.errors({ stack: true }), winston.format.json()),
        transports: [
            new winston.transports.Console({
                format: winston.format.combine(winston.format.colorize(), winston.format.simple())
            }),
            new winston.transports.File({
                filename: path.join(logDir, 'error.log'),
                level: 'error'
            }),
            new winston.transports.File({
                filename: path.join(logDir, 'combined.log')
            })
        ]
    });
}
//# sourceMappingURL=logger.js.map