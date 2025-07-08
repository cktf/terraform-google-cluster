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

  groups = {
    manager = {
      zone = "us-central1-a"
    }
    worker = {
      zone = "us-central1-a"
    }
  }

  servers = {
    manager-1 = {
      type   = "e2-small"
      zone   = "us-central1-a"
      image  = "debian-cloud/debian-11"
      groups = ["manager"]
    }
    manager-2 = {
      type   = "e2-small"
      zone   = "us-central1-a"
      image  = "debian-cloud/debian-11"
      groups = ["manager"]
    }
    manager-3 = {
      type   = "e2-small"
      zone   = "us-central1-a"
      image  = "debian-cloud/debian-11"
      groups = ["manager"]
    }

    worker-1 = {
      type   = "e2-medium"
      zone   = "us-central1-a"
      image  = "debian-cloud/debian-11"
      groups = ["worker"]
    }
    worker-2 = {
      type   = "e2-medium"
      zone   = "us-central1-a"
      image  = "debian-cloud/debian-11"
      groups = ["worker"]
    }
    worker-3 = {
      type   = "e2-medium"
      zone   = "us-central1-a"
      image  = "debian-cloud/debian-11"
      groups = ["worker"]
    }
    worker-4 = {
      type   = "e2-medium"
      zone   = "us-central1-a"
      image  = "debian-cloud/debian-11"
      groups = ["worker"]
    }
    worker-5 = {
      type   = "e2-medium"
      zone   = "us-central1-a"
      image  = "debian-cloud/debian-11"
      groups = ["worker"]
    }
  }

  balancers = {
    default = {
      type   = "INTERNAL"
      scope  = "GLOBAL"
      groups = ["manager", "worker"]
      mappings = {
        "tcp:80:80"   = {}
        "tcp:443:443" = {}
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
