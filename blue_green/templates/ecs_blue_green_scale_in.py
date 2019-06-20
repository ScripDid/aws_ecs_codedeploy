import json
import boto3
import os

REGION = os.environ['AWS_DEFAULT_REGION']
QueueUrl = os.environ['QueueUrl']
env_name = os.environ['EcsClusterName'].split("-")[1]
AppShortName = os.environ['AppShortName']
# DryRun = True
DryRun = False

ASG = boto3.client('autoscaling', region_name=REGION)

def lambda_handler(event, context):
    print(event)
    # print(event['Records'][0]['body'])
    json_body = json.loads(event['Records'][0]['body'].replace("'", "\""))
    print(json_body)
    AsgName = json_body['AutoScalingGroupName']
    print(AsgName)
    asg_info = ASG.describe_auto_scaling_groups(
        AutoScalingGroupNames=[AsgName]
    )
    
    initial_desired_size = json_body['current_desired_size']
    initial_max_size = json_body['current_max_size']
    
    new_desired_size = json_body['new_desired_size']
    
    current_desired_size = asg_info['AutoScalingGroups'][0]['DesiredCapacity']
    current_max_size = asg_info['AutoScalingGroups'][0]['MaxSize']
    current_running_instances = len(asg_info['AutoScalingGroups'][0]['Instances'])
    
    print("Current DESIRED MAX RUNNING: ", current_desired_size, current_max_size, current_running_instances)
    if new_desired_size < current_desired_size:
        print("More instances(s) were added in the auto scaling group since the related blue/green deployment occured")
        print ("Maybe more traffic. Nothing to do... [END]")
    elif new_desired_size > current_desired_size:
        print("Some instances(s) were removed in the auto scaling group since the related blue/green deployment occured")
        print ("Maybe less traffic. Nothing to do... [END]")
    else:
        if not DryRun:
            response = ASG.update_auto_scaling_group(
                AutoScalingGroupName=AsgName,
                MaxSize=initial_max_size,
                DesiredCapacity=initial_desired_size
            )
        print("Set DesiredCapacity to "+ str(initial_desired_size) + " and set MaximumCapacity to " + str (initial_max_size))
        