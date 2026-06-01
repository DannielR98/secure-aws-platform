# 1. Skapa själva användardatabasen (User Pool)
resource "aws_cognito_user_pool" "this" {
  name = "secure-api-user-pool"

  # Enterprise Security: Kräv starka lösenord
  password_policy {
    minimum_length    = 12
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  # Gör att användare loggar in med sin e-postadress
  username_attributes = ["email"]
  
  # Auto-verifiera e-post (krävs för produktion, AWS skickar verifieringskod)
  auto_verified_attributes = ["email"]
}

# 2. Skapa en App Client som vår frontend/klient använder för att kommunicera med Cognito
resource "aws_cognito_user_pool_client" "this" {
  name         = "secure-api-app-client"
  user_pool_id = aws_cognito_user_pool.this.id

  # Tillåt traditionell inloggning med användarnamn/lösenord via API/CLI
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  # Säkerhet: Generera INTE en klienthemlighet (Client Secret) eftersom 
  # publika klienter (SPAs som React/mobilappar) inte kan dölja den säkert.
  generate_secret = false
}

# Skicka vidare relevanta ID:n till resten av Terraform-projektet
output "user_pool_id" {
  value = aws_cognito_user_pool.this.id
}

output "user_pool_arn" {
  value = aws_cognito_user_pool.this.arn
}

output "client_id" {
  value = aws_cognito_user_pool_client.this.id
}