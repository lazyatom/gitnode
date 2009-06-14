require 'sinatra'
require 'grit'
require 'md5'

require 'diff'

GITNODE_ROOT = ENV["GITNODE_ROOT"]

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
  end
  
  class Head
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

def load_repository(repo, branch=nil)
  @repository = GitNode::Repository.new(repo)
  @branch ||= 'master'
end

helpers do
  include Rack::Utils
  def link_to_commit(commit, text=nil)
    %{<a href="/#{commit.repository.name}/commit/#{commit.sha}">#{text || commit.sha}</a>}
  end
  def link_to_repository(repository, text=nil)
    %{<a href="/#{repository.name}">#{text || repository.name}</a>}
  end
  def gravatar(person)
    %{<img src="http://gravatar.com/avatar/#{MD5.md5(person.email).to_s}.jpg?s=30">}
  end
end

get '/favicon.ico' do
end

get '/:repo/commit/:sha/?' do |repo, sha|
  load_repository(repo)
  @commit = @repository.commit(sha)
  erb :commit
end

get '/:repo/:branch/?' do |repo, branch|
  load_repository(repo, branch)
  erb :repository
end

get '/:repo/?' do |repo|
  load_repository(repo)
  erb :repository
end