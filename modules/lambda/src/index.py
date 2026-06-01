import json
import os

def handler(event, context):
    # Hämta tabellnamnet från miljövariablerna vi skickade via Terraform
    table_name = os.environ.get('DYNAMODB_TABLE', 'Okänd-tabell')
    
    # Extrahera användarens e-post från Cognito JWT-claims
    request_context = event.get('requestContext', {})
    authorizer = request_context.get('authorizer', {})
    claims = authorizer.get('claims', {})
    user_email = claims.get('email', 'Anonym Användare')
    
    # Simulera en strukturerad enterprise-logg (JSON-format är bäst för logganalys)
    print(json.dumps({
        "level": "INFO",
        "message": f"Användare {user_email} anropar databasen",
        "target_table": table_name,
        "action": "Scan/Query"
    }))
    
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'message': f"Välkommen {user_email}! Ditt API pratar säkert med DynamoDB-tabellen: '{table_name}'.",
            'status': 'Connected'
        })
    }