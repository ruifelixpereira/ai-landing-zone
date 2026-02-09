locals {
    apim_role_assignments = try(var.apim_definition.role_assignments, {})
}
