#!/bin/bash
yum -y update
yum -y install curl which
yum install java-1.8.0-openjdk-devel.x86_64 -y
yum install jq -y
# clean
yum clean all
# Confluent Public Key for repo
rpm --import https://packages.confluent.io/rpm/5.3/archive.key
# create repo for yum
cd /etc/yum.repos.d/
echo "[Confluent.dist]
name=Confluent repository (dist)
baseurl=https://packages.confluent.io/rpm/5.3/7
gpgcheck=1
gpgkey=https://packages.confluent.io/rpm/5.3/archive.key
enabled=1

[Confluent]
name=Confluent repository
baseurl=https://packages.confluent.io/rpm/5.3
gpgcheck=1
gpgkey=https://packages.confluent.io/rpm/5.3/archive.key
enabled=1" > confluent.repo
# Install Confluent REST-Proxy
yum -y install confluent-kafka-rest
# Create Property file for Kafka Rest Proxy to work with Confluent Cloud
cd /home/ec2-user/
echo "id=kafka-rest-with-ccloud
listeners=http://0.0.0.0:80
bootstrap.servers=${confluent_cloud_broker}
client.sasl.mechanism=PLAIN
client.sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username=\"${confluent_cloud_broker_key}\" password=\"${confluent_cloud_broker_secret}\";
client.security.protocol=SASL_SSL
client.ssl.endpoint.identification.algorithm=https
# consumer only properties must be prefixed with consumer.
consumer.retry.backoff.ms=600
consumer.request.timeout.ms=25000
# producer only properties must be prefixed with producer.
producer.acks=1
# admin client only properties must be prefixed with admin.
admin.request.timeout.ms=50000
# uncomment and set correct value if using with schema registry
schema.registry.basic.auth.credentials.source=USER_INFO
schema.registry.basic.auth.user.info=${confluent_cloud_schema_key}:${confluent_cloud_schema_secret}
schema.registry.url=${confluent_cloud_schema_url}" > ccloud_kafka-rest.properties
# Start Kafka REST Proxy
kafka-rest-start -daemon /home/ec2-user/ccloud_kafka-rest.properties


