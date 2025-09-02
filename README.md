![Random picture from my walk](sangimi.png)

*All great and precious things are lonely. - John Steinbeck, East of Eden*

## Summary

A simple project, based on `make`, for testing a subset of the GitHub API
using REST requests. It's implemented in Bash with `curl` and `jq`.

### GitHub API endpoints

- **Repositories**: `/repos/{owner}/{repo}`
- **Issues**: `/repos/{owner}/{repo}/issues`

### Local setup

- Create a [GitHub personal access token](https://github.com/settings/tokens)
- Add an entry `GITHUBPAT`="<your-github-pat>" to `tests/env.sh` or `export GITHUB_PAT=<your-github-pat>`
- Run `make test` to execute the tests

### Troubleshooting

Use `curl` and `jq` to do all your debugging. If you prefer UI, either one of these
should be fine - `postman, hoppscotch, insomnia`.
