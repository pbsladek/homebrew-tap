# pbsladek/homebrew-tap

Homebrew tap monorepo for publishing multiple CLI tools under a single tap.

## Usage

```bash
brew tap pbsladek/tap
brew install ai-mr-comment
```

Or install in one command:

```bash
brew install pbsladek/tap/ai-mr-comment
```

## Available Formulae

- `ai-mr-comment` - AI-generated MR/PR review comments from git diffs.

## Tap Structure

```text
.
├── Formula/
│   ├── ai-mr-comment.rb
│   └── <future-formula>.rb
├── LICENSE
└── README.md
```

Each tool should have a dedicated file in `Formula/` named `<formula>.rb`.

## CI Validation

This tap includes GitHub Actions workflows for:

- push/PR checks on this repo: Ruby style/lint, audit, and build-from-source install
- upstream release validation: triggered from another repo via `repository_dispatch`

Workflow logic is implemented in repo scripts:

- `.github/scripts/tap-ci.sh`
- `.github/scripts/upstream-release-validation.sh`
- `.github/scripts/ruby-lint.sh`
- `.github/scripts/ruby-fmt.sh`

The upstream release validation script currently allows dispatch validation only for `ai-mr-comment` and its GitHub source tarball URL pattern.

Ruby checks:

- Lint: `.github/scripts/ruby-lint.sh`
- Format (write): `.github/scripts/ruby-fmt.sh write`
- Format (check only): `.github/scripts/ruby-fmt.sh check`

Unified local checks:

- `make lint` for Bash + Ruby lint and format checks
- `make fmt` to apply Bash + Ruby formatting

### Trigger release validation from another repo

From your release workflow in `pbsladek/ai-mr-comment`, send a dispatch event:

```yaml
- name: Validate Homebrew tap release payload
  env:
    GH_TOKEN: ${{ secrets.HOMEBREW_TAP_DISPATCH_TOKEN }}
  run: |
    gh api repos/pbsladek/homebrew-tap/dispatches \
      -f event_type=upstream_release \
      -f client_payload[formula]=ai-mr-comment \
      -f client_payload[version]=${{ github.ref_name }} \
      -f client_payload[url]=https://github.com/pbsladek/ai-mr-comment/archive/refs/tags/${{ github.ref_name }}.tar.gz \
      -f client_payload[sha256]=${{ needs.build.outputs.source_sha256 }}
```

`HOMEBREW_TAP_DISPATCH_TOKEN` should be a fine-grained PAT with access to trigger Actions in this repo.

## Add Another Project Later

1. Create `Formula/<name>.rb` with a `class <Name> < Formula`.
2. Point `url` at a released source tarball (or artifact).
3. Set `sha256` for that release.
4. Implement `install` and `test do`.
5. Commit and push to `main`.

Once pushed, users install with:

```bash
brew install pbsladek/tap/<name>
```
