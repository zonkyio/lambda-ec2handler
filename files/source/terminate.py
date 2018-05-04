#!/usr/bin/env python3

import boto3
import os
import http
from pprint import pprint
import socket
from botocore.exceptions import ClientError


aws = boto3.client("route53")

def log_err(msg):
	""" Need more love
	"""
	print("ERR: ", msg)


def log_info(msg):
	""" Need more love
	"""
	print("INFO: ", msg)


def check_http(url):
	""" Check http return code

		if url return exception (timeout) return False in other cases return True
	"""
	ret = False
	try:
		web = http.client.HTTPConnection(url, timeout=5)
		web.request("HEAD", "/")
		_r = web.getresponse()
		ret = True

	except:
		log_err(url)

	finally:
		return ret


def delete_record(record, zone_id):
	""" AWS boto3 route53 record delete wraper

		record {
					"Type": str("CNAME/A/AAAA/MX/TXT/..."),
					"Name": str("www.sub.domain.ltd."),
					"ResourceRecords": [
						{ "Value": str() }
					]
				}

		return bool()

	"""
	try:

		_change = {
					'Changes': [
						{'Action': 'DELETE', 'ResourceRecordSet': record}
					]
				}
		aws.change_resource_record_sets(HostedZoneId=zone_id, ChangeBatch=_change)
		log_info("DNS record {} has been deleted".format(record["Name"]))
		return True

	except ClientError as err:
		log_err("Unable to delete record: {} (probably does not exist)".format(record["Name"]))
		pprint(record)
		log_err(err)

		return False


def get_zoneid(zone_name):
	""" Get zone_id from zone_name
		
		zone_name = str("mydomain.tld.")	don't forgot dot at the end 
		
		return str() or raise ValueError exception
	""" 
	try:
		zone = aws.list_hosted_zones_by_name(DNSName=zone_name, MaxItems="1")["HostedZones"][0]
		if zone_name == zone["Name"]:
			zone_id = zone["Id"].split("/")[-1:][0]
			return zone_id
	
	except:
		raise ValueError("Wrong value in variable zone_name!!! Domain \"{}\" not found in route53".format(zone_name))


def lambda_handler(event, context):
	"""
		Lambda default entrypoint function
		----------------------------------
		feel free to modify this part to fit function your usecase

		event = {
			"detail": {
				"state": "terminated/stopped",
				"instance-id": ""
			},
			"resources": [
				"arn:aws:ec2:eu-west-1:467575887937:instance/i-00b2febba25dee154"
			],
			"source": "aws.ec2",
			"region": "eu-wes-+"
		}
	"""
	ZONE_ID=get_zoneid(os.getenv("ZONE_NAME"))
	ec2 = boto3.client("ec2")

	for instance in ec2.describe_instances(InstanceIds=[event["detail"]["instance-id"]])["Reservations"][0]["Instances"]:
		# reformat tags for easier ussage
		tags = { t["Key"]: t["Value"] for t in instance["Tags"] }

		#
		# Please modify this part to fit your use-case!!!
		#
		if tags.get("source", "") == "jenkinsDockerBuild":
			url = "api.{}._______EXAMPLE.COM_______.".format(tags["Name"])
			try:
				# we handle termination event so it is not possible to get PublicDnsName 
				# from ec2 instance, so we get it from DNS and check if host is up
				instance_dns, *_ = socket.gethostbyaddr(url[:-1])
				if not check_http(url):

					# One instance has more aliases, but we can't check each of them,
					# so we check the first one, and than delete the rest
					for dom_prefix in ["dom1", "dom2", "dom3", "api"]:
						rec = {
							"Type": "CNAME",
							"TTL": 600,
							"Name": url.replace("api", dom_prefix),
							"ResourceRecords": [
								{ "Value": instance_dns }
							]
						}
						delete_record(rec, zone_id=ZONE_ID)
			
			except socket.gaierror as err:
				log_err("url {} not found".format(url))
				log_err(err)
			
	return True
