job "rabbitmq" {
  datacenters = ["dc1"]
  type        = "service"

  group "rabbitmq-cluster" {
    count = 3

    constraint {
      distinct_hosts = true
    }

    update {
      max_parallel = 1
    }

    network {
      port "rabbitmq" {
        static = 5672
      }
      port "rabbitmq-management" {
        static = 15672
      }

      port "rabbitmq-clustering" {
        static = 25672
      }

      port "rabbitmq-epmd" {
        static = 4369
      }
    }

    task "rabbitmq" {
      driver = "docker"

      config {
        image    = "rabbitmq:3.8-management-alpine"
        hostname = "${attr.unique.hostname}"
        ports    = ["rabbitmq", "rabbitmq-management", "rabbitmq-clustering", "rabbitmq-epmd"]

        volumes = [
          "local/enabled_plugins:/etc/rabbitmq/enabled_plugins",
          "local/rabbitmq.conf:/etc/rabbitmq/rabbitmq.conf",
        ]
      }

      resources {
        cpu    = 300
        memory = 1024
      }

      env {
        RABBITMQ_ERLANG_COOKIE = "rabbitmq"
        RABBITMQ_DEFAULT_USER  = "test"
        RABBITMQ_DEFAULT_PASS  = "test"
      }

      template {
        data        = <<EOH
[rabbitmq_management,rabbitmq_peer_discovery_consul].
EOH
        destination = "local/enabled_plugins"
      }

      template {
        data        = <<EOH
cluster_formation.peer_discovery_backend = consul
cluster_formation.consul.host = {{ env "attr.unique.network.ip-address" }}
EOH
        destination = "local/rabbitmq.conf"
      }
    }
  }
}