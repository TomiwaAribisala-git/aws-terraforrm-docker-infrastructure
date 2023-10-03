import boto3
import os 
import time

aws_access_key_id = os.environ["AWS_ACCESS_KEY_ID"]
aws_secret_access_key = os.environ["AWS_SECRET_ACCESS_KEY"]
aws_region = 'eu-north-1'

instance_id = 'i-0c5104cef51f79fcd'

ec2 = boto3.client('ec2', region_name=aws_region)

def check_instance_status(instance_id):
    try:
        response = ec2.describe_instances(InstanceIds=[instance_id])
        instance = response['Reservations'][0]['Instances'][0]
        return instance['State']['Name']
    except Exception as e:
        print(f"Error checking instance status: {e}")
        return None

def restart_instance(instance_id):
    try:
        ec2.stop_instances(InstanceIds=[instance_id])
        ec2.get_waiter('instance_stopped').wait(InstanceIds=[instance_id])
        ec2.start_instances(InstanceIds=[instance_id])
        ec2.get_waiter('instance_running').wait(InstanceIds=[instance_id])
        print(f"Instance {instance_id} has been restarted.")
    except Exception as e:
        print(f"Error restarting instance: {e}")

def main():
    while True:
        instance_status = check_instance_status(instance_id)
        if instance_status == 'running':
            print("Instance is up and serving the expected version.")
        elif instance_status == 'stopped':
            print("Instance is stopped. Restarting...")
            restart_instance(instance_id)

        # Sleep for 3 hours before the next check (3 hours * 60 minutes * 60 seconds)
        time.sleep(3 * 60 * 60)

if __name__ == "__main__":
    main()