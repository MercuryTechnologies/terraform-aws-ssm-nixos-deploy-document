
output "arn" {
    description = "The Amazon Resource Name (ARN) of the document"
    value       = aws_ssm_document.nixos_deploy.arn
}

output "created_date" {
    description = "The date the document was created"
    value       = aws_ssm_document.nixos_deploy.created_date
}

output "default_version" {
    description = "The default version of the document"
    value       = aws_ssm_document.nixos_deploy.default_version
}

output "description" {
    description = "The description of the document"
    value       = aws_ssm_document.nixos_deploy.description
}

output "document_version" {
    description = "The document version"
    value       = aws_ssm_document.nixos_deploy.document_version
}

output "hash_type" {
    description = "The hash type of the document. Valid values: `Sha256`, `Sha1`"
    value       = aws_ssm_document.nixos_deploy.hash_type
}

output "id" {
    description = "The name of the document"
    value       = aws_ssm_document.nixos_deploy.id
}

output "latest_version" {
    description = "The latest version of the document"
    value       = aws_ssm_document.nixos_deploy.latest_version
}

output "parameter" {
    description = "The parameters of the document"
    value       = aws_ssm_document.nixos_deploy.parameter
}

output "platform_types" {
    description = "The list of operating systems compatible with the document"
    value       = aws_ssm_document.nixos_deploy.platform_types
}

output "schema_version" {
    description = "The schema version of the document"
    value       = aws_ssm_document.nixos_deploy.schema_version
}

output "status" {
    description = "The status of the document"
    value       = aws_ssm_document.nixos_deploy.status
}

output "tags_all" {
    description = "A map of tags assigned to the resource, including those inherited from the provider"
    value       = aws_ssm_document.nixos_deploy.tags_all
}