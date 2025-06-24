#Define the API Endpoint
API_URL="http://localhost:5001/api-server/reporting/send-bimonthly-excel-opd-report/"

#Call the API using curl
curl -X GET $API_URL