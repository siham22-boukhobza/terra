variable "cidr" {
  description = "this cidr define the range of the vpc"
  default     = "10.0.0.0/16"
}
variable "cidr_sub1" {
  description = "this is the ip range for the first subnet"
  default     = "10.0.0.0/24"

}

variable "cidr_sub2" {
  description = "this is the ip range for the second subnet"
  default     = "10.0.1.0/24"

}
variable "availability_zone_sub1" {
  description =  "defines in which availability zone the subnet will be created"

  default     = "us-east-1a"

}
variable "availability_zone_sub2" {
  description =  "defines in which availability zone the subnet will be created"

  default     = "us-east-1b"

}
variable "ami_value" {
  description = "ami value for the servers 1 in both public subnet sub1 and sub2"
  default     = "ami-020cba7c55df1f615"

}
variable "type_value" {
  description = "this is the type of the servers created in public subnet sub1 and sub2"
  default     = "t2.micro"

}