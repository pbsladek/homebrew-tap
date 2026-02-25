class AiMrComment < Formula
  desc "Generate AI-powered MR/PR comments from git diffs"
  homepage "https://github.com/pbsladek/ai-mr-comment"
  url "https://github.com/pbsladek/ai-mr-comment/archive/refs/tags/v1.2.0.tar.gz"
  sha256 "3ad31b7af052bdc693933b5ee5df0d968bb1b5c8c4b64a74a3660d60d6c3f062"
  license "MIT"

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X main.Version=#{version}
      -X main.Commit=104e6f9
      -X main.CommitFull=104e6f93907644098e734c753a8d00a38bd2ee52
    ]
    system "go", "build", *std_go_args(ldflags: ldflags.join(" ")), "."
  end

  test do
    assert_match "Generate MR/PR comments using AI", shell_output("#{bin}/ai-mr-comment --help")
  end
end
