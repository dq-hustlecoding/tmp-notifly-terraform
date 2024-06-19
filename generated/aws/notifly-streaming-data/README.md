## notifly-streaming-data

[AWS 기반 notifly-streaming-data 설계 설명](https://docs.google.com/document/d/1cOWUXFmtSw-ykF5cBW-7bxaObVNFaeyukp2NVNqFPb8/edit#heading=h.q6eynehyswkm)을 참고하세요.

### How this project was setup

AWS CloudFormation으로 AWS resource들을 생성한 이후에 [terraformer](https://github.com/GoogleCloudPlatform/terraformer)를 활용해서 terraform tf, tfstate들을 생성했습니다.

```
terraform state replace-provider "registry.terraform.io/-/aws" "hashicorp/aws"
terraform init
```

### References

- [terraformer](https://github.com/GoogleCloudPlatform/terraformer)
- [Terraform - AWS tutorial](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/aws-build)

### Import existing resources

```
terraform import aws_api_gateway_method.records-options 12lnng07q2/i98qdf/OPTIONS
terraform import aws_api_gateway_integration.records-options 12lnng07q2/i98qdf/OPTIONS
terraform import aws_api_gateway_integration_response.records-options 12lnng07q2/i98qdf/OPTIONS/200
terraform import aws_api_gateway_method_response.records-options 12lnng07q2/i98qdf/OPTIONS/200
terraform import aws_cloudwatch_log_group.kds-consumer-cloudwatch-log-group /aws/lambda/kds-consumer
terraform import aws_cloudwatch_log_group.event-streaming-api-access-cloudwatch-log-group event-streaming-api-access-logs
```
