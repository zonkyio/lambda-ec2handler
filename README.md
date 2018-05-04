AWS Lambda ec2 handler
======================

This repo contain python lambda scripts (in path ./files/source), Makefile to build python36 package and could work as terraform module.


Script requirements
-------------------
python 3.6
pip3
boto3


Prepare module
--------------

  git clone this_repo
  modify s
  make build

  in directory source change _______EXAMPLE.COM_______ to your domain, we use it as filter to prevent deleting another domains than we need


Add module to terraform
-----------------------
  module "lambda-ec2handler" {
    source = "../modules/lambda-ec2handler"

    tags = {
      Env = "devel",
      Zone = "eu-central-1"
    }
  }  



Terminate
=========
handle 