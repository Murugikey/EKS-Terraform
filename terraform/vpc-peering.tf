##### VPC Peering SFCNONPRODSS #####
resource "aws_vpc_peering_connection" "vpc_peering_connection_sfcnonprodss" {
  peer_owner_id = var.VPC_PEER_SETTINGS_SFCNONPRODSS.PEER_ACCOUNT_ID
  peer_vpc_id   = var.VPC_PEER_SETTINGS_SFCNONPRODSS.PEER_VPC_ID
  peer_region   = var.VPC_PEER_SETTINGS_SFCNONPRODSS.PEER_REGION
  vpc_id        = aws_vpc.vpc.id
  tags = merge(
    local.common_tags,
    tomap({
      "Name" = "Request for the VPC Peering connection with VPN, Account ID: ${var.VPC_PEER_SETTINGS_SFCNONPRODSS.PEER_ACCOUNT_ID}"
      "SecurityZone" = "X2"
    })
  )
}

##### VPC Peering SHARED SERVICES #####
resource "aws_vpc_peering_connection" "vpc_peering_connection_shared_services" {
  peer_owner_id = var.VPC_PEER_SETTINGS_SHARED_SERVICES.PEER_ACCOUNT_ID
  peer_vpc_id   = var.VPC_PEER_SETTINGS_SHARED_SERVICES.PEER_VPC_ID
  peer_region   = var.VPC_PEER_SETTINGS_SHARED_SERVICES.PEER_REGION
  vpc_id        = aws_vpc.vpc.id
  tags = merge(
    local.common_tags,
    tomap({
      "Name" = "Request for the VPC Peering connection with VPN, Account ID: ${var.VPC_PEER_SETTINGS_SHARED_SERVICES.PEER_ACCOUNT_ID}"
      "SecurityZone" = "X2"
    })
  )
}