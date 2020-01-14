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
# Install Confluent KSQL
yum -y install confluent-ksql

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

# Create Property file for Kafka KSQL to work with Confluent Cloud
cd /home/ec2-user/
echo "# KSQL Basic
request.timeout.ms=20000
retry.backoff.ms=500
listeners=http://0.0.0.0:8088
bootstrap.servers=${confluent_cloud_broker}
ssl.endpoint.identification.algorithm=https
sasl.mechanism=PLAIN
security.protocol=SASL_SSL
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username=\"${confluent_cloud_broker_key}\" password=\"${confluent_cloud_broker_secret}\";
ksql.schema.registry.basic.auth.credentials.source=USER_INFO
ksql.schema.registry.basic.auth.user.info=${confluent_cloud_schema_key}:${confluent_cloud_schema_secret}
ksql.schema.registry.url=${confluent_cloud_schema_url}
# Confluent Monitoring Interceptor specific configuration
confluent.monitoring.interceptor.ssl.endpoint.identification.algorithm=https
confluent.monitoring.interceptor.sasl.mechanism=PLAIN
confluent.monitoring.interceptor.security.protocol=SASL_SSL
confluent.monitoring.interceptor.bootstrap.servers=${confluent_cloud_broker}
confluent.monitoring.interceptor.sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username=\"${confluent_cloud_broker_key}\" password=\"${confluent_cloud_broker_secret}\";
# KSQL Server specific configuration
producer.interceptor.classes=io.confluent.monitoring.clients.interceptor.MonitoringProducerInterceptor
consumer.interceptor.classes=io.confluent.monitoring.clients.interceptor.MonitoringConsumerInterceptor
ksql.streams.producer.retries=2147483647
ksql.streams.producer.confluent.batch.expiry.ms=9223372036854775807
ksql.streams.producer.request.timeout.ms=300000
ksql.streams.producer.max.block.ms=9223372036854775807
ksql.streams.replication.factor=3
ksql.internal.topic.replicas=3
ksql.sink.replicas=3
ksql.logging.processing.topic.replication.factor=3
# Confluent Schema Registry configuration for KSQL Server
ksql.schema.registry.basic.auth.credentials.source=USER_INFO
ksql.schema.registry.basic.auth.user.info=${confluent_cloud_schema_key}:${confluent_cloud_schema_secret}
ksql.schema.registry.url=${confluent_cloud_schema_url}" > ccloud_ksql.properties


# Start Kafka REST Proxy
kafka-rest-start -daemon /home/ec2-user/ccloud_kafka-rest.properties
# Start KSQL
ksql-server-start -daemon /home/ec2-user/ccloud_ksql.properties

