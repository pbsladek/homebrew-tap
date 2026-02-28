class AiMrComment < Formula
  desc "Generate AI-powered MR/PR comments from git diffs"
  homepage "https://github.com/pbsladek/ai-mr-comment"
  url "https://github.com/pbsladek/ai-mr-comment/archive/refs/tags/v1.4.5.tar.gz"
  sha256 "cb07a1ce7733b8d29f1eb549ad9634a68ce94320eb2e4d6ac3fde7f588b3b5e4"
  license "MIT"

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X main.Version=#{version}
      -X main.Commit=f02676a
      -X main.CommitFull=f02676a2ff377fdd565cd9d3c51cfc9ff5d3732f
    ]
    system "go", "build", *std_go_args(ldflags: ldflags.join(" ")), "."
  end

  test do
    assert_match "Generate MR/PR comments using AI", shell_output("#{bin}/ai-mr-comment --help")
  end
end
