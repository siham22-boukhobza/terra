provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "example" {
  ami = ""
  instance_type = "us-east-1"
}