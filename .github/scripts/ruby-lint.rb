#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/script_helpers"

ruby_files = Dir.glob("Formula/*.rb").sort

if ruby_files.empty?
  ScriptHelpers.fail!("No Ruby files found under Formula/.")
end

puts "Linting Ruby files: #{ruby_files.join(' ')}"
ruby_files.each do |file|
  ScriptHelpers.run_cmd!("brew", "style", file)
end
