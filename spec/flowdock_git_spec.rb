require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Flowdock Git Hook" do
  it "raises error if git token is not defined" do
    lambda {
      Flowdock::Git.new("refs/heads/master", "random-hash", "random-hash")
    }.should raise_error(Flowdock::Git::TokenError)
  end

  it "can read token from git config" do
    Grit::Config.stub!(:new).and_return({
      "flowdock.token" => "flowdock-token"
    })

    lambda {
      Flowdock::Git.new("refs/heads/master", "random-hash", "random-hash")
    }.should_not raise_error
  end

  it "builds payload" do
    stub_request(:post, "https://api.flowdock.com/v1/git/flowdock-token")
    Flowdock::Git.new("refs/heads/master", "7e32af569ba794b0b1c5e4c38fef1d4e2e56be51", "a1a94ba4bfa5f855676066861604b8edae1a20f5", :token => "flowdock-token").post
    a_request(:post, "https://api.flowdock.com/v1/git/flowdock-token").with { |req|
      req.body.match(/7e32af569ba794b0b1c5e4c38fef1d4e2e56be51/)
    }.should have_been_made
  end
end

describe "Flowdock Git Hook", "HTTP Post" do
  before :each do
    @notifier = Flowdock::Git.new("origin/refs/master", "random-hash", "random-hash", :token => "flowdock-token")
    @notifier.stub(:payload) { {} }
    stub_request(:post, "https://api.flowdock.com/v1/git/flowdock-token")
  end

  it "posts to api.flowdock.com" do
    @notifier.post
    a_request(:post, "https://api.flowdock.com/v1/git/flowdock-token").should have_been_made
  end

  it "sends payload encoded as JSON" do
    @notifier.post
    a_request(:post, "https://api.flowdock.com/v1/git/flowdock-token").with(:body => {:payload => "{}"}).should have_been_made
  end
end
