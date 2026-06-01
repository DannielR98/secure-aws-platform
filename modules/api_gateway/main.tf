variable "lambda_invoke_arn" {
  type        = string
  description = "Invoke ARN för backend-lambdan"
}

# Tar emot data från rot-modulen (vi behöver veta Cognitos ARN)
variable "cognito_user_pool_arn" {
  type        = string
  description = "ARN för Cognito User Pool för att kunna validera tokens"
}

# 1. Skapa REST API-komponenten
resource "aws_api_gateway_rest_api" "this" {
  name        = "secure-api-gateway"
  description = "Säker API-plattform skyddad av Cognito"
  
  # Enterprise Best Practice: Vi tvingar TLS 1.2+ genom att använda regional endpoint
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# 2. Skapa dörrvakten (Cognito Authorizer)
resource "aws_api_gateway_authorizer" "cognito" {
  name          = "cognito-authorizer"
  rest_api_id   = aws_api_gateway_rest_api.this.id
  type          = "COGNITO_USER_POOLS"
  provider_arns = [var.cognito_user_pool_arn]
  identity_source = "method.request.header.Authorization" # Var token ska skickas
}

# 3. Skapa en API-resurs (en URL-path: /notes)
resource "aws_api_gateway_resource" "notes" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "notes"
}

# 4. Skapa en HTTP-metod (GET) på vår /notes-path
resource "aws_api_gateway_method" "notes_get" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.notes.id
  http_method   = "GET"
  
  # Här aktiverar vi säkerheten!
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

# 5. En temporär "Mock"-integration (så vi kan testa API:et utan en backend i detta steg)
resource "aws_api_gateway_integration" "lambda" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.notes.id
  http_method             = aws_api_gateway_method.notes_get.http_method
  integration_http_method = "POST" # AWS kräver att API Gateway alltid pratar med Lambda via POST internt
  type                    = "AWS_PROXY" # Skickar med hela HTTP-kontexten (headers, tokens, IP osv)
  uri                     = var.lambda_invoke_arn
}

# Svara med 200 OK från vår mock
resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.notes.id
  http_method = aws_api_gateway_method.notes_get.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "mock_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.notes.id
  http_method = aws_api_gateway_method.notes_get.http_method
  status_code = aws_api_gateway_method_response.response_200.status_code

  # RÄTTELSE HÄR: Ändrat från request_templates till response_templates
  response_templates = {
    "application/json" = "{\"message\": \"Hello from behind a secure gateway!\"}"
  }
}

# 6. Driftsätt API:et (Deployment + Stage)
resource "aws_api_gateway_deployment" "this" {
  depends_on  = [aws_api_gateway_integration.lambda] # Ändrad till lambda
  rest_api_id = aws_api_gateway_rest_api.this.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.this.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
  stage_name    = "prod"
}

# Skicka ut API-urlen så vi kan anropa den sen
output "api_url" {
  value = "${aws_api_gateway_stage.prod.invoke_url}/${aws_api_gateway_resource.notes.path_part}"
}