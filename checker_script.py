import boto3

instance_id = 'i-08d002a6b831c8a47'
ec2 = boto3.client('ec2', region_name="eu-north-1")

def check_instance_status(ec2, instance_id):
    try:
        response = ec2.describe_instance_status(InstanceIds=[instance_id])
        if len(response['InstanceStatuses']) == 0:
            return 'not-found'
        status = response['InstanceStatuses'][0]['InstanceState']['Name']
        return status
    except Exception as e:
        return 'error'

def restart_instance(ec2, instance_id):
    try:
        ec2.start_instances(InstanceIds=[instance_id])
        return f"Instance {instance_id} has been started."
    except Exception as e:
        return f"Error restarting instance: {str(e)}"

def main():
    
    instance_status = check_instance_status(ec2, instance_id)

    if instance_status == 'running':
        print(f"Instance {instance_id} is running.")
    elif instance_status == 'stopped':
        print(f"Instance {instance_id} is stopped. Restarting...")
        restart_result = restart_instance(ec2, instance_id)
        print(restart_result)
    elif instance_status == 'not-found':
        print(f"Instance {instance_id} not found. Please check the instance ID.")
    elif instance_status == 'error':
        print("There was an error checking the instance status. Please check your configuration.")

if __name__ == '__main__':
    main()