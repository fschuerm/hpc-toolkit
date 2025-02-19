/**
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

output "ramble_runner" {
  description = <<-EOT
  Runner to setup Ramble using an ansible playbook. The startup-script module
  will automatically handle installation of ansible.
  - id: example-startup-script
    source: modules/scripts/startup-script
    settings:
      runners:
      - $(your-ramble-id.ramble_setup_runner)
  ...
  EOT
  value       = local.ramble_setup_runner
}

output "ramble_path" {
  description = "Location ramble is installed into."
  value       = var.install_dir
}

output "ramble_ref" {
  description = "Git ref the ramble install is checked out to use"
  value       = var.ramble_ref
}
