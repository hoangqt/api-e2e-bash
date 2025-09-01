#!/usr/bin/env bash

fancy_echo() {
	local message="$1"
	echo "===================="
	echo "$message"
	echo "===================="
}

assert_equal() {
	local actual="$1"
	local expected="$2"
	local message="$3"

	if [[ "$actual" != "$expected" ]]; then
		echo "ℹ Actual: $actual"
		echo "ℹ Expected: $expected"
		echo "❌ Assertion failed: $message"
	else
		echo "✅ Passed: $message"
	fi
}

getToken() {
	local -r env_file="$(dirname "$0")/env.sh"

	if [[ -f "$env_file" ]]; then
		token_marker=$(grep '^GITHUBPAT=' "$env_file" 2>/dev/null)

		if [[ -n "$token_marker" ]]; then
			echo "$token_marker" | sed 's/^GITHUBPAT="\(.*\)"$/\1/'
		fi
	fi
}
