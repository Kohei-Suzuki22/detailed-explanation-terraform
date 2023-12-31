# リモートステートバケットを作成。
resource "aws_s3_bucket" "terraform_state" {
  bucket = "hello-terraform-remote-state"

  lifecycle {
    prevent_destroy = true
  }
  
}


# リモートステートバケットのバージョニングを有効化
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
  
}


# リモートステートバケットの、サーバーサイド暗号化
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
  
}


# リモートステートバケットのパブリックアクセスをブロック
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}


# リモートステートのロックを管理するためのdynamoDBを作成
resource "aws_dynamodb_table" "terraform-locks" {
  name = "hello-terraform-remote-state-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "LockID"


  attribute {
    name = "LockID"
    type = "S"
  }
  
}


# backend

# terraform {
#   backend "s3" {
#     # tfstateファイルを置くs3バケットを指定
#     bucket = "hello-terraform-remote-state"
#     key = "backend_tutorial/terraform.tfstate"
#     region = "ap-northeast-1"
#     # lockを管理するdynamo_tableを指定
#     dynamodb_table = "hello-terraform-remote-state-locks"
#     encrypt = true
#   }
# }



# backend

## backend.hclファイルに共通の設定を抽出している。
## terraform init --backend-config=backend.hcl  のように、initする際に共通設定ファイルを指定する。
terraform {
  backend "s3" {
    key = "backend_tutorial/terraform.tfstate"
  }
}


output "s3_bucket_arn" {
  value = aws_s3_bucket.terraform_state.arn
  description = "The ARN of the S3 bucket"
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.terraform-locks.name
  description = "The name of the Dynamo table"
  
}