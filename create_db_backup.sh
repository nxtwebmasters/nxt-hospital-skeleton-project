#Define the API Endpoint
API_URL="http://localhost:5001/api-server/db-backup/backup"

#Call the API using curl
curl -X POST $API_URL