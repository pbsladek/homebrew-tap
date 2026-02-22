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
