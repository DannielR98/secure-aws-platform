## Lättfattat för  min egna del
Vi skickar användarnamn+lösenord till cognito aws, den vi skapade med:

```bash
aws cognito-idp admin-create-user

--user-pool-id "[USER_POOL_ID]"

--username "daniel.racho98@gmail.com"

--user-attributes Name=email,Value=daniel.racho98@gmail.com Name=email_verified,Value=true

--message-action "SUPPRESS"
```



```bash
aws cognito-idp admin-set-user-password

--user-pool-id "[USER_POOL_ID]"

--username "daniel.racho98@gmail.com"

--password "SecurePassword123!"

--permanent
```



vi loggar in med:

```bash
aws cognito-idp initiate-auth

--auth-flow USER_PASSWORD_AUTH

--client-id "[CLIENT_ID]"

--auth-parameters USERNAME=daniel.racho98@gmail.com,PASSWORD=SecurePassword123!
```

och då får vi vårt id token genom att cognito hashar lösenordet (+ salt) och kollar om den finns med där. Den skapar ett token som den signerar med en privat nyckel


Vi använder vårt id token med vårt curl kommando och om den är äkta släpper cognito in oss. AWS API gateway kollar sedan token, använder cognitos publika nyckel och om det stämmer (blir matematiskt korrekt) så är token rät. Det är en av CIa triaden, integriteten av token kollas 


Då kommer vi till lambdafunktionen, lambdafunktionen python börjar köras. Lambda har en iam roll (som vi gav den via terraform) så den behöver inget lösenord för att öppna databasen 


Resten av delen är skriven mer i detalj med ai, skrev bara denna del för att jag själv ska förstå vad som händer


# Säkrad AWS API-Plattform (Infrastructure as Code)

Detta projekt demonstrerar en modern, serverlös backend-arkitektur på AWS, helt uppbyggd och hanterad som kod via **Terraform**. Arkitekturen följer en så kallad **Zero-Trust-modell**, vilket innebär att ingen okänd trafik tillåts krascha applikationen eller nå databasen utan att först ha blivit strikt identifierad och godkänd vid dörren.

---

<img width="1472" height="1240" alt="bild" src="https://github.com/user-attachments/assets/f21e5060-d973-4fb3-9538-d6efa9cdc8e2" />


## Terraform?

**Terraform** är ett verktyg för *Infrastructure as Code (IaC)*. Istället för att klicka runt i AWS-konsolen manuellt för att skapa databaser, servrar och användare, skriver vi vår infrastruktur i form av konfigurationsfiler. 

### Varför är detta viktigt?
* **Återanvändbarhet:** Lätt att bygga upp den igen
* **Historik:** kan versionshantera

---

##  Arkitektur & Projektstruktur

Projektet är uppdelat i fyra fristående moduler

```text
secure-aws-platform/
├── main.tf                 # Projektets hjärta (kopplar ihop alla moduler)
├── variables.tf            # Globala inställningar (t.ex. vilken AWS-region vi använder)
├── outputs.tf              # Visar slutresultatet (vår färdiga URL och ID-nummer)
└── modules/
    ├── cognito/            # Modul 1: Hanterar användare och säkerhetslösenord
    ├── api_gateway/        # Modul 2: Dörrvakten som tar emot webb-anropen
    ├── lambda/             # Modul 3: Serverlös Python-kod (vår backend-logik)
    └── database/           # Modul 4: Vår NoSQL-databas (DynamoDB)
```


## 1. Rotmappens main.tf (Huvudkontoret)

Denna fil fungerar som projektets dirigent. Den talar om för Terraform att vi vill kommunicera med AWS, och skickar data mellan de olika modulerna. Det är här vi ser till att den databas som skapas i database-modulen skickas som en miljövariabel till vår kod i lambda-modulen.



## 2. modules/database/main.tf (Lagringen)

Skapar en Amazon DynamoDB-tabell. Detta är en supersnabb, serverlös NoSQL-databas. Den är inställd på "Pay-per-request", vilket gör att den är helt gratis när ingen använder den, men kan skala upp till miljontals användare på ett ögonblick. Den är även krypterad i vila för maximal datasekretess.



## 3. modules/cognito/main.tf (Identitetshanteraren)

Skapar en AWS Cognito User Pool. Detta är din applikations användardatabas. Den hanterar registreringar, inloggningar och krypterade lösenord. Här har vi ställt in en strikt lösenordspolicy (krav på tecken, siffror och stor bokstav) samt skapat en app-klient så att en frontend (eller terminalen) tillåts prata med inloggningssystemet.



## 4. modules/lambda/main.tf (Hjärnan/Backend)

Skapar en AWS Lambda-funktion som kör Python 3.11. Lambda är helt serverlöst – det finns ingen server att underhålla eller patcha. När ett anrop kommer in, startar AWS koden, kör den i några millisekunder, och stänger sedan ner den.

    Säkerhetsfokus: Filen skapar en IAM-roll (ett digitalt pass) som ger Lambdan exakt de rättigheter som krävs för att prata med DynamoDB-databasen. Inga databaslösenord eller nycklar sparas någonsin i koden.



## 5. modules/api_gateway/main.tf (Dörrvakten/Brandväggen)

Skapar en AWS API Gateway (REST API). Detta är det publika ansiktet utåt och den URL som omvärlden anropar.

    Säkerhetsfokus: Vi har kopplat ihop API Gateway med Cognito. Om någon försöker anropa vår URL utan en giltig, kryptografisk nyckel (JWT-token) blir de omedelbart blockerade i dörren (401 Unauthorized). Trafiken når aldrig vår backend-kod om den inte är verifierad.




## 1. Driftsättning av infrastrukturen

Först startar vi upp Terraform och rullar ut alla resurser till AWS-molnet.
Bash

# Initiera projektet och ladda ner AWS-kopplingar
terraform init

# Kontrollera vad som kommer att byggas (en förhandsgranskning)
terraform plan

# Driftsätt allt live till AWS
terraform apply



# 2. Hantering av testanvändare i AWS Cognito

Eftersom vi har en säker dörrvakt måste vi skapa en riktig användare i molnet för att kunna logga in. (Byt ut [USER_POOL_ID] och [CLIENT_ID] mot dina unika outputs från Terraform).
Bash

# A. Skapa användaren daniel.racho98@gmail.com i din User Pool
aws cognito-idp admin-create-user \
    --user-pool-id "[USER_POOL_ID]" \
    --username "daniel.racho98@gmail.com" \
    --user-attributes Name=email,Value=daniel.racho98@gmail.com Name=email_verified,Value=true \
    --message-action "SUPPRESS"

# B. Tvinga kontot att bli permanent godkänt (så vi slipper FORCE_CHANGE_PASSWORD)
aws cognito-idp admin-set-user-password \
    --user-pool-id "[USER_POOL_ID]" \
    --username "daniel.racho98@gmail.com" \
    --password "SecurePassword123!" \
    --permanent

# C. Logga in via terminalen för att hämta ut din kryptografiska ID-token
aws cognito-idp initiate-auth \
    --auth-flow USER_PASSWORD_AUTH \
    --client-id "[CLIENT_ID]" \
    --auth-parameters USERNAME=daniel.racho98@gmail.com,PASSWORD=SecurePassword123!




# 3. Verifiering och test av API:et

Nu simulerar vi ett säkert anrop från en frontend genom att skicka med vår token i Authorization-headern med hjälp av verktyget curl.
Bash

curl -H "Authorization: [Klistra_in_din_långa_IdToken_här]" [DIN_API_ENDPOINT_URL]




# Förväntat svar (Kvitto på att allt fungerar):
```json
{
  "message": "Välkommen daniel.racho98@gmail.com! Ditt API pratar säkert med DynamoDB-tabellen: 'secure-api-notes'.", 
  "status": "Connected"
}
```




# Hur man uppdaterar backend-koden i framtiden

Om du ändrar i din Python-kod (index.py), beräknar Terraform automatiskt en ny fil-hash tack vare source_code_hash = filebase64sha256(...) i din kod. Det enda du behöver göra för att skicka upp den nya koden till AWS är:


```bash
terraform apply
``` 




# AWS Cloud Configuration & Verification Guide

Denna guide dokumenterar de exakta stegen, kommandona och flödena som kördes i AWS-molnet och via terminalen för att konfigurera, säkra och verifiera den serverlösa plattformen.

---

##  Vad vi gjorde i AWS (Steg-för-steg)

Genom att kombinera **Terraform** (som skapade resurserna) och **AWS CLI / cURL** (som hanterade dataflödet) utförde vi följande operationer i AWS-molnet:

### Steg 1: Driftsättning av resurserna
Vi körde `terraform apply` vilket instruerade AWS att provisionera:
1. En **Cognito User Pool** (med strikt lösenordspolicy).
2. En **API Gateway** (med en `/notes`-rutt inställd på TLS 1.2+).
3. En **Lambda-funktion** (med tillhörande IAM-roll för DynamoDB-åtkomst).
4. En **DynamoDB-tabell** (krypterad i vila).

### Steg 2: Skapande av identitet (Användarhantering)
Eftersom vi stängde dörren till API:et behövde vi en testanvändare. Vi använde AWS CLI för att skapa en profil direkt i molnet:
```bash
aws cognito-idp admin-create-user \
    --user-pool-id "eu-north-1_XyGr5i3pt" \
    --username "daniel.racho98@gmail.com" \
    --user-attributes Name=email,Value=daniel.racho98@gmail.com Name=email_verified,Value=true \
    --message-action "SUPPRESS"
```




Steg 3: Permanent aktivering av lösenord

För att göra kontot redo för inloggning skickade vi ett kommando som tvingade kontot till statusen CONFIRMED:
```bash
aws cognito-idp admin-set-user-password \
    --user-pool-id "eu-north-1_XyGr5i3pt" \
    --username "daniel.racho98@gmail.com" \
    --password "SecurePassword123!" \
    --permanent
```
Steg 4: Autentisering (Hämta kryptografisk nyckel)

Vi simulerade en inloggning från en applikation för att bevisa att Cognito känner igen användaren:
Bash
```bash
aws cognito-idp initiate-auth \
    --auth-flow USER_PASSWORD_AUTH \
    --client-id "3av44vq68auvs62c7d8vqmkhhp" \
    --auth-parameters USERNAME=daniel.racho98@gmail.com,PASSWORD=SecurePassword123!
```
    Vad hände i AWS? Cognito validerade lösenordet, skapade en digital signatur och skickade tillbaka en krypterad textsträng: en IdToken (JWT).

Steg 5: API-anrop genom brandväggen

Vi skickade vår IdToken i Authorization-headern till vår unika API-länk:
Bash

curl -H "Authorization: eyJraWQiOiIvWXRY...[din token]...w" [https://6xhytnvqc9.execute-api.eu-north-1.amazonaws.com/prod/notes](https://6xhytnvqc9.execute-api.eu-north-1.amazonaws.com/prod/notes)

    Vad hände i AWS? 
    1. API Gateway tog emot anropet, läste av token, och frågade Cognito: "Är den här signerad av dig och giltig just nu?".

    2. När Cognito svarade Ja, rensade API Gateway bort sin gamla "Mock-integration", öppnade dörren och skickade requesten vidare till Lambda.

    3. Lambda körde Python-koden, läste av din e-postadress inifrån den godkända token-strängen och returnerade det dynamiska svaret: Ditt API pratar säkert med DynamoDB-tabellen: 'secure-api-notes'.



## 🧠 Djupdykning: Hur fungerar det egentligen?

Här är en enkel förklaring av de tre pelarna i din arkitektur, skrivet för att du enkelt ska förstå hur de hänger ihop.

### 1. Vad är AWS Cognito och hur skapas en Token?
**AWS Cognito** är som ett externt, nyckelfärdigt inloggningssystem. Istället för att du ska bygga kryptering av lösenord, glömt-lösenord-mail och databastabeller för användare själv, sköter Cognito allt.

**Hur skapas en token?**
När du skickar ditt användarnamn och lösenord till Cognito sker följande:
1. Cognito kollar om lösenordet matchar det hashade lösenordet i databasen.
2. Om det matchar, skapar Cognito en **JWT (JSON Web Token)**. 
3. Denna token är en textsträng uppdelad i tre delar (Header, Payload, Signature). I "Payload" paketerar Cognito information om dig, t.ex: `"email": "daniel.racho98@gmail.com"`.
4. Cognito **signerar** sedan denna sträng med en privat, matematisk nyckel som bara AWS känner till. Denna signatur gör det omöjligt för en hackare att ändra i texten (t.ex. ändra e-postadressen), för då slutar signaturen att matcha.

### 2. Hur gjorde vi så att vi *måste* ha en token? (Dörrvakten)
Detta är magin i din `api_gateway/main.tf`. Vi gjorde två saker i koden:
* Vi skapade en **Authorizer** (en dörrvakt) och sa till den att hålla utkik efter en header som heter `Authorization`. Vi pekade också ut din specifika Cognito User Pool som dörrvaktens facit.
* På själva `GET`-metoden för `/notes` ändrade vi `authorization = "NONE"` till `authorization = "COGNITO_USER_POOLS"`. 

Detta gör att AWS API Gateway automatiskt kastar bort alla anrop som saknar en token, eller som har en manipulerad token, med svaret `401 Unauthorized`. Din Lambda-funktion (din backend) behöver inte ens bry sig om att kolla om användaren är inloggad – API Gateway har redan garanterat det innan koden ens startar!

### 3. Vad är AWS Lambda?
**AWS Lambda** är en serverlös beräkningstjänst. Traditionellt sett behöver man ha en server (t.ex. en Linux-dator i molnet) igång dygnet runt som väntar på API-anrop. Det kostar pengar även när ingen använder appen.

Med Lambda laddar du bara upp din Python-kod. Koden ligger helt "vakenlös" och kostar $0.00. Men i samma millisekund som API Gateway släpper igenom ett godkänt anrop, skapar AWS en blixtsnabb mikro-container, kör din funktion `handler(event, context)`, skickar tillbaka svaret, och raderar sedan containern. Det är det ultimata sättet att hålla nere kostnader och maximera säkerheten.

---




