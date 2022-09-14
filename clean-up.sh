vault login $VAULT_TOKEN

# Delete policies
vault policy delete secrets
vault policy delete admin
vault policy delete sysops
vault policy delete test-rgp

# Delete entities and a group
vault delete identity/group/id/$(cat group_id_sysops.txt)
vault delete identity/entity/id/$(cat entity_id_james.txt)
vault delete identity/entity/id/$(cat entity_id_bob.txt)
vault auth disable userpass-test

# Delete created files
rm group_id_sysops.txt entity_id_james.txt entity_id_bob.txt bob_token.txt james_token.txt accessor_test.txt