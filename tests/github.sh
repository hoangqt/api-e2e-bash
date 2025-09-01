#!/usr/bin/env bash

source "$(dirname "$0")/env.sh"
source "$(dirname "$0")/utils.sh"

[[ "$DEBUG" == "true" ]] && set -x

TOKEN=""
HEADER=""
ISSUE_NUMBER=""

trap cleanup EXIT

beforeAll() {
	# Get GitHub PAT from env.sh, otherwise, use GITHUB_PAT from
	# the environment variable
	local -r pat=$(getToken)
	if [[ -n "$pat" ]]; then
		TOKEN="$pat"
	else
		TOKEN="$GITHUB_PAT"
	fi
	HEADER="Authorization: Bearer $TOKEN"
}

testGetRepository() {
	fancy_echo 'testGetRepository'

	local -r endpoint="$GITHUB_API_URL/repos/$OWNER/$REPO"

	response=$(curl -k -H "$HEADER" -X GET "$endpoint" -w "%{http_code}" -s)

	local -r http_code="${response: -3}"
	local -r json_response="${response%???}"
	local -r repo_name=$(echo "$json_response" | jq -r '.name')

	assert_equal "$http_code" "200" "HTTP status code should be 200"
	assert_equal "$repo_name" "$REPO" "Repository name should be '$REPO'"
}

testCreateIssue() {
	fancy_echo 'testCreateIssue'

	local -r endpoint="$GITHUB_API_URL/repos/$OWNER/$REPO/issues"
	local -r issue_payload='{"title": "Found a bug", "body": "This is a test issue created by curl", "assignees": ["hoangqt"], "labels": ["bug"]}'

	response=$(curl -k -H "$HEADER" -X POST "$endpoint" -d "$issue_payload" -w "%{http_code}" -s)

	local -r http_code="${response: -3}"
	local -r json_response="${response%???}"

	local -r title=$(echo "$json_response" | jq -r '.title')
	local -r body=$(echo "$json_response" | jq -r '.body')
	local -r state=$(echo "$json_response" | jq -r '.state')

	assert_equal "$http_code" "201" "HTTP status code should be '201'"
	assert_equal "$title" "Found a bug" "Title should be 'Found a bug'"
	assert_equal "$body" "This is a test issue created by curl" "Issue body matched"
	assert_equal "$state" "open" "Issue state should be 'open'"
}

testGetIssues() {
	fancy_echo 'testGetIssues'

	local -r endpoint="$GITHUB_API_URL/repos/$OWNER/$REPO/issues"

	response=$(curl -k -H "$HEADER" -X GET "$endpoint" -w "%{http_code}" -s)

	local -r http_code="${response: -3}"
	local -r json_response="${response%???}"

	assert_equal "$http_code" "200" "HTTP status code should be 200"

	readarray -t issues_list < <(echo "$json_response" | jq -r '.[].number')
	readarray -t titles_list < <(echo "$json_response" | jq -r '.[].title')

	if [[ ${#issues_list[@]} -gt 0 ]]; then
		for i in "${!issues_list[@]}"; do
			if [[ "${titles_list[i]}" == "Found a bug" ]]; then
				ISSUE_NUMBER="${issues_list[i]}"
				echo "Found issue number: $ISSUE_NUMBER"
			fi
		done
	fi
}

cleanup() {
	rm -f /tmp/headers.txt
}

afterAll() {
	fancy_echo 'Running tear down'

	local endpoint
	endpoint="$GITHUB_API_URL/repos/$OWNER/$REPO/issues"

	# GitHub default of 30 issues per page
	local url
	local page
	url="$endpoint?per_page=30"
	page=1

	local body
	local link_header

	while [[ -n "$url" ]]; do
		# Dump the header into a file
		response=$(curl -D /tmp/headers.txt -H "$HEADER" "$url" -s)

		# Get a list of issues per page
		readarray -t issues_list < <(echo "$response" | jq -r '.[].number')

		if [[ ${#issues_list[@]} -eq 0 ]]; then
			return
		fi

		body='{"state": "closed", "state_reason": "not_planned"}'

		# For each issue, mark state as closed and reason not planned
		for i in "${!issues_list[@]}"; do
			response=$(curl -k -H "$HEADER" -X PATCH "$endpoint/${issues_list[i]}" -d "$body" -w "%{http_code}" -s)
			http_code="${response: -3}"

			assert_equal "$http_code" "200" "Marking issue ${issues_list[i]} as not planned"
		done

		# Get the link from the header
		link_header=$(grep -i "^link:" /tmp/headers.txt 2>/dev/null | cut -d' ' -f2-)

		# Parse the next page URL from the link
		if [[ -n "$link_header" && $link_header =~ \<([^>]+)\>\;\ rel=\"next\" ]]; then
			url="${BASH_REMATCH[1]}"
		else
			url="" # No more pages
		fi
		((page++))
	done
}
