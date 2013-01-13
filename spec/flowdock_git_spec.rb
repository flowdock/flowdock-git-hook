require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Flowdock Git Hook" do
  it "raises error if git token is not defined" do
    lambda {
      Flowdock::Git.new
    }.should raise_error(Flowdock::Git::TokenError)
  end

  it "can read token from git config" do
    Grit::Config.stub!(:new).and_return({
      "flowdock.token" => "flowdock-token"
    })

    lambda {
      Flowdock::Git.new
    }.should_not raise_error
  end

  it "encodes content as UTF-8" do
    @repo = Grit::Repo.new(".")
    @before = "7e32af569ba794b0b1c5e4c38fef1d4e2e56be51"
    @after = "a66d3ce668ae6f2a42d54d811962724200d5b32b"
    @repo.stub!(:path).and_return("/foo/bar/flowdock-git-hook/.git")
    @hash = Flowdock::Git::Builder.new(@repo, "refs/heads/master", @before, @after).to_hash
  end

  it "builds payload" do
    stub_request(:post, "https://api.flowdock.com/v1/git/flowdock-token")
    Flowdock::Git.post("refs/heads/master", "7e32af569ba794b0b1c5e4c38fef1d4e2e56be51", "a1a94ba4bfa5f855676066861604b8edae1a20f5", :token => "flowdock-token")
    a_request(:post, "https://api.flowdock.com/v1/git/flowdock-token").with { |req|
      req.body.match(/7e32af569ba794b0b1c5e4c38fef1d4e2e56be51/)
    }.should have_been_made
  end

  it "builds payload with repo url, diff url and commit urls" do
    Grit::Config.stub!(:new).and_return({
      "flowdock.token" => "flowdock-token",
      "flowdock.repository-url" => "http://www.example.com",
      "flowdock.diff-url-pattern" => "http://www.example.com/compare/%s...%s",
      "flowdock.commit-url-pattern" => "http://www.example.com/commit/%s"
    })
    stub_request(:post, "https://api.flowdock.com/v1/git/flowdock-token")
    Flowdock::Git.post("refs/heads/master", "7e32af569ba794b0b1c5e4c38fef1d4e2e56be51", "a1a94ba4bfa5f855676066861604b8edae1a20f5", :token => "flowdock-token")
    a_request(:post, "https://api.flowdock.com/v1/git/flowdock-token").with { |req|
      body = CGI.unescape(req.body)
      body.match("http://www.example.com/") &&
      body.match("http://www.example.com/compare/7e32af569ba794b0b1c5e4c38fef1d4e2e56be51...a1a94ba4bfa5f855676066861604b8edae1a20f5")
    }.should have_been_made
  end

  describe "Tagging" do
    it "reads tags from initializer parameter" do
      tags = Flowdock::Git.new(:token => "flowdock-token", :tags => ["foo", "bar"]).send(:tags)
      tags.should include("foo", "bar")
    end

    it "reads tags from gitconfig as fallback" do
      Grit::Config.stub!(:new).and_return({
        "flowdock.tags" => "foo,bar"
      })
      tags = Flowdock::Git.new(:token => "flowdock-token").send(:tags)
      tags.should include("foo", "bar")
    end

    it "encodes tags suitable for URI" do
      Flowdock::Git.new(:token => "flowdock-token", :tags => ["foo%bar"]).send(:tags).should include("foo%25bar")
    end
  end
end

describe "Flowdock Git Hook", "HTTP Post" do
  before :each do
    stub_request(:post, "https://api.flowdock.com/v1/git/flowdock-token+foo+bar")
    Flowdock::Git.post("origin/refs/master", "7e32af569ba794b0b1c5e4c38fef1d4e2e56be51", "a1a94ba4bfa5f855676066861604b8edae1a20f5", :token => "flowdock-token", :tags => ["foo", "bar"])
  end

  it "posts to api.flowdock.com" do
    a_request(:post, "https://api.flowdock.com/v1/git/flowdock-token+foo+bar").should have_been_made
  end

  it "sends payload encoded as JSON" do
    payload = MultiJson.encode(Flowdock::Git::Builder.new(Grit::Repo.new("."), "origin/refs/master", "7e32af569ba794b0b1c5e4c38fef1d4e2e56be51", "a1a94ba4bfa5f855676066861604b8edae1a20f5").to_hash)
    a_request(:post, "https://api.flowdock.com/v1/git/flowdock-token+foo+bar").with(:body => {:payload => payload}).should have_been_made
  end
end
