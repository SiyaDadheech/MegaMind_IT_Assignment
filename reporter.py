import boto3
import time

athena = boto3.client('athena')
ses = boto3.client('ses')

def handler(event, context):
    # 1. Athena Query (Daily Count)
    query = "SELECT count(*) as total_records FROM MyCatalogDatabase.processed_table_name"
    
    response = athena.start_query_execution(
        QueryString=query,
        QueryExecutionContext={'Database': 'MyCatalogDatabase'},
        ResultConfiguration={'OutputLocation': 's3://megamind-processed-data-2026/reports/'}
    )
    
    # 2. Wait for query to finish (Simple 5s wait)
    time.sleep(5)
    
    # 3. Send Email via SES
    ses.send_email(
        Source='siyadadheech175@gmail.com', # Yahan apna verified SES email likhein
        Destination={'ToAddresses': ['siyadadheech175@gmail.com']},
        Message={
            'Subject': {'Data': 'Daily Pipeline Summary Report'},
            'Body': {'Text': {'Data': 'Daily data processing is complete. Please check Athena for details.'}}
        }
    )
    
    return {"status": "Report Sent"}

