variable "zone" {
  default = "at-vie-1"
}

variable "vm" {
  default = "Linux Ubuntu 20.04 LTS 64-bit"
}

variable "tport" {
  default = "9100"
}

data "exoscale_compute_template" "instancepool" {
  zone = var.zone
  name = var.vm
}

data "exoscale_compute_template" "ubuntu" {
  zone = var.zone
  name = var.vm
}

resource "exoscale_instance_pool" "sprint_one_instance_pool" {
  zone               = var.zone
  name               = "sprint_one"
  description        = "This is the pool for sprint2"
  template_id        = data.exoscale_compute_template.instancepool.id
  service_offering   = "micro"
  size               = 3
  disk_size          = 10
  key_pair           = ""
  security_group_ids = [exoscale_security_group.sg.id]
  user_data = <<EOF
#!/bin/bash
set -e
apt update
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo docker pull janoszen/http-load-generator:latest
sudo docker run -d --rm -p 80:8080 janoszen/http-load-generator
docker run -d \
  -p ${var.tport}:${var.tport} \
  --net="host" \
  --pid="host" \
  -v "/:/host:ro,rslave" \
  quay.io/prometheus/node-exporter \
  --path.rootfs=/host
EOF
}

resource "exoscale_nlb" "sprint_one_nlb" {
  zone        = var.zone
  name        = "sprint_one_nlb"
  description = "This is the Network Load Balancer for sprint1"
}

resource "exoscale_nlb_service" "sprint_one_nlb_service" {
  zone             = exoscale_nlb.sprint_one_nlb.zone
  name             = "sprint_one_nlb_service"
  description      = "NLB service for sprint1"
  nlb_id           = exoscale_nlb.sprint_one_nlb.id
  instance_pool_id = exoscale_instance_pool.sprint_one_instance_pool.id
  protocol         = "tcp"
  port             = 80
  target_port      = 80
  strategy         = "round-robin"

  healthcheck {
    mode     = "http"
    port     = 80
    uri      = "/health"
    interval = 10
    timeout  = 10
    retries  = 1
  }
}

resource "exoscale_compute" "prometheus" {
  zone         = var.zone
  display_name = "prometheus"
  template_id  = data.exoscale_compute_template.ubuntu.id
  size         = "Micro"
  disk_size    = 10
  key_pair     = ""
  security_group_ids = [exoscale_security_group.sg.id]
  user_data = <<EOF
#!/bin/bash
set -e
sudo apt update
sudo apt-get -y install prometheus
sudo echo "[
  {
    "targets": [ "localhost:9100" ]
  }
]" > /service-discovery/custom_servers.json;
sudo echo "global:
  scrape_interval: 15s
scrape_configs:
  - job_name: 'prometheus'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:9090']
  - job_name: Monitoring Server Node Exporter
    static_configs:
      - targets:
          - 'localhost:9100'
  - job_name: Sprint two
    file_sd_configs:
      - files:
          - /service-discovery/custom_servers.json
        refresh_interval: 10s"
sudo docker run \
  -d \
  -e EXOSCALE_KEY=${var.exoscale_key} \
  -e EXOSCALE_SECRET=${var.exoscale_secret} \
  -e TARGET_PORT=${var.tport} \
  -e EXOSCALE_ZONE=${var.zone} \
  -e EXOSCALE_INSTANCEPOOL_ID=${exoscale_instance_pool.sprint_one_instance_pool.id} \
  -v /service-discovery/custom_servers.json:/srv/service-discovery/config.json \
  oemerbulut/prometheus_sd

sudo docker run \
    -d \
    -p 9090:9090 \
    -v /srv/service-discovery/:/service-discovery/ \
    -v /srv/prometheus.yml:/etc/prometheus/prometheus.yml \
    prom/prometheus
EOF
}