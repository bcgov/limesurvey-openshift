<?php
/**
 * StderrLogRoute - Yii 1.x log route for container/Kubernetes environments.
 *
 * CFileLogRoute uses file_put_contents() with LOCK_EX, which fails on pipes
 * and special file descriptors (/dev/stderr, php://stderr, /proc/1/fd/2).
 * This class uses error_log() instead, which PHP-FPM routes through its own
 * error log. The official PHP Docker image configures error_log = /dev/stderr,
 * so output appears on the container's stderr and is captured by Kubernetes.
 */
class StderrLogRoute extends CLogRoute
{
    /**
     * @param array $logs list of log messages, each an array of:
     *   [message, level, category, timestamp]
     */
    protected function processLogs($logs)
    {
        foreach ($logs as $log) {
            [$message, $level, $category, $timestamp] = $log;
            $message = rtrim($message);
            $date = date('Y-m-d H:i:s', (int)$timestamp);
            $entry = '[' . $date . '] [' . strtoupper($level) . '] [' . $category . '] ' . $message;
            error_log($entry);
        }
    }
}
