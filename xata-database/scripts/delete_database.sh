echo "Xata database branch to delete is $TARGET_BRANCH_NAME ($BRANCH_ID)"

if [ -n "$BRANCH_ID" ]; then
    echo "Checking to see if the database branch $TARGET_BRANCH_NAME ($BRANCH_ID) exists..."

    existing_branch_response=$( \
        curl -s -w "\n%{http_code}" \
            --request GET \
            --url https://api.staging.maki.cooking/organizations/$ORGANIZATION_ID/projects/$PROJECT_ID/branches/$BRANCH_ID \
            --header 'accept: application/json' \
            --header "authorization: Bearer $API_TOKEN" \
    )
    existing_branch_response_code=$(echo "$existing_branch_response" | tail -n1)
    existing_branch_response_body=$(echo "$existing_branch_response" | sed '$d')

    if [ "$existing_branch_response_code" -eq 200 ]; then
        echo "Database branch $TARGET_BRANCH_NAME exists in Xata, ID $BRANCH_ID."
    elif [ "$existing_branch_response_code" -eq 404 ]; then
        echo "Database branch $TARGET_BRANCH_NAME does not exist in Xata, nothing to delete."
        exit 0
    else
        echo "HTTP Error: $existing_branch_response_code"
        echo "$existing_branch_response_body"
        exit 1
    fi
fi

echo "Deleting the database branch..."

delete_branch_response=$( \
    curl -s -w "\n%{http_code}" \
        --request DELETE \
        --url https://api.staging.maki.cooking/organizations/$ORGANIZATION_ID/projects/$PROJECT_ID/branches/$BRANCH_ID \
        --header 'accept: application/json' \
        --header "authorization: Bearer $API_TOKEN" \
)
delete_branch_response_code=$(echo "$delete_branch_response" | tail -n1)
delete_branch_response_body=$(echo "$delete_branch_response" | sed '$d')

if [ "$delete_branch_response_code" -eq 204 ]; then
    echo "Successfully deleted database branch $TARGET_BRANCH_NAME."
else
    echo "Error deleting database branch $TARGET_BRANCH_NAME."
    echo "HTTP code: $delete_branch_response_code"
    echo "$delete_branch_response_body"
    exit 1
fi