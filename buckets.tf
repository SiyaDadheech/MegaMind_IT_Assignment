# 1. Raw Bucket (Landing Zone) - Jahan User data upload karega

resource "aws_s3_bucket" "raw_data" {
  bucket = "megamind-raw-data-2026" # Globally unique name
  tags = {
    Name        = "Raw Data Bucket"
    Environment = "Dev"
  }
}

# 2. Processed Bucket (Curated Zone) - Jahan Lambda processed data rakhega

resource "aws_s3_bucket" "processed_data" {
  bucket = "megamind-processed-data-2026"
  tags = {
    Name        = "Processed Data Bucket"
    Environment = "Dev"
  }
}

