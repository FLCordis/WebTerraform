# Apache2 WebService

Just a simple project made to use Terraform to create AWS Cloud instance and resources such as VPC, Subnet, Internet Gateway/Interface and Elastic IP to run a Apache2 Webservice.


## Docs used

 - [Terraform AWS Doc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)


## Deploy

Deploy in local, first change the "public" and "private" keys to your AWS ones, **BE CAREFUL ITS SENSITIVY INFO**!

```bash
  terraform apply --auto-approve
```
