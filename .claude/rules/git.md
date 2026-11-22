# Commits, PRs, changelog

## Conventional Commits

`<type>(<scope>)?: <subject>`, in English.

- `feat` → "Added", MINOR bump (pre-1.0). `fix` → "Fixed", PATCH. `perf` / `refactor` → "Changed", PATCH.
- `docs`, `chore`, `ci`, `test`, `build` → no changelog entry, no bump.
- Areas are scopes, not types: `feat(cycom): count match arms`, `fix(shim): ...`, `feat(json)!: ...`.
- Breaking changes: `!` plus a `BREAKING CHANGE:` footer.
- No attribution trailers (`Co-Authored-By`, generated-by footers).

## Changelog and version

Do not edit `CHANGELOG.md` or `VERSION` by hand; they are generated at release time from commit messages.

## Hygiene

- One PR does one thing. A bug found outside the PR's scope becomes an issue, not an inline fix.
- A grammar or core update in `vendor/` is a commit of its own.
- Every fix adds a fixture that reproduces the bug.
