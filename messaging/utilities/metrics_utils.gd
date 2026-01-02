extends RefCounted
## Messaging-specific utility functions for metrics calculations and operations.
##
## These utilities work with the messaging package's specific metrics dictionary
## structure: {count: int, total_time: float, min_time: float, max_time: float}
##
## Note: These are messaging-specific because they work with messaging's metrics
## structure. Other packages would have different metrics structures.

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

