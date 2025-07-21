import boto3
import pandas as pd
import io
from datetime import datetime, timedelta

s3 = boto3.client("s3")
BUCKET_NAME = "iot-pipeline-data-bucket"  # Update if different

def lambda_handler(event, context):
    yesterday = datetime.utcnow() - timedelta(days=1)
    prefix = f"data/{yesterday.strftime('%Y-%m-%d')}"
    
    response = s3.list_objects_v2(Bucket=BUCKET_NAME, Prefix="data/")
    records = []

    for obj in response.get("Contents", []):
        if not obj["Key"].endswith(".json"):
            continue
        data_obj = s3.get_object(Bucket=BUCKET_NAME, Key=obj["Key"])
        df = pd.read_json(data_obj["Body"])
        records.append(df)

    if not records:
        print("No data to process")
        return

    final_df = pd.concat(records)
    summary = final_df.groupby("device_id").agg({
        "temperature": ["mean", "max"],
        "humidity": ["mean", "min"]
    })

    csv_buffer = io.StringIO()
    summary.to_csv(csv_buffer)

    output_key = f"reports/summary_{yesterday.strftime('%Y-%m-%d')}.csv"
    s3.put_object(
        Bucket=BUCKET_NAME,
        Key=output_key,
        Body=csv_buffer.getvalue()
    )
