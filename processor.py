import boto3
import pandas as pd
import io

s3 = boto3.client('s3')
glue = boto3.client('glue')

def handler(event, context):
    try:
        # 1. Incoming file details
        source_bucket = event['Records'][0]['s3']['bucket']['name']
        file_key = event['Records'][0]['s3']['object']['key']
        
        # 2. Load CSV from S3
        response = s3.get_object(Bucket=source_bucket, Key=file_key)
        df = pd.read_csv(io.BytesIO(response['Body'].read()))
        
        # 3. Data Cleaning (Example: Remove empty rows)
        df_cleaned = df.dropna()
        df_cleaned['processed_timestamp'] = pd.Timestamp.now()
        
        # 4. Save to Processed Bucket as Parquet
        target_bucket = "megamind-processed-data-2026"
        output_buffer = io.BytesIO()
        df_cleaned.to_parquet(output_buffer, index=False)
        
        target_key = file_key.replace('.csv', '.parquet')
        s3.put_object(
            Bucket=target_bucket, 
            Key=target_key, 
            Body=output_buffer.getvalue()
        )
        
        # 5. Trigger Glue Crawler (Schema Update)
        glue.start_crawler(Name="pipeline-data-crawler")
        
        return {"status": "success", "file": target_key}
        
    except Exception as e:
        print(f"Error: {str(e)}")
        raise e
