#!/usr/bin/env bash

source "$(dirname "$0")/github.sh"

beforeAll
testGetRepository
testCreateIssue
testGetIssues
afterAll
