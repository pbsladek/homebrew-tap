# frozen_string_literal: true

require "spec_helper"
require_relative "../.github/scripts/ruby-lint"

RSpec.describe "ruby-lint.rb" do
  describe "#run_lint!" do
    it "fails if no ruby files are found" do
      allow(Dir).to receive(:glob).with("Formula/*.rb").and_return([])

      expect {
        expect { run_lint! }.to output(/No Ruby files found under Formula/).to_stderr
      }.to raise_error(SystemExit) do |error|
        expect(error.status).to eq(1)
      end
    end

    it "runs brew style for each formula file" do
      allow(Dir).to receive(:glob).with("Formula/*.rb").and_return(["Formula/a.rb", "Formula/b.rb"])
      allow(ScriptHelpers).to receive(:run_cmd!)

      expect { run_lint! }.to output(/Linting Ruby files: Formula\/a.rb Formula\/b.rb/).to_stdout

      expect(ScriptHelpers).to have_received(:run_cmd!).with("brew", "style", "Formula/a.rb")
      expect(ScriptHelpers).to have_received(:run_cmd!).with("brew", "style", "Formula/b.rb")
    end
  end
end
