terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket-124356"
    key            = "terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
