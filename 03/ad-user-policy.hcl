# Grant permissions on user specific path
path "user-kv/data/application01" {
    capabilities = [ "create", "update", "read", "delete", "list" ]
}

# Grant permissions on user specific path
path "user-kv/application01" {
    capabilities = [ "create", "update", "read", "delete", "list" ]
}

# Grant permissions on user specific path
path "user-kv/data/{{identity.entity.name}}/*" {
    capabilities = [ "create", "update", "read", "delete", "list" ]
}

# Grant permissions on user specific path
path "user-kv/{{identity.entity.name}}/*" {
    capabilities = [ "create", "update", "read", "delete", "list" ]
}

# For Web UI usage
path "user-kv/metadata" {
  capabilities = ["list"]
}