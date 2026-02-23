#!/usr/bin/env ruby
# frozen_string_literal: true

require "open3"

module ScriptHelpers
  module_function

  def fail!(message)
    warn message
    exit 1
  end

  def run_cmd!(*cmd)
    stdout, stderr, status = Open3.capture3(*cmd)
    unless status.success?
      warn stderr unless stderr.empty?
      fail!("Command failed: #{cmd.join(' ')}")
    end
    stdout
  end

  def capture_cmd!(*cmd)
    run_cmd!(*cmd)
  end

  def tool_available?(tool)
    _out, _err, status = Open3.capture3("command", "-v", tool)
    status.success?
  end

  def ensure_tool!(tool)
    fail!("Required tool not found: #{tool}") unless tool_available?(tool)
  end
end
