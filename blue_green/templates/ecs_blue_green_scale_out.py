import json
import time
import boto3
import os
import json
import math

REGION = os.environ['AWS_DEFAULT_REGION']
QueueUrl = os.environ['QueueUrl']
env_name = os.environ['EcsClusterName'].split("-")[1]
PARAM_STORE = ""
DELAY_SECONDS = 300
MAX_INCREMENTS_COUNT = 5
AppShortName = os.environ['AppShortName']
# DryRun = True
DryRun = False

ECS = boto3.client('ecs', region_name=REGION)
ASG = boto3.client('autoscaling', region_name=REGION)
SSM = boto3.client('ssm', region_name=REGION)
SQS = boto3.client('sqs', region_name=REGION)

def get_instanceId_from_container_instance(containerInstanceArn, clusterArn):
    response = ECS.describe_container_instances(
        cluster=clusterArn,
        containerInstances=[
            containerInstanceArn
        ]
    )
    
    print("Instances in cluster :", response['containerInstances'])
    return response['containerInstances']
    
def log_scale_out_operation(latesttaskdefinition):
    response = SSM.put_parameter(
        Name=PARAM_STORE,
        Description='SSM parameter to log ASG update operations',
        Value=latesttaskdefinition,
        Type='String',
        Overwrite=True
    )
    
def get_last_scale_out_operation():
    try:
        return SSM.get_parameter(Name=PARAM_STORE)['Parameter']['Value']
    except Exception as exp:
        print("Could not get value from " +  PARAM_STORE)
        print(exp)
        return ""

def get_ec2_autoscaling(containerInstanceArnList, clusterArn):
    print("Container instance list :", str(containerInstanceArnList))
    for containerInstanceArn in containerInstanceArnList:
        instance_list = get_instanceId_from_container_instance(containerInstanceArn, clusterArn)
        for instance in instance_list:
            instanceId = instance['ec2InstanceId']
            response = ASG.describe_auto_scaling_instances(
                InstanceIds=[
                    instanceId,
                ]
            ) 
            print (response)
            if len(response['AutoScalingInstances']) > 0:
                asg_Name = response['AutoScalingInstances'][0]['AutoScalingGroupName']
                print (instanceId + " runs in ASG " + asg_Name + " whose health is " + response['AutoScalingInstances'][0]['HealthStatus'])
                return asg_Name
            else:
                print ("Instance" + instanceId + " does not belong to any auto caling group")
    print("No instance in auto scaling group")
    return None

def scale_out_autoscaling(asgName, latest_task_definition):
    asg_info = ASG.describe_auto_scaling_groups(
        AutoScalingGroupNames=[asgName]
    )

    current_desired_size = asg_info['AutoScalingGroups'][0]['DesiredCapacity']
    current_max_size = asg_info['AutoScalingGroups'][0]['MaxSize']
    current_running_instances = len(asg_info['AutoScalingGroups'][0]['Instances'])
    print("Current DESIRED MAX RUNNING: ", current_desired_size, current_max_size, current_running_instances)
    
    if current_max_size - current_desired_size >= math.ceil(current_desired_size / 4):
        desired_increment = math.ceil(current_desired_size / 4)
        max_increment = 0
    else:
        desired_increment = math.ceil(current_desired_size / 4)
        max_increment = (desired_increment - (current_max_size - current_desired_size))
    
    if desired_increment >= MAX_INCREMENTS_COUNT or max_increment >= MAX_INCREMENTS_COUNT:
        desired_increment = MAX_INCREMENTS_COUNT
        max_increment = (desired_increment - (current_max_size - current_desired_size))
    
    print("INCREMENTS DESIRED MAX : ", desired_increment, max_increment)
    try:
        if not DryRun:
            response = ASG.update_auto_scaling_group(
                AutoScalingGroupName=asgName,
                MaxSize=current_max_size + max_increment,
                DesiredCapacity=current_desired_size + desired_increment
            )
            log_scale_out_operation(latest_task_definition)
        
        print("Will add "+ str(desired_increment) + " instance(s) in autocaling group and set Max to " + str (current_max_size + max_increment))
        json_data = json.dumps({"AutoScalingGroupName": asgName, "current_desired_size": current_desired_size, "current_max_size": current_max_size, "current_running_instances": current_running_instances, 
            "new_desired_size": current_desired_size + desired_increment, "new_max_size": current_max_size + max_increment})
        put_message_in_queue(json_data)
        print("Scale out process endend SUCCESSFULLY")
    except Exception as exp:
        print("Error during update auto scaling process")
        print(exp)

def get_latest_task_definition(FamilyPrefix):
    time.sleep(5)
    paginator = ECS.get_paginator('list_task_definitions')
    response_iterator = paginator.paginate(
        familyPrefix=FamilyPrefix,
        status='ACTIVE',
    ) 
    for x in response_iterator:
        if len(x['taskDefinitionArns']):
            print ("Found " + x['taskDefinitionArns'][0] + " as the latest task definition version")
            return x['taskDefinitionArns'][0]
        else:
            print("No ACTIVE task definition for " + familyPrefix)
            
def put_message_in_queue(data):
    response = SQS.send_message(
        QueueUrl=QueueUrl,
        MessageBody=data,
        DelaySeconds=DELAY_SECONDS,
        MessageAttributes={
            'custom_attribute': {
                'StringValue': 'id',
                'DataType': 'String'
            }
        }
    )
    print("SQS message ID: " + response['MessageId'])

def get_cluster_from_task_def(TaskDefFamily):
    cluster_next_token = ""
    
    while cluster_next_token is not None:  
        cluster_response = ECS.list_clusters(nextToken=cluster_next_token)
        cluster_next_token = cluster_response.get('NextToken', None)
        for cluster_arn in cluster_response['clusterArns']:
            service_name = get_ecs_service_name(cluster_arn, TaskDefFamily)
            if service_name:
                return cluster_arn
    print("Matching container instance not found")
    return None
    
def get_ecs_service_name(cluster, TaskDefFamily):
    service_next_token = ""
    while service_next_token is not None:  
        service_response = ECS.list_services(
            cluster=cluster,
            launchType='EC2',
            nextToken=service_next_token
        )
        service_next_token = service_response.get('NextToken', None)

        if service_response['serviceArns'] != []:
            for services_in_cluster in service_response['serviceArns']:
                Service_Name = services_in_cluster.split("/")[-1]
                resp = ECS.describe_services(
                    cluster=cluster,
                    services=[Service_Name]
                )
                if TaskDefFamily in resp['services'][0]['taskDefinition'] :
                    TaskDefArn = resp['services'][0]['taskDefinition']
                    print(services_in_cluster + "\t\t\t" + TaskDefArn)
                    return Service_Name
    return None
        
def get_container_instances_list(cluster):
    cont_inst_arn_list = ECS.list_container_instances(
        cluster=cluster,
        status='ACTIVE'
    )
    if cont_inst_arn_list:
        return cont_inst_arn_list['containerInstanceArns']
    else:
        print("No container instance found in cluster " + cluster)
        return []
                    
def lambda_handler(event, context):
    print ("DryRun :", DryRun)
    print(event)
    container_instance_arn_list = []
    if event['detail-type'] == "ECS Task State Change":
        print("Triggered by a task event")
        task_def_arn = event['detail']['taskDefinitionArn']
        task_def_family = task_def_arn.split("/")[-1].split(":")[0]
        container_instance_arn_list.append(event['detail']['containerInstanceArn'])
        cluster_arn = event['detail']['clusterArn']
    elif event['detail-type'] == "AWS API Call via CloudTrail" and event['detail'].get("eventName") == "DeregisterTaskDefinition":
        print("Triggered by a service event")
        # DeregisterTaskDefinition event contains deactivated task definition ARN >>>>
        task_def_arn = event['detail']['responseElements']['taskDefinition']['taskDefinitionArn']
        task_def_family = event['detail']['responseElements']['taskDefinition']['family']
        cluster_arn = get_cluster_from_task_def(task_def_family)
        container_instance_arn_list = get_container_instances_list(cluster_arn)
    else:
        raise ValueError("Event source not supported")
        
    service_name = get_ecs_service_name(cluster_arn, task_def_family)
    print("service_name", service_name)
    
    global PARAM_STORE
    PARAM_STORE = "/" + env_name + "/" + AppShortName + "/" + service_name + "/LastTaskDefThatScaledOutASG"
    
    latest_task_definition = get_latest_task_definition(task_def_family)

    # Ensure ASG scale out operation was NOT already triggered by another function invocation 
    # Event triggered by task based on latest task def
    # Must exist before GetParameter
    last_task_definition_logged = get_last_scale_out_operation()
    print ("Parameter Store " + PARAM_STORE + "'s value : " + last_task_definition_logged)
    if last_task_definition_logged ==  latest_task_definition:
        print("Scale out operation previously triggered.")
        print ("Up to date: nothing to do... [END]")
    else:
        Asg_Name = get_ec2_autoscaling(container_instance_arn_list, cluster_arn)
        scale_out_autoscaling(Asg_Name, latest_task_definition)
