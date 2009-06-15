require 'grit'
require 'comment'

module GitNode
  class Repository
    attr_reader :name, :path
    def initialize(name)
      @name = name
      @path = File.join(GITNODE_ROOT, @name)
      @path += ".git" unless File.exist?(@path)
      @repo = Grit::Repo.new(@path)
    end
    def commits(*args)
      @repo.commits(*args).map { |c| Commit.new(self, c) }
    end
    def commit(*args)
      Commit.new(self, @repo.commit(*args))
    end
    def branches(*args)
      @repo.branches(*args).map { |h| Head.new(self, h) }
    end
    def method_missing(*args)
      @repo.send(*args)
    end
  end
  
  class Commit
    attr_reader :repository
    def initialize(repository, commit)
      @repository = repository
      @commit = commit
    end
    def parents
      @commit.parents.map { |c| GitNode::Commit.new(@repository, c) }
    end
    def method_missing(*args)
      @commit.send(*args)
    end
    def show
      @commit.show.map { |b| GitNode::Bit.new(@repository, self, b) }
    end
  end
  
  class Bit
    def initialize(repository, commit, bit)
      @repository = repository
      @commit = commit
      @bit = bit
    end
    def method_missing(*args)
      @bit.send(*args)
    end
    def comments
      Comment.all(:conditions => {:repository_name => @repository.name, :commit_sha => @commit.sha, :path => @bit.b_path},
                  :order => [:created_at.asc])
    end
  end
  
  class Head
    attr_reader :repository
    def initialize(repository, head)
      @repository = repository
      @head = head
    end
    def commit
      GitNode::Commit.new(@repository, @head.commit)
    end
    def method_missing(*args)
      @head.send(*args)
    end
  end
end