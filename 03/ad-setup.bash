vault policy write ad-user-policy ad-user-policy.hcl

C:\Users\Administrator>dsadd user cn=vault,cn=users,dc=interrupt,dc=io -disabled no -pwd Corr3ct-h0rse-battery-staple!

dsadd succeeded:cn=vault,cn=users,dc=interrupt,dc=io

C:\Users\Administrator>dsquery user -name vault
"CN=vault,CN=Users,DC=interrupt,DC=io"

C:\Users\Administrator>dsquery user dc=interrupt,dc=io -name vault
"CN=vault,CN=Users,DC=interrupt,DC=io"

vault secrets enable ad

vault write ad/config \
    binddn="cn=vault,cn=users,dc=interrupt,dc=io" \
    bindpass="Corr3ct-h0rse-battery-staple!" \
    url="ldap://192.168.100.37" \
    userdn="dc=interrupt,dc=io" \
    insecure_tls=true \
    password_policy="ad-password-rules" \
    length=0 \
    starttls=1

vault write ad/config \
    binddn="cn=vault,cn=Users,dc=interrupt,dc=io" \
    bindpass="Corr3ct-h0rse-battery-staple!" \
    url="ldap://192.168.100.37" \
    userdn="dc=interrupt,dc=io" \
    password_policy="ad-password-rules" \
    length=0 \
    certificate=@interrupt.pem \
    insecure_tls=true


vault write ad/config \
    binddn="cn=vault,cn=users,dc=interrupt,dc=io" \
    bindpass="Corr3ct-h0rse-battery-staple!" \
    url="ldap://192.168.100.37" \
    userdn="dc=interrupt,dc=io" \
    insecure_tls=true

vault write ad/roles/application01 \
    service_account_name="application01@interrupt.io"

vault write ad/roles/application01 \
    service_account_name="application01@interrupt.io" \
    ttl=20 \
    max_ttl=40

vault write sys/policies/password/ad-password-rules policy=@ad-password-rules.hcl

vault read sys/policies/password/ad-password-rules

vault write ad/roles/application01 \
    service_account_name="application01@interrupt.io" \
    ttl=30 \
    max_ttl=40
    password_policy="ad-password-rules"

vault read ad/creds/application01

---

vault auth enable ldap

vault write auth/ldap/config \
      binddn="CN=vault,CN=Users,DC=interrupt,DC=io" \
      bindpass="Corr3ct-h0rse-battery-staple!" \
      url="ldap://192.168.100.37:389" \
      userdn="CN=Users,DC=interrupt,DC=io" \
      userattr="sAMAccountName" \
      groupdn="CN=Users,DC=interrupt,DC=io" \
      groupfilter="(&(objectClass=person)(samAccountName={{.Username}}))" \
      groupattr="memberOf" \
      insecure_tls="true" \
      starttls=1

vault write auth/ldap/config \
      binddn="CN=vault,CN=Users,DC=interrupt,DC=io" \
      bindpass="Corr3ct-h0rse-battery-staple!" \
      url="ldap://192.168.100.37:389" \
      userdn="CN=Users,DC=interrupt,DC=io" \
      userattr="sAMAccountName" \
      groupdn="CN=Users,DC=interrupt,DC=io" \
      groupfilter="(&(objectClass=person)(samAccountName={{.Username}}))" \
      groupattr="memberOf" \
      certificate=@interrupt.pem

vault write auth/ldap/config \
      binddn="CN=vault,CN=Users,DC=interrupt,DC=io" \
      bindpass="Corr3ct-h0rse-battery-staple!" \
      url="ldap://192.168.100.37:389" \
      userdn="CN=Users,DC=interrupt,DC=io" \
      userattr="sAMAccountName" \
      groupdn="CN=Users,DC=interrupt,DC=io" \
      groupfilter="(&(objectClass=person)(samAccountName={{.Username}}))" \
      groupattr="memberOf" \
      insecure_tls="true"

vault write auth/ldap/config \
      binddn="CN=vault,CN=Users,DC=interrupt,DC=io" \
      bindpass="Corr3ct-h0rse-battery-staple!" \
      url="ldap://192.168.100.37:389" \
      userdn="CN=Users,DC=interrupt,DC=io" \
      userattr="sAMAccountName" \
      groupdn="CN=Users,DC=interrupt,DC=io" \
      groupfilter="(&(objectClass=group)(member={{.UserDN}}))" \
      groupattr="memberOf" \
      insecure_tls="true"

vault write auth/ldap/config \
      binddn="CN=vault,CN=vault-manager,DC=interrupt,DC=io" \
      bindpass="Corr3ct-h0rse-battery-staple!" \
      url="ldap://192.168.100.37:389" \
      userdn="CN=vault-manager,DC=interrupt,DC=io" \
      userattr="sAMAccountName" \
      groupdn="CN=vault-manager,DC=interrupt,DC=io" \
      groupfilter="(&(objectClass=group)(member={{.UserDN}}))" \
      groupattr="memberOf" \
      insecure_tls="true"

vault write auth/ldap/config \
      binddn="CN=vault,CN=Users,DC=interrupt,DC=io" \
      bindpass="Corr3ct-h0rse-battery-staple!" \
      url="ldap://192.168.100.37:389" \
      userdn="CN=Users,DC=interrupt,DC=io" \
      userattr="sAMAccountName" \
      groupdn="CN=Users,DC=interrupt,DC=io" \
      groupfilter="(|(memberUid={{.Username}})(member={{.UserDN}})(uniqueMember={{.UserDN}}))" \
      groupattr="memberOf" \
      insecure_tls="true"

vault write auth/ldap/groups/vault-manager policies=ad-user-policy

vault login -method=ldap username=vault password=Corr3ct-h0rse-battery-staple!

vault login -method=ldap username=application01 password=Corr3ct-h0rse-battery-staple!

export VAULT_TOKEN=$(vault login -method=ldap username=application01 password=Corr3ct-h0rse-battery-staple! -format=json | jq -r '.auth.client_token')

vault read ad/creds/application01

vault read ad/creds/application01 -format=json | jq '.data' > data.json
vault kv put user-kv/application01 @data.json

unset VAULT_TOKEN
vault login -method=ldap username=application01
