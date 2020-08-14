# ECS Non-Traffic

Module to provisioning services and rolling update deployments and autoscaling ecs task with cloudwatch alarms. Some features:

- Elasticsearch cluster for logs.
- Autoscaling
- Terraform: `0.13.+`
- Force deployment

## Inputs

| Name | Description | Type |
|------|-------------|:----:|
| <div id='var.auto_scale_role'></div> auto_scale_role | IAM Role for autocaling services | string |
| <div id='var.cluster'></div> cluster | Cluster used in ecs | string |
| <div id='var.cpu_unit'></div> cpu_unit | Number of cpu units for container | string |
| <div id='var.cwl_endpoint'></div> cwl_endpoint | Cloudwatch endpoint logs | string |
| <div id='var.dummy_deps'></div> dummy_deps | Dummy dependencies for interpolation step | string |
| <div id='var.environment'></div> environment | Environment variables for ecs task | list |
| <div id='var.lambda_stream_arn'></div> lambda_stream_arn | ARN of function lambda to stream logs into elasticsearch | string |
| <div id='var.max_scale'></div> max_scale | Maximun number of task scaling | string |
| <div id='var.memory'></div> memory | Number of memory for container | string |
| <div id='var.min_scale'></div> min_scale | Minimun number of task scaling | string |
| <div id='var.name'></div> name | Name of service | string |
| <div id='var.public_ip'></div> public_ip | Flag to set auto assign public ip | string |
| <div id='var.roleArn'></div> roleArn | Role Iam for task def | string |
| <div id='var.roleExecArn'></div> roleExecArn | Role Iam for execution | string |
| <div id='var.role_service'></div> role_service | Role for execution service | string |
| <div id='var.secrets'></div> secrets | Secrets values for ecs task | list |
| <div id='var.security_groups'></div> security_groups | Security groups allowed | list |
| <div id='var.service_count'></div> service_count | Number of desired task | string |
| <div id='var.service_role_codedeploy'></div> service_role_codedeploy | Role for ecs codedeploy | string |
| <div id='var.subnets'></div> subnets | Private subnets from VPC | string |
| <div id='var.task'></div> task | ARN of task created | string |
| <div id='var.vpc_id'></div> vpc_id | VPC ID for create target group resources | string |

### Outputs

| Name | Description |
|------|-------------|
| <div id='output.ecs_service_id'></div> ecs_service_id | ID of service created |

#### How to use

```hcl

module "your_service_name" {
  source                = "hendrixroa/ecs-non-traffic/aws"
  name                  = "nameService"
  security_groups       = ["security_group_id"]
  subnets               = ["list of subnets"]
  vpc_id                = "vpc_id"
  cluster               = "ecs cluster id"
  role_service          = "role service arn"
  roleExecArn           = "role task execution arn"
  roleArn               = "role task arn"
  service_count         = 1
  disable_log_streaming = true
  dummy_deps            = "any deps that this service should wait for."
  kms_key_id            = "kms key id"
}

```
