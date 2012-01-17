# encoding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Git Payload Builder" do
  before :each do
    @repo = Grit::Repo.new(".")
    @before = "7e32af569ba794b0b1c5e4c38fef1d4e2e56be51"
    @after = "a66d3ce668ae6f2a42d54d811962724200d5b32b"
  end

  it "parses ref name from head" do
    Flowdock::Git::Builder.new(@repo, "refs/heads/master", @before, @after).ref_name.should == "master"
  end

  it "parses ref name from tag" do
    Flowdock::Git::Builder.new(@repo, "refs/tags/release-1.0", @before, @after).ref_name.should == "release-1.0"
  end

  it "detects new branch and sets created=true in data" do
    hash = Flowdock::Git::Builder.new(@repo, "refs/heads/master", "0000000000000000000000000000000000000000", @after).to_hash
    hash[:created].should eq(true)
    hash[:deleted].should_not eq(true)
  end

  it "detects deleted branch and sets deleted=true in data" do
    hash = Flowdock::Git::Builder.new(@repo, "refs/heads/master", @before, "0000000000000000000000000000000000000000").to_hash
    hash[:deleted].should eq(true)
    hash[:created].should_not eq(true)
  end

  it "doesn't include commits in branch delete" do
    hash = Flowdock::Git::Builder.new(@repo, "refs/heads/master", @before, "0000000000000000000000000000000000000000").to_hash
    hash[:commits].should be_empty
  end

  describe "data hash" do
    before :each do
      @repo.stub!(:path).and_return("/foo/bar/flowdock-git-hook/.git")
      @hash = Flowdock::Git::Builder.new(@repo, "refs/heads/master", @before, @after).to_hash
    end

    if RUBY_VERSION > '1.9'
      it "properly sets encoding for UTF-8 content" do
        builder = Flowdock::Git::Builder.new(@repo, "refs/heads/master", @before, "0000000000000000000000000000000000000000")
        builder.stub(:commits).and_return([
          {
            :id => "0000000000000000000000000000000000000001",
            :message => "This message contains UTF-8: ö".force_encoding("ASCII-8BIT"),
            :timestamp => Time.now.iso8601,
            :author => {
              :name => "Föö Bär".force_encoding("ASCII-8BIT"),
              :email => "foo@example.com"
            },
            :removed => [],
            :added => [],
            :modified => []
          }
        ])
        builder.to_hash[:commits][0][:message].encoding.should eq(Encoding::UTF_8)
        builder.to_hash[:commits][0][:message].should == "This message contains UTF-8: ö"
      end

      it "encodes ISO-8859-1 to UTF-8" do
        builder = Flowdock::Git::Builder.new(@repo, "refs/heads/master", @before, "0000000000000000000000000000000000000000")
        builder.stub(:commits).and_return([
          {
            :id => "0000000000000000000000000000000000000001",
            :message => "This message contains UTF-8: ö".encode("ISO-8859-1").force_encoding("ASCII-8BIT"),
            :timestamp => Time.now.iso8601,
            :author => {
              :name => "Föö Bär".encode("ISO-8859-1").force_encoding("ASCII-8BIT"),
              :email => "foo@example.com"
            },
            :removed => [],
            :added => [],
            :modified => []
          }
        ])
        builder.to_hash[:commits][0][:author][:name].encoding.should eq(Encoding::UTF_8)
        builder.to_hash[:commits][0][:author][:name].should == "Föö Bär"
      end
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

    describe "commits" do
      it "contains all changed commits" do
        @hash[:commits].should have(2).items
      end

      it "has commit author information" do
        @hash[:commits].first[:author][:name].should eq("Ville Lautanala")
        @hash[:commits].first[:author][:email].should eq("lautis@gmail.com")
      end

      it "has commit id" do
        @hash[:commits].first[:id].should == "cf4a78c59cf9e06ebd7336900b2a66b85a88b76c"
      end

      it "puts deleted files in an array" do
        @hash[:commits].first[:removed].should include("spec/flowdock-git-hook_spec.rb")
      end

      it "puts added files to an array" do
        @hash[:commits].first[:added].should include("lib/flowdock/git.rb")
      end

      it "detects modified files" do
        @hash[:commits].first[:modified].should_not include("spec/flowdock-git-hook_spec.rb")
        @hash[:commits].first[:modified].should_not include("lib/flowdock/git.rb")
        @hash[:commits].first[:modified].should include("lib/flowdock-git-hook.rb")
      end
    end

    describe "repository information" do
      it "contains repository name based on file path" do
        @hash[:repository][:name] = "flowdock-git-hook"
      end
    end
  end
end
