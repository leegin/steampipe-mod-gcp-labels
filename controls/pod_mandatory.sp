variable "pod_mandatory_labels" {
  type        = list(string)
  description = "A list of mandatory labels to check for."
  default     = ["Environment", "Owner"]
}

locals {
  pod_mandatory_sql = <<-EOT
    with analysis as (
      select
        name,
        title,
        labels ?& $1 as has_mandatory_labels,
        to_jsonb($1) - array(select jsonb_object_keys(labels)) as missing_labels,
        __DIMENSIONS__
      from
        __TABLE_NAME__
    )
    select
      name as resource,
      case
        when has_mandatory_labels then 'ok'
        else 'alarm'
      end as status,
      case
        when has_mandatory_labels then title || ' has all mandatory labels.'
        else title || ' is missing labels: ' || array_to_string(array(select jsonb_array_elements_text(missing_labels)), ', ') || '.'
      end as reason,
      __DIMENSIONS__
    from
      analysis
  EOT
}

locals {
#  mandatory_sql_project  = replace(local.mandatory_sql, "__DIMENSIONS__", "project")
  pod_mandatory_sql_name = replace(local.pod_mandatory_sql, "__DIMENSIONS__", "context_name")
}

benchmark "pod_mandatory" {
  title       = "Pod Mandatory Labels"
  description = "Resources should all have a standard set of labels applied for functions like resource organization, automation, cost control, and access control."
  children = [
    control.pod_mandatory
  ]

    tags = merge(local.kubernetes_labels_common_tags, {
    type = "Benchmark"
  })
}

control "pod_mandatory" {
  title       = "pods should have mandatory labels"
  description = "Check if pods have mandatory labels."
  sql         = replace(local.pod_mandatory_sql_name, "__TABLE_NAME__", "kubernetes_pod")
  param "pod_mandatory_labels" {
    default = var.pod_mandatory_labels
  }
}
