vault secrets list
vault secrets enable aws
vault write aws/config/lease lease=30m lease_max=30m


vault write aws/config/root \
  access_key=$AWS_ACCESS_KEY_ID \
  secret_key=$AWS_SECRET_ACCESS_KEY \
  region=us-west-1

vault write aws/roles/my-role \
        credential_type=iam_user \
        policy_document=@aws-policy

or

vault write aws/roles/my-role \
        credential_type=iam_user \
        policy_document=-<<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Stmt1426528957000",
      "Effect": "Allow",
      "Action": [
        "ec2:*"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF

aws iam list-users

vault read aws/creds/my-role

aws iam list-users

vault list sys/leases/lookup/aws/creds/my-role

vault lease revoke aws/creds/my-role/BdQC3gYvmKP3J6zxnWqLoG29