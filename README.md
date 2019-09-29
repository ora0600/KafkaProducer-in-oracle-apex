# KafkaProducer-in-oracle-apex
Create a Kafka producer in Oracle Apex, which produces events into Confluent Clound real-time event streaming platform.

## setup the Confluent Cloud a fully managed realt-time streaming platform
What is easier than goto [Confluent Cloud](https://www.confluent.io/confluent-cloud) and sign up for a real-time streaming platform? I can say, not much.
Register yourself and you will have immediately a running kafka cluster and can start your work.

If the cluster is running, create your environment and then create a new cluster. The cluster setup allows to create an API Key with secret, please create one(go tp cluster setting/ API access). We also need access to fully managed Schema registry. Please create also a Key with secret to access the Schema registry (go to Schema/ API access).

The confluent cloud is running for you a fully managed zookeeper, broker and Schema registry cluster, with Topic management, connector management (only cloud object connectors right now, more will come), KSQL (in preview, full GA will follow), consumer management and some monitor features.

## The project goal - run a kafka producer into APEX
I would like to add a producer into my Oracle Application Express application and produce event from apex into my Kafka cluster running in the confluent cloud.
It is easy going...

### Use a Kafka-REST proxy with the Confluent Cloud
To access the Confluent Cloud very easily from APEX, I decided to use a Kafka-Rest proxy. For this I prepared a terraform script, which will setup and run a Kafka-REST Proxy and access the Confluent Cloud. For this demo setup, no security in Kafka-REST proxy was activated. The REST-Proxy will listen on port 80.
Everything what you need to do, is to enter all your content regarding AWS API keys and Confluent Cloud API Keys like
  * aws API key
  * aws API secret
  * confluent cloud broker url with port
  * confluent cloud broker API key
  * confluent cloud broker API secret
  * confluent cloud schema registry URL
  * confluent cloud schema registry API key
  * confluent cloud schema registry API secret
  * aws_region
  * aws ssh_key_name

These parameters are found in the variables.tf file. So, what you need to do:
  * download git repo
  * change the values in variables.tf
  * execute terraform

To execute terraform after changing variables.tf, do the following
```
terraform init
terraform plan
terraform apply
```
Your Kafka REST-Proxy will be up and running after provisioning. The output after provisioning looks like this:
```
REST_Call = List Topics with curl: curl http://pub-IP:80/topics
SSH = SSH  Access: ssh -i ~/keys/yourkey.pem ec2-user@PUB-IP
```
Test your Kafka-REST proxy and list all topics in confluent cloud:
```
curl http://pub-IP:80/topics
```

### Setup your local machine for access the confluent cloud
Confluent cloud offers a cli to manage the confluent cloud from the prompt. Please active the ccloud of confluent and follow the [installation guide](https://docs.confluent.io/current/cloud/cli/install.html):
Active your Confluent Cloud customer with cc cli:
```
ccloud login
ccloud environment use ENVID
ccloud kafka cluster use CLUSTERID
ccloud api-key store CCAPIKEY CCAPISECRET
ccloud api-key use CCAPIKEY
```
Now, you are able to create a new topic in your Confluent Cloud cluster (you could do it also in the UI):
```
ccloud kafka topic create cmfeedback
ccloud kafka topic list
```
I decided to create a Producer in my APEX app, which should collect feedback of all the attendes of my events I visit as presenter. I run my business card in APEX, where you are able to download my business card via QR code.
The Schema of my Topic looks like this:
```
{
  "type": "record",
  "name": "value_cmfeedback",
  "namespace": "cm",
  "fields": [{"name" : "email", "type" : "string"},
             {"name" : "forWHAT", "type" : "string"},
             {"name" : "feedback", "type" : "string"}
            ]
}
```
I put that Schema into a file cmfeedback.json and register that schema as value to my topic cmfeedback:
```
ccloud schema-registry schema create --subject cmfeedback-value --schema ./cmfeedback.json
```
Check in the UI if Schema is registered against my topic. It should look like this:

## Add the producer into APEX 
Now, the Kafka-REST proxy is running and let me allow to send stupid REST call against the Confluent Cloud Kafka cluster. my payload would be of type JSON, and type of data is registered as Schema. A typically looks like this by the way:
```
curl -X POST -H "Content-Type: application/vnd.kafka.json.v2+json" \
      -H "Accept: application/vnd.kafka.v2+json" \
      --data '{"records":[{"value":{"email":"trick@duck","forWhat":"Meetup Dresden","feedback":"Fantastic"}}]}' "http://pub-ip:80/topics/cmfeedback"
```
This call format is transfered into a PL/SQL procedure in APEX, so that I can easy produce events into the Kafka cluster running ini Confluent Cloud. The procedure looks like this:
```
create or replace Procedure ProduceMessage2CC(p_email varchar2, p_forwhat varchar2, p_feedback varchar2) as
    l_clob       CLOB;
    l_payload    varchar2(4000) := NULL;
BEGIN
-- build the rest call service call
  apex_web_service.g_request_headers(1).name := 'Content-Type';
  apex_web_service.g_request_headers(1).value := 'application/vnd.kafka.json.v2+json';
-- create payload
  l_payload := '{"records":[{"value":{"email":"'||p_email||'","forWhat":"'||p_forwhat||'","feedback":"'||p_feedback||'"}}]} "http://pub-ip:80/topics/cmfeedback"';
  l_clob := apex_web_service.make_rest_request(
        p_url => 'http://pub-ip:80/topics/cmfeedback',
        p_http_method => 'POST',
        p_body => l_payload
        );
exception 
WHEN OTHERS THEN
      raise_application_error (-20002,'An error has occurred during REST-CALL');
END;
```
You just have to install the PL/SQL in your APEX environment and use it in your APEX app. I did create a page with a Form based on the procedure, there is no coding, just clicking:

Now, you extend your APEX app with Kafka-Producer using the KAFKA-REST Proxy and produce events into your Confluent Cloud Kafka cluster.

## On my Laptop I do check the feedback with KSQL
On my laptop I connect myself with the Confluent Cloud and review the feedback. For This I run my local installation of KSQL and do just some simple select.
Before running KSQL I need the correct properties file, which tells KSQL that the cluster is running in Confluent Cloud. So create a correct property file first and than run KSQL:
```
# first configure ccloud for ksql
echo "# Configuration derived from template_delta_configs/example_ccloud_config
listeners=http://0.0.0.0:8088
ssl.endpoint.identification.algorithm=https
sasl.mechanism=PLAIN
request.timeout.ms=20000
retry.backoff.ms=500
security.protocol=SASL_SSL
bootstrap.servers=CONFLUENTCLOUDB-ROKERURL-WITH-PORT
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="CONFLUENTCLOUD-APIKEY" password="CONFLUENTCLOUD-APISECRET";
basic.auth.credentials.source=USER_INFO
schema.registry.basic.auth.user.info=CONFLUENTCLOUD-SCHEMAAPIKEY:CONFLUENTCLOUD-SCHEMAAPISECRET
schema.registry.url=CONFLUENTCLOUD-SCHEMAURL
# Confluent Monitoring Interceptor specific configuration
confluent.monitoring.interceptor.ssl.endpoint.identification.algorithm=https
confluent.monitoring.interceptor.sasl.mechanism=PLAIN
confluent.monitoring.interceptor.security.protocol=SASL_SSL
confluent.monitoring.interceptor.bootstrap.servers=CONFLUENTCLOUDB-ROKERURL-WITH-PORT
confluent.monitoring.interceptor.sasl.jaas.config=confluent.monitoring.intercerity.plain.Plainconfluent.monitorind username="CONFLUENTCLOUD-APIKEY" password="CONFLUENTCLOUD-APISECRET";
# KSQL Server specific configuration
producer.interceptor.classes=io.confluent.monitoring.clients.interceptor.MonitoringProducerInterceptor
consumer.interceptor.classes=io.confluent.monitoring.clients.interceptor.MonitoringConsumerInterceptor
ksql.streams.producer.retries=2147483647
ksql.streams.producer.confluent.batch.expiry.ms=9223372036854775807
ksql.streams.producer.request.timeout.ms=300000
ksql.streams.producer.max.block.ms=9223372036854775807
ksql.streams.replication.factor=3
ksql.internal.topic.rksql.internal.topic.rksql.internal.topic.rksql.internal.topic.rksql.internar KSQL Server
ksql.schema.registry.basic.auth.credentials.source=USER_INFO
ksql.schema.registry.basic.auth.user.info=CONFLUENTCLOUD-SCHEMAAPIKEY:CONFLUENTCLOUD-SCHEMAAPISECRET
ksql.schema.registry.url=CONFLUENTCLOUD-SCHEMAURL" > ccloud_ksql.properties
# Start KSQL server on your local machine
ksql-server-start ./ccloud_ksql.properties
# do the analysis
ksql
ksql> list topics;
ksql> CREATE stream s_cmfeedback (email VARCHAR, forWHAT varchar, feedback varchar)  WITH (KAFKA_TOPIC='cmfeedback', VALUE_FORMAT='JSON');
ksql> SET 'auto.offset.reset' = 'earliest';
ksql> select * from s_cmfeedback limit 3;
1569668813053 | null | donald@duck | Meetup DUS | Fantastic
1569674781804 | null | trick@duck | Meetup Dresden | Fantastic
1569676788019 | null | trick@duck | Meetup Dresden | Fantastic
ksql> select * from s_cmfeedback where forWHAT = 'Meetup Dresden';
1569668862446 | null | daisy@duck | Meetup Dresden | Fantastic
1569676816681 | null | trick@duck | Meetup Dresden | Fantastic
1569676963481 | null | cmutzlitz@confluent.io | Meetup Dresden | great event and lot of discussion
1569674781804 | null | trick@duck | Meetup Dresden | Fantastic
1569676788019 | null | trick@duck | Meetup Dresden | Fantastic
1569676983377 | null | cmutzlitz@confluent.io | Meetup Dresden | great event and lot of discussion
ksql> exit
## Stop the KSQL Server
ksql-server-stop ./ccloud_ksql.properties

# Conclusion
I really love APEX because it really easy to create a cool web app. The add-on for Kafka-Producer is also very easy if you use a Kafka-REST Prooxy.