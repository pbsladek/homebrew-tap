class AiMrComment < Formula
  desc "Generate AI-powered MR/PR comments from git diffs"
  homepage "https://github.com/pbsladek/ai-mr-comment"
  url "https://github.com/pbsladek/ai-mr-comment/archive/refs/tags/v1.11.1.tar.gz"
  sha256 "6ae1d7c299a37b0e02a3afe19063bdfed781b9fd99067df4084b0e8e5d9507e0"
  license "MIT"

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X main.Version=#{version}
      -X main.Commit=44c5f03
      -X main.CommitFull=44c5f0347b59a4b60935061a2d86a792bb55f9b1
    ]
    system "go", "build", *std_go_args(ldflags: ldflags.join(" ")), "."
  end

  test do
    assert_match "Generate MR/PR comments using AI", shell_output("#{bin}/ai-mr-comment --help")
  end
end
