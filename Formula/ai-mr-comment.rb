class AiMrComment < Formula
  desc "Generate AI-powered MR/PR comments from git diffs"
  homepage "https://github.com/pbsladek/ai-mr-comment"
  url "https://github.com/pbsladek/ai-mr-comment/archive/refs/tags/v1.7.9.tar.gz"
  sha256 "d009b2af8682f07c2ea015a7518c4f585afddb5f8c3ccb3f43edd5a25372739a"
  license "MIT"

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X main.Version=#{version}
      -X main.Commit=9644b4a
      -X main.CommitFull=9644b4a81029ebb55d77f31a0ddbf58c44acec59
    ]
    system "go", "build", *std_go_args(ldflags: ldflags.join(" ")), "."
  end

  test do
    assert_match "Generate MR/PR comments using AI", shell_output("#{bin}/ai-mr-comment --help")
  end
end
