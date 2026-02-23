#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/script_helpers"

mode = ARGV[0] || "check"
ruby_files = Dir.glob("Formula/*.rb").sort

if ruby_files.empty?
  ScriptHelpers.fail!("No Ruby files found under Formula/.")
end

case mode
when "write"
  puts "Formatting Ruby files: #{ruby_files.join(' ')}"
  ruby_files.each { |file| ScriptHelpers.run_cmd!("brew", "style", "--fix", file) }
when "check"
  puts "Checking Ruby formatting: #{ruby_files.join(' ')}"
  ruby_files.each { |file| ScriptHelpers.run_cmd!("brew", "style", file) }
else
  ScriptHelpers.fail!("Usage: #{File.basename($PROGRAM_NAME)} [check|write]")
end
