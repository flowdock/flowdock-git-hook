require "grit"

module Flowdock
  class Git
    class Builder
      def initialize(repo, ref, before, after)
        @repo = repo
        @ref = ref
        @before = before
        @after = after
      end

      def commits
        []
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
        }
      end
    end
  end
end
