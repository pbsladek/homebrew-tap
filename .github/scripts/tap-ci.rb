#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/script_helpers"

tap_name = ENV.fetch("TAP_NAME", "pbsladek/tap")
workspace = ENV.fetch("GITHUB_WORKSPACE", Dir.pwd)

unless tap_name.match?(/\A[a-zA-Z0-9_.-]+\/[a-zA-Z0-9_.-]+\z/)
  ScriptHelpers.fail!("Invalid TAP_NAME: #{tap_name}")
end

%w[brew git].each { |tool| ScriptHelpers.ensure_tool!(tool) }

taps = ScriptHelpers.capture_cmd!("brew", "tap").split("\n")
ScriptHelpers.run_cmd!("brew", "untap", "--force", tap_name) if taps.include?(tap_name)
ScriptHelpers.run_cmd!("brew", "tap", "--custom-remote", tap_name, workspace)

formulae = Dir.glob("Formula/*.rb").sort.map { |f| File.basename(f, ".rb") }
ScriptHelpers.fail!("No formulae found in Formula/.") if formulae.empty?

puts "Found formulae: #{formulae.join(' ')}"

puts "Running Ruby format check"
ScriptHelpers.run_cmd!(".github/scripts/ruby-fmt.rb", "check")

puts "Running Ruby lint"
ScriptHelpers.run_cmd!(".github/scripts/ruby-lint.rb")

formulae.each do |formula|
  target = "#{tap_name}/#{formula}"
  puts "brew audit --strict --online #{target}"
  ScriptHelpers.run_cmd!("brew", "audit", "--strict", "--online", target)

  puts "brew install --build-from-source #{target}"
  ScriptHelpers.run_cmd!("brew", "install", "--build-from-source", target)

  puts "brew test #{target}"
  ScriptHelpers.run_cmd!("brew", "test", target)
end
