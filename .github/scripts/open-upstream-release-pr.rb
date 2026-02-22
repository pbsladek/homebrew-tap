#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "open3"

def fail!(message)
  warn message
  exit 1
end

def run_cmd!(*cmd)
  stdout, stderr, status = Open3.capture3(*cmd)
  unless status.success?
    if stderr.include?("GitHub Actions is not permitted to create or approve pull requests")
      fail!(<<~MSG)
        #{stderr}
        PR creation is blocked for the current token.
        Fix one of:
        1) Repository Settings > Actions > General > Workflow permissions:
           enable "Allow GitHub Actions to create and approve pull requests".
        2) Set secret HOMEBREW_TAP_PR_TOKEN to a PAT with repo contents+pull_request write access.
      MSG
    end
    warn stderr unless stderr.empty?
    fail!("Command failed: #{cmd.join(' ')}")
  end
  stdout
end

def normalize(value)
  value.to_s.delete("\r\n")
end

def env_required(name)
  value = ENV[name]
  fail!("Missing required env: #{name}") if value.nil? || value.empty?
  normalize(value)
end

def validate!(label, value, regex)
  fail!("Invalid #{label}: #{value}") unless value.match?(regex)
end

formula = env_required("FORMULA")
version = env_required("VERSION")
formula_file = env_required("FORMULA_FILE")
src_url = env_required("SRC_URL")
src_sha256 = env_required("SRC_SHA256")
base_branch = env_required("BASE_BRANCH")
assignee = normalize(ENV.fetch("ASSIGNEE", ""))

%w[git gh].each do |tool|
  run_cmd!("which", tool)
end

validate!("FORMULA", formula, /\A[a-z0-9][a-z0-9+_.-]*\z/)
fail!("Unexpected FORMULA_FILE path: #{formula_file}") unless formula_file == "Formula/#{formula}.rb"
validate!("VERSION", version, /\Av[0-9]+\.[0-9]+\.[0-9]+([-.][0-9A-Za-z.]+)*\z/)
validate!("SRC_SHA256", src_sha256, /\A[A-Fa-f0-9]{64}\z/)
validate!("BASE_BRANCH", base_branch, /\A[A-Za-z0-9._\/-]+\z/)
validate!("ASSIGNEE", assignee, /\A[A-Za-z0-9-]+\z/) unless assignee.empty?

url_regex = %r{\Ahttps://github\.com/pbsladek/ai-mr-comment/archive/refs/tags/v[0-9]+\.[0-9]+\.[0-9]+([-.][0-9A-Za-z.]+)*\.tar\.gz\z}
fail!("URL is not in the allowed source list: #{src_url}") unless src_url.match?(url_regex)

expected_url = "https://github.com/pbsladek/ai-mr-comment/archive/refs/tags/#{version}.tar.gz"
if src_url != expected_url
  fail!("URL/version mismatch. Expected URL: #{expected_url}; provided URL: #{src_url}")
end

safe_version = version.gsub(/[^[:alnum:]._-]/, "-")
branch = "automation/bump-#{formula}-#{safe_version}"
title = "chore(formula): bump #{formula} to #{version}"
run_url = "#{ENV.fetch('GITHUB_SERVER_URL', 'https://github.com')}/#{ENV.fetch('GITHUB_REPOSITORY', 'pbsladek/homebrew-tap')}/actions/runs/#{ENV.fetch('GITHUB_RUN_ID', 'unknown')}"
body = <<~BODY
  Automated formula update from upstream release metadata.

  - Formula: `#{formula}`
  - Version: `#{version}`
  - File: `#{formula_file}`
  - Source URL: `#{src_url}`
  - SHA256: `#{src_sha256}`
  - Workflow run: #{run_url}
BODY

run_cmd!("git", "config", "user.name", "github-actions[bot]")
run_cmd!("git", "config", "user.email", "41898282+github-actions[bot]@users.noreply.github.com")
run_cmd!("git", "fetch", "origin", base_branch)
run_cmd!("git", "checkout", "-B", branch, "origin/#{base_branch}")

content = File.read(formula_file)
unless content.match?(/^\s*url\s*".*"\s*$/) && content.match?(/^\s*sha256\s*".*"\s*$/)
  fail!("Could not find url/sha256 fields in #{formula_file}")
end

updated = content
  .sub(/^(\s*url\s*)".*?"(\s*)$/, "\\1\"#{src_url}\"\\2")
  .sub(/^(\s*sha256\s*)".*?"(\s*)$/, "\\1\"#{src_sha256}\"\\2")

File.write(formula_file, updated)
run_cmd!("git", "add", formula_file)

_out, _err, status = Open3.capture3("git", "diff", "--cached", "--quiet")
if status.success?
  puts "No staged formula changes to commit; skipping PR update."
  exit 0
end

run_cmd!("git", "commit", "-m", title)
run_cmd!("git", "push", "--force-with-lease", "--set-upstream", "origin", branch)

pr_json = run_cmd!("gh", "pr", "list", "--head", branch, "--base", base_branch, "--json", "number")
pr_number = begin
  parsed = JSON.parse(pr_json)
  parsed.is_a?(Array) && parsed.first ? parsed.first["number"] : nil
rescue JSON::ParserError
  nil
end

if pr_number
  cmd = ["gh", "pr", "edit", pr_number.to_s, "--title", title, "--body", body]
  cmd += ["--add-assignee", assignee] unless assignee.empty?
  run_cmd!(*cmd)
  puts "Updated PR ##{pr_number}"
else
  cmd = ["gh", "pr", "create", "--base", base_branch, "--head", branch, "--title", title, "--body", body]
  cmd += ["--assignee", assignee] unless assignee.empty?
  run_cmd!(*cmd)
  puts "Created PR for #{formula} #{version}"
end
