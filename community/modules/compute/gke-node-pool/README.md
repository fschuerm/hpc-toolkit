## Description

This module creates a Google Kubernetes Engine
([GKE](https://cloud.google.com/kubernetes-engine)) node pool.

> **_NOTE:_** This is an experimental module and the functionality and
> documentation will likely be updated in the near future. This module has only
> been tested in limited capacity.

### Example

The following example creates a GKE node group.

```yaml
  - id: compute_pool
    source: community/modules/compute/gke-node-pool
    use: [gke_cluster]
```

Also see a full [GKE example blueprint](../../../examples/hpc-gke.yaml).

### Taints and Tolerations

By default node pools created with this module will be tainted with
`user-workload=true:NoSchedule` to prevent system pods from being scheduled.
User jobs targeting the node pool should include this toleration. This behavior
can be overridden using the `taints` setting. See
[docs](https://cloud.google.com/kubernetes-engine/docs/how-to/node-taints) for
more info.

### Local SSD Storage
GKE offers two options for managing locally attached SSDs.  

The first, and recommended, option is for GKE to manage the ephemeral storage
space on the node, which will then be automatically attached to pods which
request an `emptyDir` volume. This can be accomplished using the
[`local_ssd_count_ephemeral_storage`] variable.

The second, more complex, option is for GCP to attach these nodes as raw block
storage. In this case, the cluster administrator is responible for software
RAID settings, partitioning, formatting and mounting these disks on the host
OS.  Still, this may be desired behavior in use cases which aren't supported
by an `emptyDir` volume (for example, a `ReadOnlyMany` or `ReadWriteMany` PV).
This can be accomplished using the [`local_ssd_count_nvme_block`] variable.

The [`local_ssd_count_ephemeral_storage`] and [`local_ssd_count_nvme_block`]
variables are mutually exclusive and cannot be mixed together.

Also, the number of SSDs which can be attached to a node depends on the
[machine type](https://cloud.google.com/compute/docs/disks#local_ssd_machine_type_restrictions).

See [docs](https://cloud.google.com/kubernetes-engine/docs/how-to/persistent-volumes/local-ssd)
for more info.

[`local_ssd_count_ephemeral_storage`]: #input\_local\_ssd\_count\_ephemeral\_storage
[`local_ssd_count_nvme_block`]: #input\_local\_ssd\_count\_nvme\_block

### Considerations with GPUs

When a GPU is attached to a node an additional taint is automatically added:
`nvidia.com/gpu=present:NoSchedule`. For jobs to get placed on these nodes, the
equivalent toleration is required. The `gke-job-template` module will
automatically apply this toleration when using a node pool with GPUs.

Nvidia GPU drivers must be installed.  The recommended approach for GKE to install
GPU dirvers is by applying a DaemonSet to the cluster. See
[these instructions](https://cloud.google.com/kubernetes-engine/docs/how-to/gpus#cos).

However, in some cases it may be desired to compile a different driver (such as
a desire to install a newer version, compatibility with the
[Nvidia GPU-operator](https://github.com/NVIDIA/gpu-operator) or other
use-cases). In this case, ensure that you turn off the
[enable_secure_boot](#input\_enable\_secure\_boot) option to allow unsigned
kernel modules to be loaded.

### GPUs Examples

There are several ways to add GPUs to a GKE node pool. See
[docs](https://cloud.google.com/compute/docs/gpus) for more info on GPUs.

The following is a node pool that uses `a2` or `g2` machine types which has a
fixed number of attached GPUs:

```yaml
  - id: simple-a2-pool
    source: community/modules/compute/gke-node-pool
    use: [gke_cluster]
    settings:
      machine_type: a2-highgpu-1g
```

> **Note**: It is not necessary to define the [`guest_accelerator`] setting when
> using `a2` or `g2` machines as information about GPUs, such as type and count,
> is automatically inferred from the machine type.

The following scenarios require the [`guest_accelerator`] block is specified:

- To partition an A100 GPU into multiple GPUs on an A2 family machine.
- To specify a time sharing configuration on a GPUs.
- To attach a GPU to an N1 family machine.

The following is an example of
[partitioning](https://cloud.google.com/kubernetes-engine/docs/how-to/gpus-multi)
an A100 GPU:

```yaml
  - id: multi-instance-gpu-pool
    source: community/modules/compute/gke-node-pool
    use: [gke_cluster]
    settings:
      machine_type: a2-highgpu-1g
      guest_accelerator:
      - type: nvidia-tesla-a100
        count: 1
        gpu_partition_size: 1g.5gb
        gpu_sharing_config: null
        gpu_driver_installation_config: null
```

> **Note**: Once we define the [`guest_accelerator`] block, all fields must be
> defined. Use `null` for optional fields.

[`guest_accelerator`]: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster#nested_guest_accelerator

The following is an example of
[GPU time sharing](https://cloud.google.com/kubernetes-engine/docs/concepts/timesharing-gpus)
(with partitioned GPUs):

```yaml
  - id: time-sharing-gpu-pool
    source: community/modules/compute/gke-node-pool
    use: [gke_cluster]
    settings:
      machine_type: a2-highgpu-1g
      guest_accelerator:
      - type: nvidia-tesla-a100
        count: 1
        gpu_partition_size: 1g.5gb
        gpu_sharing_config:
        - gpu_sharing_strategy: TIME_SHARING
          max_shared_clients_per_gpu: 3
        gpu_driver_installation_config: null
```

Finally, the following is an example of using a GPU attached to an `n1` machine:

```yaml
  - id: t4-pool
    source: community/modules/compute/gke-node-pool
    use: [gke_cluster]
    settings:
      machine_type: n1-standard-16
      guest_accelerator:
      - type: nvidia-tesla-t4
        count: 2
        gpu_partition_size: null
        gpu_sharing_config: null
        gpu_driver_installation_config: null
```

## License

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
Copyright 2023 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 4.75.1, < 5.0 |
| <a name="requirement_google-beta"></a> [google-beta](#requirement\_google-beta) | >= 4.75.1, < 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 4.75.1, < 5.0 |
| <a name="provider_google-beta"></a> [google-beta](#provider\_google-beta) | >= 4.75.1, < 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google-beta_google_container_node_pool.node_pool](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_container_node_pool) | resource |
| [google_project_iam_member.node_service_account_artifact_registry](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.node_service_account_gcr](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.node_service_account_log_writer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.node_service_account_metric_writer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.node_service_account_monitoring_viewer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.node_service_account_resource_metadata_writer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_compute_default_service_account.default_sa](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_default_service_account) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_auto_upgrade"></a> [auto\_upgrade](#input\_auto\_upgrade) | Whether the nodes will be automatically upgraded. | `bool` | `false` | no |
| <a name="input_autoscaling_total_max_nodes"></a> [autoscaling\_total\_max\_nodes](#input\_autoscaling\_total\_max\_nodes) | Total maximum number of nodes in the NodePool. | `number` | `1000` | no |
| <a name="input_autoscaling_total_min_nodes"></a> [autoscaling\_total\_min\_nodes](#input\_autoscaling\_total\_min\_nodes) | Total minimum number of nodes in the NodePool. | `number` | `0` | no |
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | projects/{{project}}/locations/{{location}}/clusters/{{cluster}} | `string` | n/a | yes |
| <a name="input_compact_placement"></a> [compact\_placement](#input\_compact\_placement) | Places node pool's nodes in a closer physical proximity in order to reduce network latency between nodes. | `bool` | `false` | no |
| <a name="input_disk_size_gb"></a> [disk\_size\_gb](#input\_disk\_size\_gb) | Size of disk for each node. | `number` | `100` | no |
| <a name="input_disk_type"></a> [disk\_type](#input\_disk\_type) | Disk type for each node. | `string` | `"pd-standard"` | no |
| <a name="input_enable_gcfs"></a> [enable\_gcfs](#input\_enable\_gcfs) | Enable the Google Container Filesystem (GCFS). See [restrictions](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster#gcfs_config). | `bool` | `false` | no |
| <a name="input_enable_secure_boot"></a> [enable\_secure\_boot](#input\_enable\_secure\_boot) | Enable secure boot for the nodes.  Keep enabled unless custom kernel modules need to be loaded. See [here](https://cloud.google.com/compute/shielded-vm/docs/shielded-vm#secure-boot) for more info. | `bool` | `true` | no |
| <a name="input_guest_accelerator"></a> [guest\_accelerator](#input\_guest\_accelerator) | List of the type and count of accelerator cards attached to the instance. | <pre>list(object({<br>    type  = string<br>    count = number<br>    gpu_driver_installation_config = list(object({<br>      gpu_driver_version = string<br>    }))<br>    gpu_partition_size = string<br>    gpu_sharing_config = list(object({<br>      gpu_sharing_strategy       = string<br>      max_shared_clients_per_gpu = number<br>    }))<br>  }))</pre> | `null` | no |
| <a name="input_image_type"></a> [image\_type](#input\_image\_type) | The default image type used by NAP once a new node pool is being created. Use either COS\_CONTAINERD or UBUNTU\_CONTAINERD. | `string` | `"COS_CONTAINERD"` | no |
| <a name="input_kubernetes_labels"></a> [kubernetes\_labels](#input\_kubernetes\_labels) | Kubernetes labels to be applied to each node in the node group. Key-value pairs. <br>(The `kubernetes.io/` and `k8s.io/` prefixes are reserved by Kubernetes Core components and cannot be specified) | `map(string)` | `null` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | GCE resource labels to be applied to resources. Key-value pairs. | `map(string)` | n/a | yes |
| <a name="input_local_ssd_count_ephemeral_storage"></a> [local\_ssd\_count\_ephemeral\_storage](#input\_local\_ssd\_count\_ephemeral\_storage) | The number of local SSDs to attach to each node to back ephemeral storage.<br>Uses NVMe interfaces.  Must be supported by `machine_type`.<br>[See above](#local-ssd-storage) for more info. | `number` | `0` | no |
| <a name="input_local_ssd_count_nvme_block"></a> [local\_ssd\_count\_nvme\_block](#input\_local\_ssd\_count\_nvme\_block) | The number of local SSDs to attach to each node to back block storage.<br>Uses NVMe interfaces.  Must be supported by `machine_type`.<br>[See above](#local-ssd-storage) for more info. | `number` | `0` | no |
| <a name="input_machine_type"></a> [machine\_type](#input\_machine\_type) | The name of a Google Compute Engine machine type. | `string` | `"c2-standard-60"` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the node pool. If left blank, will default to the machine type. | `string` | `null` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The project ID to host the cluster in. | `string` | n/a | yes |
| <a name="input_service_account"></a> [service\_account](#input\_service\_account) | DEPRECATED: use service\_account\_email and scopes. | <pre>object({<br>    email  = string,<br>    scopes = set(string)<br>  })</pre> | `null` | no |
| <a name="input_service_account_email"></a> [service\_account\_email](#input\_service\_account\_email) | Service account e-mail address to use with the node pool | `string` | `null` | no |
| <a name="input_service_account_scopes"></a> [service\_account\_scopes](#input\_service\_account\_scopes) | Scopes to to use with the node pool. | `set(string)` | <pre>[<br>  "https://www.googleapis.com/auth/cloud-platform"<br>]</pre> | no |
| <a name="input_spot"></a> [spot](#input\_spot) | Provision VMs using discounted Spot pricing, allowing for preemption | `bool` | `false` | no |
| <a name="input_static_node_count"></a> [static\_node\_count](#input\_static\_node\_count) | The static number of nodes in the node pool. If set, autoscaling will be disabled. | `number` | `null` | no |
| <a name="input_taints"></a> [taints](#input\_taints) | Taints to be applied to the system node pool. | <pre>list(object({<br>    key    = string<br>    value  = any<br>    effect = string<br>  }))</pre> | <pre>[<br>  {<br>    "effect": "NO_SCHEDULE",<br>    "key": "user-workload",<br>    "value": true<br>  }<br>]</pre> | no |
| <a name="input_threads_per_core"></a> [threads\_per\_core](#input\_threads\_per\_core) | Sets the number of threads per physical core. By setting threads\_per\_core<br>to 2, Simultaneous Multithreading (SMT) is enabled extending the total number<br>of virtual cores. For example, a machine of type c2-standard-60 will have 60<br>virtual cores with threads\_per\_core equal to 2. With threads\_per\_core equal<br>to 1 (SMT turned off), only the 30 physical cores will be available on the VM.<br><br>The default value of \"0\" will turn off SMT for supported machine types, and<br>will fall back to GCE defaults for unsupported machine types (t2d, shared-core<br>instances, or instances with less than 2 vCPU).<br><br>Disabling SMT can be more performant in many HPC workloads, therefore it is<br>disabled by default where compatible.<br><br>null = SMT configuration will use the GCE defaults for the machine type<br>0 = SMT will be disabled where compatible (default)<br>1 = SMT will always be disabled (will fail on incompatible machine types)<br>2 = SMT will always be enabled (will fail on incompatible machine types) | `number` | `0` | no |
| <a name="input_timeout_create"></a> [timeout\_create](#input\_timeout\_create) | Timeout for creating a node pool | `string` | `null` | no |
| <a name="input_timeout_update"></a> [timeout\_update](#input\_timeout\_update) | Timeout for updating a node pool | `string` | `null` | no |
| <a name="input_total_max_nodes"></a> [total\_max\_nodes](#input\_total\_max\_nodes) | DEPRECATED: Use autoscaling\_total\_max\_nodes. | `number` | `null` | no |
| <a name="input_total_min_nodes"></a> [total\_min\_nodes](#input\_total\_min\_nodes) | DEPRECATED: Use autoscaling\_total\_min\_nodes. | `number` | `null` | no |
| <a name="input_zones"></a> [zones](#input\_zones) | A list of zones to be used. Zones must be in region of cluster. If null, cluster zones will be inherited. Note `zones` not `zone`; does not work with `zone` deployment variable. | `list(string)` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_allocatable_cpu_per_node"></a> [allocatable\_cpu\_per\_node](#output\_allocatable\_cpu\_per\_node) | Number of CPUs available for scheduling pods on each node. |
| <a name="output_has_gpu"></a> [has\_gpu](#output\_has\_gpu) | Boolean value indicating whether nodes in the pool are configured with GPUs. |
| <a name="output_node_pool_name"></a> [node\_pool\_name](#output\_node\_pool\_name) | Name of the node pool. |
| <a name="output_tolerations"></a> [tolerations](#output\_tolerations) | Tolerations needed for a pod to be scheduled on this node pool. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
