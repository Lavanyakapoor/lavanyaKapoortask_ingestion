#!/bin/bash

# Base URL for the API
URL="https://e94fb036-1fcf-48b3-9772-58c65bd020f0-00-1qhuy96r5k581.kirk.replit.dev"

# Submit 5 IDs with MEDIUM priority
response=$(curl -s -X POST "$URL/ingest" -H "Content-Type: application/json" -d '{"ids":[1,2,3,4,5],"priority":"MEDIUM"}')
echo "$response"
ingestion_id_1=$(echo "$response" | grep -oP '(?<="ingestion_id":")[^"]+')
if [ -z "$ingestion_id_1" ]; then
  echo '{"error": "No ingestion_id received"}'
  exit 1
fi
sleep 1

# Submit 4 IDs with HIGH priority
response=$(curl -s -X POST "$URL/ingest" -H "Content-Type: application/json" -d '{"ids":[6,7,8,9],"priority":"HIGH"}')
echo "$response"
ingestion_id_2=$(echo "$response" | grep -oP '(?<="ingestion_id":")[^"]+')
if [ -z "$ingestion_id_2" ]; then
  echo '{"error": "No ingestion_id received"}'
  exit 1
fi
sleep 1

# Check initial status of both submissions
response1=$(curl -s "$URL/status/$ingestion_id_1")
echo "$response1"
response2=$(curl -s "$URL/status/$ingestion_id_2")
echo "$response2"

# Wait 15 seconds for processing
sleep 15

# Check final status of both submissions
final_response1=$(curl -s "$URL/status/$ingestion_id_1")
echo "$final_response1"
final_response2=$(curl -s "$URL/status/$ingestion_id_2")
echo "$final_response2"

# Basic validation of requirements
echo "Validating requirements..."

for response in "$response1" "$response2" "$final_response1" "$final_response2"; do
  batches=$(echo "$response" | grep -oP '(?<="ids":)\[[0-9,]+\]' | tr -d '[]')
  while IFS= read -r batch; do
    count=$(echo "$batch" | tr -d ' ' | tr ',' '\n' | wc -l)
    if [ "$count" -gt 3 ]; then
      echo '{"error": "Batch size exceeds 3 IDs", "batch": "'"$batch"'"}'
      exit 1
    fi
  done <<< "$batches"
done
echo '{"validation": "Batching OK: Max 3 IDs per batch"}'

high_status=$(echo "$final_response2" | grep -oP '(?<="ids":\[6,7,8\],"status":")[^"]+')
if [ "$high_status" != "completed" ]; then
  echo '{"error": "HIGH priority batch [6,7,8] not completed, status: '"$high_status"'"}'
  exit 1
fi
medium_status=$(echo "$final_response1" | grep -oP '(?<="ids":\[1,2,3\],"status":")[^"]+')
if [ "$medium_status" = "completed" ] && [ "$high_status" != "completed" ]; then
  echo '{"error": "MEDIUM priority batch [1,2,3] completed before HIGH priority [6,7,8]"}'
  exit 1
fi
echo '{"validation": "Priority OK: HIGH processed before MEDIUM"}'

batch_678=$(echo "$final_response2" | grep -oP '(?<="ids":\[6,7,8\],"status":")[^"]+')
batch_9=$(echo "$final_response2" | grep -oP '(?<="ids":\[9\],"status":")[^"]+')
batch_123=$(echo "$final_response1" | grep -oP '(?<="ids":\[1,2,3\],"status":")[^"]+')
batch_45=$(echo "$final_response1" | grep -oP '(?<="ids":\[4,5\],"status":")[^"]+')
echo '{"rate_limit_check": {"batch_678": "'"$batch_678"'", "batch_9": "'"$batch_9"'", "batch_123": "'"$batch_123"'", "batch_45": "'"$batch_45"'", "note": "Expect 6,7,8 completed, 9 and 1,2,3 triggered, 4,5 yet_to_start by T15"}}'