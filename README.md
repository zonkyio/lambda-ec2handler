AWS Lambda ec2 handler
======================

This repo contain python lambda scripts (in path ./files/source), Makefile to build python36 package and could work as terraform module.


Terminate function
==================
When cloudWatch receives event "ec2 terminate" notify the lambda-ec2handler-terminate lambda function. This lambda function check if instance has tag "source" equals to "jenkinsDockerBuild", create url api.EC2_INSTANCE_NAME.example.com and check if this url has CNAME, and if it does not listen on HTTP protocol. If all requirements are fullfiled, the script try to delete records belonged to instance in defined zone in route53 service. 


Script requirements
-------------------
python 3.6
pip3
boto3
... Linux/BSD/OSX os to be able run make and installation by terraform


Instalation
-----------
this repo work as a terraform module and in example bellow you could see how to use it in your terraform environment. 

  module "lambda-ec2handler" {
    source = "../modules/lambda-ec2handler"

    tags = {
      Env = "devel",
      Zone = "eu-central-1",
      Terraform = "True",
    }
  } 


Before run it as a module you should:
  * check source code in files/source/terminate.py to fit lambda_handler function to your usecase (at least change _______EXAMPLE.COM_______ to your domain). 
  * build files/python36_env.zip by run make command in this directory (begin with **make help**)


After installation there are a few steps I didn't add to terraform (sorry for that):
  * in lambda designer add "CloudWatch Event" to trigers and save function
