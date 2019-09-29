#########################################################
######## Confluent Kafka-Rest 5.3 Dev Instance ##########
#########################################################

data "template_file" "confluent_instance" {
  template = file("utils/instance.sh")

  vars = {
    confluent_cloud_broker        = var.cc_broker_url
    confluent_cloud_broker_key    = var.cc_broker_key
    confluent_cloud_broker_secret = var.cc_broker_secret
    confluent_cloud_schema_url    = var.cc_schema_url
    confluent_cloud_schema_key    = var.cc_schema_key
    confluent_cloud_schema_secret = var.cc_schema_secret
  }
}
