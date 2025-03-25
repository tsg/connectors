echo "Xata designated database branch is $TARGET_BRANCH_NAME"

if [ -n "$BRANCH_ID" ]; then
    echo "Checking to see if the database branch $TARGET_BRANCH_NAME ($BRANCH_ID) already exists..."

    existing_branch_response=$( \
        curl -s -w "\n%{http_code}" \
                --request GET \
                --url https://api.staging.maki.cooking/organizations/$ORGANIZATION_ID/projects/$PROJECT_ID/branches/$BRANCH_ID \
                --header 'accept: application/json' \
                --header "authorization: Bearer $API_TOKEN" \
    )
    existing_branch_response_code=$(echo "$existing_branch_response" | tail -n1)
    existing_branch_response_body=$(echo "$existing_branch_response" | sed '$d')

    if [ "$existing_branch_response_code" -eq 404 ]; then
        echo "Database branch $TARGET_BRANCH_NAME does not exist in Xata."
    elif [ "$existing_branch_response_code" -eq 200 ]; then
        echo "Database branch $TARGET_BRANCH_NAME already exists in Xata, ID $BRANCH_ID."
        exit 0
    else
        echo "HTTP Error: $existing_branch_response_code"
        echo "$existing_branch_response_body"
        exit 1
    fi
fi

echo "Creating the database branch..."

create_branch_response=$( \
    curl -s -w "\n%{http_code}" \
        --request POST \
        --url https://api.staging.maki.cooking/organizations/$ORGANIZATION_ID/projects/$PROJECT_ID/branches \
        --header 'accept: application/json' \
        --header "authorization: Bearer $API_TOKEN" \
        --header 'content-type: application/json' \
        --data "{\"parentID\": \"$SOURCE_BRANCH_ID\", \"name\": \"$TARGET_BRANCH_NAME\"}" \
)

echo "create_branch_response: $create_branch_response"

create_branch_response_code=$(echo "$create_branch_response" | tail -n1)
create_branch_response_body=$(echo "$create_branch_response" | sed '$d')

if [ "$create_branch_response_code" -eq 201 ]; then
    echo "Successfully created database branch $TARGET_BRANCH_NAME."
    BRANCH_ID=$(echo "$create_branch_response_body" | jq -r '.id')
    echo "Branch ID: $BRANCH_ID"
else
    echo "Error creating database branch $TARGET_BRANCH_NAME."
    echo "HTTP code: $create_branch_response_code"
    echo "$create_branch_response_body"
    exit 1
fi

echo "Waiting for the connection string"

while true; do
    connection_string_response=$( \
        curl -s -w "\n%{http_code}" \
            --request GET \
            --url https://api.staging.maki.cooking/organizations/$ORGANIZATION_ID/projects/$PROJECT_ID/branches/$BRANCH_ID \
            --header 'accept: application/json' \
            --header "authorization: Bearer $API_TOKEN" \
    )
    connection_string_response_code=$(echo "$connection_string_response" | tail -n1)
    connection_string_response_body=$(echo "$connection_string_response" | sed '$d')

    if [ "$connection_string_response_code" -gt 299 ]; then
        echo "Error getting the connection string"
        echo "HTTP code: $connection_string_response_code"
        echo "$connection_string_response_body"
        exit 1
    fi
    CONNECTION_STRING=$(echo "$connection_string_response_body" | jq -r '.connectionString')

    if [ -n "$CONNECTION_STRING" ]; then
        echo "Connection string ready"
        break
    fi

    sleep 1
    echo -n "."
done

echo "Connection string: $CONNECTION_STRING"
