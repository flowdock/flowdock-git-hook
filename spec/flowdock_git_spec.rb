require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Flowdock Git Hook" do
  it "raises error if git token is not defined" do
    lambda {
      Flowdock::Git.new("origin/refs/master", "random-hash", "random-hash")
    }.should raise_error(Flowdock::Git::TokenError)
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
