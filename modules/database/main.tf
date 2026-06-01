# 1. Skapa DynamoDB-tabellen
resource "aws_dynamodb_table" "this" {
  name         = "secure-api-notes"
  billing_mode = "PAY_PER_REQUEST" # Serverlös prissättning (kostar 0 kr när det inte används)
  hash_key     = "userId"          # Partition Key (Strukturerat efter Cognitos unika User ID)
  range_key    = "noteId"          # Sort Key (Unikt ID för varje specifik anteckning)

  # Definiera attributen och deras typer (S = String)
  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "noteId"
    type = "S"
  }

# Enterprise Security: Server-side-kryptering aktiverad som standard
  server_side_encryption {
    enabled = true
    # Raden med kms_key_arn är borttagen – AWS hanterar detta automatiskt nu
  }

  # Säkerhet: Skydda mot oavsiktlig radering i produktion
  deletion_protection_enabled = false # Sätt till true i riktiga produktionsmiljöer
}

# Skicka ut tabellens namn och dess ARN (Amazon Resource Name) så Lambdan kan använda det
output "table_name" {
  value = aws_dynamodb_table.this.name
}

output "table_arn" {
  value = aws_dynamodb_table.this.arn
}