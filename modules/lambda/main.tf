variable "dynamodb_table_arn" {
  type        = string
  description = "ARN för DynamoDB-tabellen"
}

variable "dynamodb_table_name" {
  type        = string
  description = "Namnet på DynamoDB-tabellen"
}


# 1. Paketera Python-koden automatiskt till en ZIP-fil
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.root}/lambda_function.zip" # RÄTTELSE HÄR: path.root istället för path.path_root
}

# 2. Skapa en IAM-roll (Execution Role) som Lambdan antar när den körs
resource "aws_iam_role" "lambda_role" {
  name = "secure-api-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# 3. Koppla AWS standardpolicy för CloudWatch-loggning till rollen (Least Privilege)
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# 4. Skapa själva Lambda-funktionen
resource "aws_lambda_function" "this" {
  # Ändra till data-källans dynamiska sökväg
  filename         = data.archive_file.lambda_zip.output_path
  
  # Ändra till data-källans inbyggda base64-hash-funktion
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  function_name    = "secure-api-backend"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler" 
  runtime          = "python3.11"

  environment {
    variables = {
      ENV            = "Production"
      DYNAMODB_TABLE = var.dynamodb_table_name
    }
  }
}

# 5. Ge API Gateway uttrycklig tillåtelse att trigga denna Lambda-funktion
resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "apigateway.amazonaws.com"
}

# Skicka vidare Lambdans ARN till API Gateway så de kan kopplas ihop
output "lambda_arn" {
  value = aws_lambda_function.this.arn
}

output "lambda_invoke_arn" {
  value = aws_lambda_function.this.invoke_arn
}


# Skapa en specifik policy som ENDAST tillåter CRUD-operationer på vår unika tabell
resource "aws_iam_policy" "lambda_dynamodb" {
  name        = "secure-api-lambda-dynamodb-policy"
  description = "Tillåt Lambda att interagera med vår specifika DynamoDB-tabell"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query"
        ]
        Resource = var.dynamodb_table_arn # Hård begränsning till just denna tabell
      }
    ]
  })
}

# Koppla policyn till Lambdans IAM-roll
resource "aws_iam_role_policy_attachment" "lambda_dynamodb" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_dynamodb.arn
}


# Skapa en explicit logggrupp för vår Lambda-funktion för att styra livslängden på loggarna
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.this.function_name}"
  retention_in_days = 14 # Sparar loggar i 14 dagar (Enterprise Best Practice för kostnad/GDPR)
}