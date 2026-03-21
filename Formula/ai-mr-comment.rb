class AiMrComment < Formula
  desc "Generate AI-powered MR/PR comments from git diffs"
  homepage "https://github.com/pbsladek/ai-mr-comment"
  url "https://github.com/pbsladek/ai-mr-comment/archive/refs/tags/v1.6.1.tar.gz"
  sha256 "97855e23c01689e84f1df2ec5683c3a3228aff3f19cb4f748a36924701517718"
  license "MIT"

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X main.Version=#{version}
      -X main.Commit=f4e07a8
      -X main.CommitFull=f4e07a82da5ad8484d3db3a8bdee453b407cc925
    ]
    system "go", "build", *std_go_args(ldflags: ldflags.join(" ")), "."
  end

  test do
    assert_match "Generate MR/PR comments using AI", shell_output("#{bin}/ai-mr-comment --help")
  end
end
