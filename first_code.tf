provider "aws" {
 profile = "awsprod"
 region = "ap-south-1"
}

resource "aws_s3_bucket_acl" "tf_course" {
  bucket = "tf-course-learning"
  acl = "private"
 }

  
