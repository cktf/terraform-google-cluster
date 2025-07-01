# Terraform Google Cluster

![pipeline](https://github.com/cktf/terraform-google-cluster/actions/workflows/ci.yml/badge.svg)
![release](https://img.shields.io/github/v/release/cktf/terraform-google-cluster?display_name=tag)
![license](https://img.shields.io/github/license/cktf/terraform-google-cluster)

General-purpose cluster provisioner for Google Cloud, suitable for configuring workload managers like Swarm, Kubernetes, or Nomad, supporting groups of servers and load balancers.

## Installation

Add the required configurations to your terraform config file and install module using command bellow:

```bash
terraform init
```

## Usage

```hcl
module "cluster" {
  source = "cktf/cluster/google"

  name        = "mycluster"
  public_key  = "<REDACTED>"
  private_key = "<REDACTED>"

  servers = {
    manager-1 = {
      type    = "cx22"
      groups  = ["manager"]
      attach  = true
      network = 12345
    }
    manager-2 = {
      type    = "cx22"
      groups  = ["manager"]
      attach  = true
      network = 12345
    }
    manager-3 = {
      type    = "cx22"
      groups  = ["manager"]
      attach  = true
      network = 12345
    }

    worker-1 = {
      type    = "cx52"
      groups  = ["worker"]
      attach  = true
      network = 12345
    }
    worker-2 = {
      type    = "cx52"
      groups  = ["worker"]
      attach  = true
      network = 12345
    }
    worker-3 = {
      type    = "cx52"
      groups  = ["worker"]
      attach  = true
      network = 12345
    }
    worker-4 = {
      type    = "cx52"
      groups  = ["worker"]
      attach  = true
      network = 12345
    }
    worker-5 = {
      type    = "cx52"
      groups  = ["worker"]
      attach  = true
      network = 12345
    }
  }

  load_balancers = {
    default = {
      groups  = ["manager", "worker"]
      attach  = true
      network = 12345
      mapping = {
        80  = 80
        443 = 443
      }
    }
  }
}
```

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License

This project is licensed under the [MIT](LICENSE.md).  
Copyright (c) KoLiBer (koliberr136a1@gmail.com)
