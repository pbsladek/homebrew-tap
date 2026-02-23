#!/usr/bin/env ruby
# frozen_string_literal: true

require "open3"
require "net/http"
require "uri"
require "digest"
require_relative "lib/script_helpers"

tap_name = ENV.fetch("TAP_NAME", "pbsladek/tap")
workspace = ENV.fetch("GITHUB_WORKSPACE", Dir.pwd)
event_name = ENV.fetch("EVENT_NAME", "")
run_brew_checks = ENV.fetch("RUN_BREW_CHECKS", "true") == "true"
apply_formula_changes = ENV.fetch("APPLY_FORMULA_CHANGES", "false") == "true"
changed = "false"

formula, version, src_url, src_sha256 = if event_name == "workflow_dispatch"
  [
    ENV["INPUT_FORMULA"],
    ENV["INPUT_VERSION"],
    ENV["INPUT_URL"],
    ENV["INPUT_SHA256"]
  ]
else
  [
    ENV.fetch("PAYLOAD_FORMULA", "ai-mr-comment"),
    ENV["PAYLOAD_VERSION"],
    ENV["PAYLOAD_URL"],
    ENV["PAYLOAD_SHA256"]
  ]
end

if formula.nil? || formula.empty? || version.nil? || version.empty? || src_url.nil? || src_url.empty? || src_sha256.nil? || src_sha256.empty?
  puts "Missing required payload values."
  puts "formula=#{formula}"
  puts "version=#{version}"
  puts "url=#{src_url}"
  puts "sha256=#{src_sha256}"
  exit 1
end

ScriptHelpers.fail!("Invalid TAP_NAME: #{tap_name}") unless tap_name.match?(/\A[a-zA-Z0-9_.-]+\/[a-zA-Z0-9_.-]+\z/)
ScriptHelpers.fail!("Invalid formula name: #{formula}") unless formula.match?(/\A[a-z0-9][a-z0-9+_.-]*\z/)
ScriptHelpers.fail!("Formula is not in the allowed release-dispatch list: #{formula}") if formula != "ai-mr-comment"
ScriptHelpers.fail!("Invalid version format: #{version}") unless version.match?(/\Av[0-9]+\.[0-9]+\.[0-9]+([-.][0-9A-Za-z]+)*\z/)
ScriptHelpers.fail!("Invalid sha256 format.") unless src_sha256.match?(/\A[A-Fa-f0-9]{64}\z/)

url_regex = %r{\Ahttps://github\.com/pbsladek/ai-mr-comment/archive/refs/tags/v[0-9]+\.[0-9]+\.[0-9]+([-.][0-9A-Za-z]+)*\.tar\.gz\z}
ScriptHelpers.fail!("URL is not in the allowed source list: #{src_url}") unless src_url.match?(url_regex)

expected_url = "https://github.com/pbsladek/ai-mr-comment/archive/refs/tags/#{version}.tar.gz"
if src_url != expected_url
  puts "URL/version mismatch."
  puts "Expected URL: #{expected_url}"
  puts "Provided URL: #{src_url}"
  exit 1
end

# Calculate actual SHA256 using curl, similar to bash script
actual_sha256_output = Open3.capture3("curl", "-fsSL", src_url)
if actual_sha256_output[2].success?
  actual_sha256 = Digest::SHA256.hexdigest(actual_sha256_output[0])
else
  ScriptHelpers.fail!("Failed to fetch upstream source tarball.")
end

if actual_sha256 != src_sha256
  puts "SHA mismatch for upstream source tarball."
  puts "Expected: #{src_sha256}"
  puts "Actual:   #{actual_sha256}"
  exit 1
end
puts "Upstream source checksum validated."

formula_file = "Formula/#{formula}.rb"
unless File.exist?(formula_file)
  puts "Missing #{formula_file}"
  exit 1
end

content = File.read(formula_file)
current_url_match = content.match(/^[ \t]*url[ \t]*"(.*?)"/)
current_sha_match = content.match(/^[ \t]*sha256[ \t]*"(.*?)"/)

unless current_url_match
  puts "Could not parse url from #{formula_file}"
  exit 1
end
current_url = current_url_match[1]

unless current_sha_match
  puts "Could not parse sha256 from #{formula_file}"
  exit 1
end
current_sha = current_sha_match[1]

current_version_match = current_url.match(%r{.*refs/tags/(v[^/"]*)\.tar\.gz})
unless current_version_match
  puts "Could not parse version from formula URL"
  exit 1
end
current_version = current_version_match[1]

if current_url != src_url || current_sha != src_sha256
  if apply_formula_changes
    puts "Updating #{formula_file} to #{version}"
    updated_content = content.sub(/^([ \t]*url[ \t]*").*?("[ \t]*)$/, "\\1#{src_url}\\2")
                             .sub(/^([ \t]*sha256[ \t]*").*?("[ \t]*)$/, "\\1#{src_sha256}\\2")
    File.write(formula_file, updated_content)
  end
  changed = "true"
else
  puts "Formula already up to date for #{version}."
end

if run_brew_checks
  ScriptHelpers.ensure_tool!("brew")

  stdout, _stderr, _status = Open3.capture3("brew", "tap")
  if stdout.lines.map(&:strip).include?(tap_name)
    ScriptHelpers.run_cmd!("brew", "untap", "--force", tap_name)
  end

  ScriptHelpers.run_cmd!("brew", "tap", "--custom-remote", tap_name, workspace)
  ScriptHelpers.run_cmd!("brew", "style", formula_file)
  ScriptHelpers.run_cmd!("brew", "audit", "--strict", "--online", "#{tap_name}/#{formula}")
  ScriptHelpers.run_cmd!("brew", "install", "--build-from-source", "#{tap_name}/#{formula}")
  ScriptHelpers.run_cmd!("brew", "test", "#{tap_name}/#{formula}")
end

if ENV["GITHUB_OUTPUT"] && !ENV["GITHUB_OUTPUT"].empty?
  File.open(ENV["GITHUB_OUTPUT"], "a") do |f|
    f.puts "formula=#{formula}"
    f.puts "version=#{version}"
    f.puts "src_url=#{src_url}"
    f.puts "src_sha256=#{src_sha256}"
    f.puts "formula_file=#{formula_file}"
    f.puts "changed=#{changed}"
  end
end
