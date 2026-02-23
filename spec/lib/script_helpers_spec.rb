# frozen_string_literal: true

require "spec_helper"
require_relative "../../.github/scripts/lib/script_helpers"

RSpec.describe ScriptHelpers do
  describe ".fail!" do
    it "prints to stderr and exits with status 1" do
      expect {
        expect { ScriptHelpers.fail!("Something went wrong") }
          .to output(/Something went wrong/).to_stderr
      }.to raise_error(SystemExit) do |error|
        expect(error.status).to eq(1)
      end
    end
  end

  describe ".run_cmd!" do
    it "returns stdout on success" do
      status = instance_double(Process::Status, success?: true)
      allow(Open3).to receive(:capture3).with("echo", "hello").and_return(["hello\n", "", status])

      result = ScriptHelpers.run_cmd!("echo", "hello")
      expect(result).to eq("hello\n")
    end

    it "warns stderr and exits on failure" do
      status = instance_double(Process::Status, success?: false)
      allow(Open3).to receive(:capture3).with("false").and_return(["", "error message", status])

      expect {
        expect { ScriptHelpers.run_cmd!("false") }
          .to output(/error message/).to_stderr
      }.to raise_error(SystemExit) do |error|
        expect(error.status).to eq(1)
      end
    end
  end

  describe ".ensure_tool!" do
    it "returns normally if tool is available" do
      status = instance_double(Process::Status, success?: true)
      allow(Open3).to receive(:capture3).with("command", "-v", "brew").and_return(["/path/to/brew\n", "", status])

      expect { ScriptHelpers.ensure_tool!("brew") }.not_to raise_error
    end

    it "exits if tool is not available" do
      status = instance_double(Process::Status, success?: false)
      allow(Open3).to receive(:capture3).with("command", "-v", "missing_tool").and_return(["", "", status])

      expect {
        expect { ScriptHelpers.ensure_tool!("missing_tool") }.to output(/Required tool not found: missing_tool/).to_stderr
      }.to raise_error(SystemExit) do |error|
        expect(error.status).to eq(1)
      end
    end
  end
end
