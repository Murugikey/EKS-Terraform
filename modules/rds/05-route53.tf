resource "aws_route53_record" "rds_dns_associate" {
  count   = var.DNS_ASSOCIATE.name != "null" ? 1 : 0
  
  zone_id = var.DNS_ASSOCIATE.zone_id
  name    = var.DNS_ASSOCIATE.name
  type    = "CNAME"
  records = ["${aws_db_instance.rds_instance.address}"] 
  ttl     = 300
  depends_on = [
    aws_db_instance.rds_instance
  ]
}