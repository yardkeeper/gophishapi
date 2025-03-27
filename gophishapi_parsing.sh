#!/bin/bash
while true 

do

GOPHISH_URL="https://go.server" 
API_KEY="d"  

go_latest_sum="go_latest_sum.json"
go_lusers_sum="go_lusers_sum.json"
go_timeline="timeline.json"
go_clicks="clicks.json"

response=$(curl  -s --location --insecure ''$GOPHISH_URL'/api/campaigns/' --header 'Authorization: Bearer '$API_KEY'')

ids=($(echo "$response" | jq -r '.[].id'))

highest=0

for id in "${ids[@]}"; do
    if (( id > highest )); then
        highest=$id
    fi
done

#debuging echo "The highest ID is: $highest"

summary_response=$(curl -s --location --insecure ''$GOPHISH_URL'/api/campaigns/'$highest'/summary' --header 'Authorization: Bearer '$API_KEY'')
echo "$summary_response"  | jq '.stats | {sent, opened, clicked, submitted_data, email_reported, error}' > $go_latest_sum
parsed_response=$(echo "$response" | jq '.[0].results[] | {id, first_name, email, status}' )
fixed_json=$(echo "$parsed_response" |  jq -s .)
echo "$fixed_json">$go_lusers_sum









campaigns=$(curl  -s --location --insecure ''$GOPHISH_URL'/api/campaigns/' --header 'Authorization: Bearer '$API_KEY'')



result_json="["


for campaign_id in $(echo "$campaigns" | jq -r '.[].id'); do

  campaign_summary=$(curl  -s --location --insecure ''$GOPHISH_URL'/api/campaigns/'$campaign_id'/summary' --header 'Authorization: Bearer '$API_KEY'')
  

  launch_date=$(echo "$campaign_summary" | jq -r '.launch_date')
  clicked_count=$(echo "$campaign_summary" | jq -r '.stats.clicked // 0') 
  
  campaign_json=$(jq -n \
    --arg id "$campaign_id" \
    --arg launch_date "$launch_date" \
    --argjson clicked_count "$clicked_count" \
    '{time: $launch_date, id: $id, clicked_count: $clicked_count}')


  result_json="$result_json$campaign_json,"

done


result_json="${result_json%,}]"


echo "$result_json" > $go_timeline




get_campaigns() {
  curl  -s --location --insecure ''$GOPHISH_URL'/api/campaigns/' --header 'Authorization: Bearer '$API_KEY''
}

get_campaign_results() {
  local campaign_id=$1
 curl  -s --location --insecure ''$GOPHISH_URL'/api/campaigns/'$campaign_id'/results' --header 'Authorization: Bearer '$API_KEY''
}

parse_results_and_count_clicks() {
  local campaign_results=$1
  for email in $(echo "$campaign_results" | jq -r '.results[] | select(.status=="Clicked Link") | .email'); do
    email_clicks["$email"]=$((email_clicks["$email"] + 1))
  done
}

declare -A email_clicks


campaigns=$(get_campaigns)


for campaign_id in $(echo "$campaigns" | jq -r '.[].id'); do
  campaign_results=$(get_campaign_results $campaign_id)
  parse_results_and_count_clicks "$campaign_results"
done




json_output="{"


for email in "${!email_clicks[@]}"; do
  json_output+="\"$email\": ${email_clicks[$email]},"
done


json_output=$(echo "$json_output" | sed 's/,$//')  
json_output+="}"


echo "$json_output" > $go_clicks






sleep 3m

done
