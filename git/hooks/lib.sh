# Sourced by every stub in this folder. Git runs these instead of a repo's own
# .git/hooks (that is what a global core.hooksPath does), so each stub:
#   1. runs the guard that belongs to this hook, if there is one (commit-msg only);
#   2. then hands over to the repo's own hook of the same name in .git/hooks, with the same
#      arguments and stdin, so lint-staged, simple-git-hooks and the like keep working.
# A repo that sets its own core.hooksPath (husky, lefthook, .githooks) overrides the global one:
# its hooks run and these stubs do not, so the guard cannot see those repos.

run_hook() {
    name="$1"; shift
    here="$(cd "$(dirname "$0")" && pwd)"

    if [ "$name" = "commit-msg" ]; then
        sh "$here/check-commit-msg.sh" "$1" || exit 1
    fi

    common="$(git rev-parse --git-common-dir 2>/dev/null)" || exit 0
    repo_hook="$common/hooks/$name"
    if [ -f "$repo_hook" ] && [ -x "$repo_hook" ]; then
        exec "$repo_hook" "$@"
    fi
    exit 0
}
