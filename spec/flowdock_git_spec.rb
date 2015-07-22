require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Flowdock Git Hook" do
  let(:before) { "611ef32e3eee84b61a7efd496bd71ae1af165823" }
  let(:after) { "3a29fcd42ca69f40c8ed357052843d8e1e549013" }
  let(:commits_in_range) { 8 }
  let(:flowdock_token) { SecureRandom.hex }
  let(:expected_message) {
    {
      event: "activity",
      title: "3f3a5fd Bumped version",
      thread: {
        title: "branch master updated",
        external_url: nil,
      },
      author: {
        name: "Antti Pitkanen",
        email: "antti@flowdock.com"
      },
      body: nil,
      flow_token: flowdock_token
    }
  }

  let!(:request) do
    stub_request(:post, "https://api.flowdock.com/v1/messages")
  end

  it "raises error if git token is not defined" do
    lambda {
      Flowdock::Git.new "ref", "from", "to"
    }.should raise_error(Flowdock::Git::TokenError)
  end

  it "can read token from git config" do
    Grit::Config.stub!(:new).and_return({
      "flowdock.token" => flowdock_token
    })

    lambda {
      Flowdock::Git.new "ref", "from", "to"
    }.should_not raise_error
  end

  it "builds payload" do
    Flowdock::Git.post("refs/heads/master", before, after, token: flowdock_token)
    expect(request.with(body: hash_including(expected_message))).to have_been_made
  end

  it "adds repo name to title if given" do
    Grit::Config.stub!(:new).and_return(
      "flowdock.repository-name" => "some repo"
    )
    Flowdock::Git.post("refs/heads/master", before, after, token: flowdock_token)
    expect(request.with(body: hash_including(
                          thread: expected_message[:thread].merge(title: "some repo branch master updated")))
          ).to have_been_made.times(commits_in_range - 1)  # da fuq. if you figure out why 139fdb4 does not generate a hit please do tell me
  end

  it "posts all transient branch updates to same thread" do
    Grit::Config.stub!(:new).and_return(
      "flowdock.permanent-references" => ""
    )
    Flowdock::Git.post("refs/heads/master", before, after, token: flowdock_token)
    expect(request.with(body: hash_including(external_thread_id: "refs/heads/master"))
          ).to have_been_made.times(commits_in_range)
  end

  it "builds payload with repo url, diff url and commit urls" do
    Grit::Config.stub!(:new).and_return({
      "flowdock.token" => "flowdock-token",
      "flowdock.repository-url" => "http://www.example.com",
      "flowdock.diff-url-pattern" => "http://www.example.com/compare/%s...%s",
      "flowdock.commit-url-pattern" => "http://www.example.com/commit/%s"
    })
    Flowdock::Git.post("refs/heads/master", before, after, token: flowdock_token)
    expect(request.with(body: hash_including(expected_message.merge(
                                              thread: expected_message[:thread].merge(external_url: "http://www.example.com"),
                                              title: "<a href=\"http://www.example.com/commit/3f3a5fd37f53970f71adec08c5376ae003ba22a3\">3f3a5fd</a> Bumped version"
                                            )))
          ).to have_been_made
  end

  it "attaches tags from configuration" do
    Grit::Config.stub!(:new).and_return({"flowdock.tags" => "git, push, foo%bar"})
    Flowdock::Git.post("refs/heads/master", before, after, token: flowdock_token)
    expect(request.with(body: hash_including(tags: ["git", "push", "foo%25bar"]))
          ).to have_been_made.times(7)
  end

  it "attaches tags from opts" do
    Flowdock::Git.post("refs/heads/master", before, after, token: flowdock_token, tags: ["git", "push", "foo%bar"])
    expect(request.with(body: hash_including(tags: ["git", "push", "foo%25bar"]))
          ).to have_been_made.times(7)
  end
end
