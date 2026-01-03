extends RefCounted
## Utilities for metrics calculations.

## Calculate average time from metrics.
static func calculate_average_time(metrics: Dictionary) -> float:
	var count: int = metrics.get("count", 0)
	if count > 0:
		return metrics.get("total_time", 0.0) / count
	return 0.0

## Create empty metrics dictionary.
static func create_empty_metrics() -> Dictionary:
	return {
		"count": 0,
		"total_time": 0.0,
		"min_time": INF,
		"max_time": 0.0
	}

