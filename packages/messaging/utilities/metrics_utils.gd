extends RefCounted
## Messaging-specific utility functions for metrics calculations and operations.
##
## Provides helper functions for working with the messaging package's performance
## metrics structure. These utilities abstract common metric calculations and
## data structure creation.
##
## **Metrics Structure:** The messaging package uses a dictionary structure:
## [code]{
##   "count": int,           # Number of executions
##   "total_time": float,    # Sum of all execution times (seconds)
##   "min_time": float,      # Minimum execution time (seconds)
##   "max_time": float       # Maximum execution time (seconds)
## }[/code]
##
## **Note:** These utilities are messaging-specific because they work with the
## messaging package's metrics structure. Other packages may use different
## metrics structures and would need their own utility functions.
##
## @note This class extends [RefCounted] and is automatically memory-managed.

## Calculate average time from metrics dictionary.
##
## [code]metrics[/code]: Dictionary with 'count' and 'total_time' keys
## Returns: Average time in seconds (float), or 0.0 if count is 0
static func calculate_average_time(metrics: Dictionary) -> float:
	var count: int = metrics.get("count", 0)
	if count > 0:
		return metrics.get("total_time", 0.0) / count
	return 0.0

## Create an empty metrics dictionary structure.
##
## Returns: Dictionary with default metrics structure for messaging package
static func create_empty_metrics() -> Dictionary:
	return {
		"count": 0,
		"total_time": 0.0,
		"min_time": INF,
		"max_time": 0.0
	}

