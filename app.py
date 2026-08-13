import pandas as pd

def process_server_metrics(data):
    """
    Processes a list of server metric dictionaries and returns the average CPU usage.
    """
    if not data:
        return 0.0
        
    df = pd.DataFrame(data)
    
    if 'cpu_usage' not in df.columns:
        raise ValueError("Data must contain a 'cpu_usage' column")
        
    return float(df['cpu_usage'].mean())

if __name__ == "__main__":
    # Sample data mimicking a systems operations log pull
    metrics = [
        {"server_id": "web-01", "cpu_usage": 45.5},
        {"server_id": "web-02", "cpu_usage": 60.0},
        {"server_id": "db-01", "cpu_usage": 85.2}
    ]
    
    avg_cpu = process_server_metrics(metrics)
    print(f"Average CPU Usage across cluster: {avg_cpu:.2f}%")
