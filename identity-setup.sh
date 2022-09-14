vault policy write secrets -<<EOF
path "secret/*" {
   capabilities = [ "create", "read", "update", "delete" ]
}
EOF

vault policy write admin -<<EOF
path "auth/*" {
   capabilities = [ "create", "read", "update", "delete", "list", "sudo" ]
}
EOF

vault policy write sysops -<<EOF
path "sys/*" {
   capabilities = [ "create", "read", "update", "delete", "list", "sudo" ]
}
EOF

# Create users under userpass auth
vault auth enable -path="userpass-test" userpass
vault write auth/userpass-test/users/james password="training" policies="test"
vault write auth/userpass-test/users/bob password="training" policies="test"

vault auth list -format=json | jq -r '.["userpass-test/"].accessor' > accessor_test.txt

# Create 'Team Lead' entity
vault write -format=json identity/entity name="James Thomas" policies="admin" \
     metadata=role="Team Lead" \
     | jq -r ".data.id" > entity_id_james.txt

vault write identity/entity-alias name="james" \
     canonical_id=$(cat entity_id_james.txt) \
     mount_accessor=$(cat accessor_test.txt) 

# Create Bob Smith entity
vault write -format=json identity/entity name="Bob Smith" policies="admin" \
     | jq -r ".data.id" > entity_id_bob.txt

vault write identity/entity-alias name="bob" \
     canonical_id=$(cat entity_id_bob.txt) \
     mount_accessor=$(cat accessor_test.txt) 

# Add an RGP policy
cat <<EOF | base64 | vault write sys/policies/rgp/test-rgp policy=- enforcement_level="hard-mandatory"
import "strings"

precond = rule {
    strings.has_prefix(request.path, "sys/policies/acl/admin")
}

main = rule when precond {
    identity.entity.metadata.role is "Team Lead" or 
  		identity.entity.name is "James Thomas"
}
EOF

# Create 'sysops' group with RGP attached
vault write -format=json identity/group name="sysops" \
     policies="sysops, test-rgp" \
     member_entity_ids="$(cat entity_id_james.txt), $(cat entity_id_bob.txt)" \
     | jq -r ".data.id" > group_id_sysops.txt
