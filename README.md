# clickhouse-single-node-deployment

This is a template for a single node clickhouse deployment on a hetzner cloud vm bundled with prometheus and grafana for monitoring

### Stack
1. Terraform for server setup.
2. Bash scripts to install clickhouse, prometheus, grafana, and node-exporter.


How to run

1. Create an aws profile to configure aws cli
2. initalize terraform backend with s3, you will need to create a state.config file

```
# state.config
bucket = "" 
key    = ""
region = ""
profile= "aws profile"
```

```
terraform init -backend-config="./state.config"
```

3. Run  `terraform plan`

4. Run `terraform apply -var-file terraform.tfvars`

Note: copy `terraform.tfvars.template` to `terraform.tfvars` and configure to your taste.


# TODO

1. Think about using ansible for configuring the services
2. Improve the documentation
3. Add if-else statement to the script to check if the service is running.
4. Implement env for the script
5. add custom config (config.xml) and prometheus.yml to the scripts.

### Configure Clickhouse
To configure clickhouse for logging, we edit the config.xml file in the config.d directory. This can be found under `/etc/clickhouse-server/config.d/` path

A sample config.xml file can be found in the `configs` directory under this repository.


### Configure Prometheus
To configure prometheus, you need to edit the prometheus.yml file under the `/etc/prometheus/prometheus.yml`.

A sample config can be found under the `configs` directory in this repo