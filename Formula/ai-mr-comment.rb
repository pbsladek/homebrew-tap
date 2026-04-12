class AiMrComment < Formula
  desc "Generate AI-powered MR/PR comments from git diffs"
  homepage "https://github.com/pbsladek/ai-mr-comment"
  url "https://github.com/pbsladek/ai-mr-comment/archive/refs/tags/v1.7.12.tar.gz"
  sha256 "7cb073cbbb2f0b5b7e919fd58196b1d42c0cee75ab9458197e71ef38fd7d551b"
  license "MIT"

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X main.Version=#{version}
      -X main.Commit=789b1ac
      -X main.CommitFull=789b1acfd79614d920698dd3206225a4bb0a671a
    ]
    system "go", "build", *std_go_args(ldflags: ldflags.join(" ")), "."
  end

  test do
    assert_match "Generate MR/PR comments using AI", shell_output("#{bin}/ai-mr-comment --help")
  end
end
