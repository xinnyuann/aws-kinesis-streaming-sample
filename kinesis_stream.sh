#!/bin/bash

aws kinesis create-stream \
--stream-name poc \
--shard-count 1

aws kinesis wait stream-exists --stream-name poc

while true; do
    # Get current date and time in ISO 8601 format for systems without --iso-8601 support.
    TIMESTAMP=$(date "+%Y-%m-%dT%H:%M:%S%z")  # ISO 8601 format with timezone offset.

    # Generate a random number between 1 and 12 to add as hours.
    RANDOM_HOURS=$(($RANDOM % 12 + 1))

    # Create a second timestamp by adding random hours to the original timestamp.
    TIMESTAMP_DROPOFF=$(date -j -v "+${RANDOM_HOURS}H" -f "%Y-%m-%dT%H:%M:%S%z" "$TIMESTAMP" "+%Y-%m-%dT%H:%M:%S%z")

    # Generate a random five-digit ZIP code.
    ZIP_CODE=$(printf "%05d" $((RANDOM % 90000 + 10000)))

    # Generate float fare_amount
    FARE_AMOUNT=$(echo "scale=2; $RANDOM/327" | bc)

    # Generate trip_distance
    TRIP_DISTANCE=$(($RANDOM % 49 + 1))

    # Create a JSON object with proper double quotes and use $RANDOM for price and volume.
    DATA="{\"tpep_pickup_datetime\": \"$TIMESTAMP\", \"tpep_dropoff_datetime\": \"$TIMESTAMP_DROPOFF\", \"trip_distance\": $TRIP_DISTANCE, \"fare_amount\": $FARE_AMOUNT, \"pickup_zip\": \"$ZIP_CODE\",  \"dropoff_zip\": \"$ZIP_CODE\"}"

    # Encode the JSON data to base64 and use it with the AWS CLI.
    echo "$DATA" | base64 | aws kinesis put-record \
        --stream-name poc \
        --partition-key "1" \
        --data file:///dev/stdin

    # Sleep for 1 second.
    sleep 1
done


aws kinesis delete-stream --stream-name poc
aws kinesis wait stream-not-exists --stream-name poc
