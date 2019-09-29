###########################################
################# Outputs #################
###########################################

output "SSH" {
  value = tonumber(var.instance_count) >= 1 ? "SSH  Access: ssh -i ~/keys/hackathon-temp-key.pem ec2-user@${join(",",formatlist("%s", aws_instance.kafka-rest.*.public_ip),)} " : "Confluent Cloud Platform on AWS is disabled" 
}
output "REST_Call" {
  value = tonumber(var.instance_count) >= 1 ? "List Topics with curl: curl http://${join(",",formatlist("%s", aws_instance.kafka-rest.*.public_ip),)}:80/topics" : "Confluent Cloud Platform on AWS is disabled"
}  
