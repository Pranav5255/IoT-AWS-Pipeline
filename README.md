# IoT Data Pipeline on AWS

This project implements an event-driven IoT data processing pipeline on AWS using Terraform for infrastructure-as-code and GitHub Actions for CI/CD.

## Features

- Ingests simulated IoT device readings via AWS IoT Core
- Stores device data in versioned Amazon S3 bucket
- Generates daily summary reports using AWS Lambda + pandas
- Scheduled via Amazon EventBridge
- Fully automated infrastructure provisioning with Terraform
- CI/CD pipeline with GitHub Actions

---

## Architecture
<p align="center">  
  <img src="./assets/architecture.png" alt="Project Logo">  
</p>

---

## AWS Services Used

- AWS IoT Core
- Amazon S3 (with versioning)
- AWS Lambda (with pandas layer)
- Amazon EventBridge (for scheduling)
- AWS IAM (for access control)
- Terraform (for provisioning)
- GitHub Actions (CI/CD)

---

## Setup

### Prerequisites

- AWS CLI configured (`aws configure`)
- Terraform installed
- GitHub Actions secret: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`

### Deployment

1. Clone this repo:

```bash
git clone https://github.com/Pranav5255/IoT-AWS-pipeline.git
cd IoT-AWS-pipeline
```

2. Initialize Terraform:
```
terraform init
```

3. Review the plan:
```
terraform plan
```

4. Apply the infra:
```
terraform apply
```

### Lambda
- When it comes to the implementation of Lambda function, if you are developing using Windows Machine, I would suggest that you only allocate the resources to create the Lambda function using IaC or AWS CLI. But do not zip the python dependencies from your pc to AWS.
- This is because, AWS Lambda heavily utilises Linux Infrastructure to provide its serverless categories and the Windows Dependencies of Python are not compatible with the AWS Infra. It may appear that your python logic has been suucessfully deployed. But when you try to test the pipeline, it returns with the following error:
  ```
  {"errorMessage": "module 'os' has no attribute 'add_dll_directory'", "errorType": "AttributeError", "requestId": "", "stackTrace": ["  File \"/var/lang/lib/python3.11/importlib/__init__.py\", line 126, in import_module\n    return _bootstrap._gcd_import(name[level:], package, level)\n", "  File \"<frozen importlib._bootstrap>\", line 1204, in _gcd_import\n", "  File \"<frozen importlib._bootstrap>\", line 1176, in _find_and_load\n", "  File \"<frozen importlib._bootstrap>\", line 1147, in _find_and_load_unlocked\n", "  File \"<frozen importlib._bootstrap>\", line 690, in _load_unlocked\n", "  File \"<frozen importlib._bootstrap_external>\", line 940, in exec_module\n", "  File \"<frozen importlib._bootstrap>\", line 241, in _call_with_frames_removed\n", "  File \"/var/task/daily_report_generator.py\", line 2, in <module>\n    import pandas as pd\n", "  File \"/var/task/pandas/__init__.py\", line 11, in <module>\n    _delvewheel_patch_1_10_1()\n", "  File \"/var/task/pandas/__init__.py\", line 8, in _delvewheel_patch_1_10_1\n    os.add_dll_directory(libs_dir)\n"]}
  ```
- If you run this CI/CD pipeline, majority of the resources will be set up, you'll just manually have to set the layer in the function. In the Functions menu:
  Layers > Add a Layer > Specify an ARN:
  ```
  arn:aws:lambda:ap-south-1:336392948345:layer:AWSSDKPandas-Python311-Arm64:22
  ```
- This is the ARN I am using for upholding the Python Logic and it is doing a spledid job of holding it up.
- You can find more ARNs from [this link](https://aws-sdk-pandas.readthedocs.io/en/stable/layers.html).
---

## Simulating IoT Data
You can simulate IoT data manually via AWS CLI:
```
aws iot-data publish \
  --topic 'iot/data' \
  --payload '{"device_id": "sensor-1", "timestamp": "2025-07-21T12:00:00Z", "temperature": 28.5, "humidity": 60}' \
  --endpoint-url <your-iot-endpoint>
```
---

## Testing the Lambda
You can test the report generation manually from the AWS Console:
- Navigate to Lambda > `iot-pipeline_daily_report`.
- Run a test with no payload.
Output report will appear in:
```
s3://iot-pipeline-data-bucket/report/YYYY-MM-DD.csv
```
---
## CI/CD Workflow:
On every push to `main`:
- Terraform plans and applies infra changes
- Uses OIDC-based GitHub Actions IAM role
- Lambda function and infra auto-updated
---

## IAM Notes
GitHub CI user needs these permissions:
- `iot:*` (or scoped access to topic rules)
- `lambda:*`
- `events:*`
- `s3:*`
- `iam:GetRole`, `iam:PassRole`

---

## File Structure
```
IoT-AWS-Pipeline/
├── lambda/
│   └── daily_report_generator.py
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── provider.tf
└── .github/workflows/
    └── terraform.yml
```


