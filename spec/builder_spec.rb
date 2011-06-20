require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Git Payload Builder" do
  before :each do
    @repo = Grit::Repo.new(".")
    @before = "7e32af569ba794b0b1c5e4c38fef1d4e2e56be51"
    @after = "cf4a78c59cf9e06ebd7336900b2a66b85a88b76c"
  end

  it "parses ref name from head" do
    Flowdock::Git::Builder.new(@repo, "refs/heads/master", @before, @after).ref_name.should == "master"
  end

  it "parses ref name from tag" do
    Flowdock::Git::Builder.new(@repo, "refs/tags/release-1.0", @before, @after).ref_name.should == "release-1.0"
  end

  describe "data hash" do
    before :each do
      @repo.stub!(:path).and_return("/foo/bar/flowdock-git-hook/.git")
      @hash = Flowdock::Git::Builder.new(@repo, "refs/heads/master", @before, @after).to_hash
    end

    it "contains before" do
      @hash[:before].should == @before
    end

    it "contains after" do
      @hash[:after].should == @after
    end

    it "contains ref" do
      @hash[:ref].should == "refs/heads/master"
    end

    it "contains ref name" do
      @hash[:ref_name].should == "master"
    end

    describe "repository information" do
      it "contains repository name based on file path" do
        @hash[:repository][:name] = "flowdock-git-hook"
      end
    end
  end
end
