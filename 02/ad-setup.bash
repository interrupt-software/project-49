vault policy write ad-auth ad-auth.hcl

C:\Users\Administrator>dsadd user cn=vault,cn=users,dc=interrupt-software,dc=aws -disabled no -pwd super-secret-password-12345

dsadd succeeded:cn=vault,cn=users,dc=interrupt-software,dc=aws

C:\Users\Administrator>dsquery user -name vault
"CN=vault,CN=Managed Service Accounts,DC=interrupt-software,DC=aws"

C:\Users\Administrator>dsquery user dc=interrupt-software,dc=aws -name vault
"CN=vault,CN=Managed Service Accounts,DC=interrupt-software,DC=aws"

vault secrets enable ad

vault write ad/config \
    binddn="cn=vault,cn=Managed Service Accounts,dc=interrupt-software,dc=aws" \
    bindpass="super-secret-password-12345" \
    url="ldap://192.168.100.200" \
    userdn="dc=interrupt-software,dc=aws" \
    insecure_tls=true

binddn='uid=vault,cn=users,cn=accounts,dc=domain,dc=net'


vault write ad/roles/application01 \
    service_account_name="application01@interrupt-software.aws"

vault write ad/roles/application01 \
    service_account_name="application01@interrupt-software.aws" \
    ttl=20 \
    max_ttl=40

vault write sys/policies/password/ad-password-rules policy=@ad-password-rules.hcl

vault write ad/roles/application01 \
    service_account_name="application01@interrupt-software.aws" \
    ttl=20 \
    max_ttl=40
    password_policy="ad-password-rules"


---

vault write auth/ldap/config \
      binddn="CN=vault,CN=Managed Service Accounts,DC=interrupt-software,DC=aws" \
      bindpass="super-secret-password-12345" \
      url="ldap://192.168.100.200:389" \
      userdn="CN=Managed Service Accounts,DC=interrupt-software,DC=aws" \
      userattr="sAMAccountName" \
      groupdn="CN=Managed Service Accounts,DC=interrupt-software,DC=aws" \
      groupattr="cn"

vault login -method=ldap username=vault password=super-secret-password-12345

vault login -method=ldap username=application01 password=super-secret-password-12345
