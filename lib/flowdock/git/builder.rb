require "grit"

module Flowdock
  class Git
    # Class used to build Git payload
    class Builder
      def initialize(repo, ref, before, after)
        @repo = repo
        @ref = ref
        @before = before
        @after = after
      end

      def commits
        @repo.commits_between(@before, @after).map do |commit|
          {
            :id => commit.sha,
            :message => commit.message,
            :timestamp => commit.authored_date.iso8601,
            :author => {
              :name => commit.author.name,
              :email => commit.author.email
            },
            :removed => filter(commit.diffs) { |d| d.deleted_file },
            :added => filter(commit.diffs) { |d| d.new_file },
            :modified => filter(commit.diffs) { |d| !d.deleted_file && !d.new_file }
          }
        end
      end

      def ref_name
        @ref.to_s.sub(/\Arefs\/(heads|tags)\//, '')
      end

      def to_hash
        {
          :before   => @before,
          :after    => @after,
          :ref      => @ref,
          :commits  => commits,
          :ref_name => @ref.to_s.sub(/\Arefs\/(heads|tags)\//, ''),
          :repository => {
            :name => File.basename(Dir.pwd).sub(/\.git$/,'')
          }
        }.merge(if @before == "0000000000000000000000000000000000000000"
          {:created => true}
        elsif @after == "0000000000000000000000000000000000000000"
          {:deleted => true}
        else
          {}
        end)
      end

      private

      def filter(diffs)
        diffs.select { |e| yield e }.map { |diff| diff.b_path }
      end
    end
  end
end
