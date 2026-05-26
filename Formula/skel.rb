class Skel < Formula
  desc "Create files and directories from an indented tree"
  homepage "https://github.com/mark-mcdermott/skel"
  url "https://github.com/mark-mcdermott/skel/archive/refs/tags/v0.3.0.tar.gz"
  # After creating the v0.3.0 release, run:
  #   curl -L https://github.com/mark-mcdermott/skel/archive/refs/tags/v0.3.0.tar.gz | shasum -a 256
  # and replace the placeholder below with the result.
  sha256 "REPLACE_WITH_SHA256_AFTER_RELEASE"
  license "MIT"

  def install
    bin.install "skel.sh" => "skel"
  end

  test do
    (testpath/"structure.txt").write("README.md\n")
    system "#{bin}/skel < #{testpath}/structure.txt"
    assert_predicate testpath/"README.md", :exist?
  end
end
