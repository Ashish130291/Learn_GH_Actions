import pytest
from app import process_server_metrics

def test_valid_metrics():
    # Tests standard expected behavior
    data = [
        {"server_id": "node-1", "cpu_usage": 50.0},
        {"server_id": "node-2", "cpu_usage": 70.0}
    ]
    assert process_server_metrics(data) == 60.0

def test_empty_metrics():
    # Tests edge case handling
    assert process_server_metrics([]) == 0.0

def test_missing_cpu_column():
    # Tests that the application correctly throws an error on bad data
    data = [{"server_id": "node-1", "memory_mb": 1024}]
    
    with pytest.raises(ValueError, match="Data must contain a 'cpu_usage' column"):
        process_server_metrics(data)
