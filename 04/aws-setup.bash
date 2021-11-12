vault secrets list
vault secrets enable aws
vault write aws/config/lease lease=30d lease_max=30d

# The AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY keys correspond 
# to the user that holds the keys and is able to manage key rotation.
# This is the target account to manage.

vault write aws/config/root \
  access_key=$AWS_ACCESS_KEY_ID \
  secret_key=$AWS_SECRET_ACCESS_KEY \
  region=us-west-1

# The role reflect the generation of a dynamic, derived account
# from the user. It does not inherit the root-user privileges
# and instead uses the given privileges in the `aws-policy`

vault write aws/roles/my-role \
        credential_type=iam_user \
        policy_document=@aws-policy

or

vault write aws/roles/my-role \
        credential_type=iam_user \
        policy_document=-<<EOF
{
   "Version": "2012-10-17",
   "Statement": [{
      "Effect": "Allow",
      "Action": [
         "ec2:DescribeInstances",
         "ec2:DescribeImages",
         "ec2:DescribeTags",
         "ec2:DescribeSnapshots"
      ],
      "Resource": "*"
   }
   ]
}
EOF

aws iam list-users

# Explore one-time values exposed for the new keys
vault read aws/creds/my-role

# Express the one-time values exposed for the new keys in JSON format
vault read -format=json aws/creds/my-role

# Express the one-time values exposed for the new keys in JSON format
# and use the `jq` utility to extract the actual secret
vault read -format=json aws/creds/my-role | jq '.data'

# Express the one-time values exposed for the new keys in JSON format
# and use the `jq` utility to extract the actual secret to a file
vault read -format=json aws/creds/my-role | jq '.data' > data.json

# Express the one-time values exposed for the new keys in JSON format
# without `jq` filtering. This is optimal to maintain the lease contract
# in view of the secret
vault read -format=json aws/creds/my-role > data.json

# Enable KV Secrets Engine
vault secrets enable -version=2 -path=aws-kv kv

# Save the current AWS keys in the KV store
# Versioning maintains track of all secrets
vault kv put aws-kv/my-role @data.json


aws iam list-users

vault list sys/leases/lookup/aws/creds/my-role

vault lease revoke aws/creds/my-role/BdQC3gYvmKP3J6zxnWqLoG29

# To Rotate the root account keys
vault write -force aws/config/rotate-root

--

vault secrets enable -path=vault02 aws

vault write vault02/config/lease lease=30m lease_max=30m

vault write vault02/config/root \
  access_key=$AWS_ACCESS_KEY_ID \
  secret_key=$AWS_SECRET_ACCESS_KEY \
  region=us-east-2

vault write vault02/roles/my-role \
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

