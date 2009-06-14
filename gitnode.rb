require 'sinatra'
require 'grit'
require 'md5'

require 'diff'

GITNODE_ROOT = ENV["GITNODE_ROOT"]

module GitNode
  class Repository
    attr_reader :name
    def initialize(path)
      @name = File.basename(path)
      @repo = Grit::Repo.new(path)
    end
    def commits(*args)
      @repo.commits(*args).map { |c| Commit.new(self, c) }
    end
    def commit(*args)
      Commit.new(self, @repo.commit(*args))
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
end

def repo(params)
  path = File.join(GITNODE_ROOT, params[:repo])
  path += ".git" unless File.exist?(path)
  GitNode::Repository.new(path)
end

get '/:repo/:branch/commits' do
  @repository = repo(params)
  erb :repository
end

get '/:repo/commit/:sha' do
  @repository = repo(params)
  @commit = @repository.commit(params[:sha])
  erb :commit
end

helpers do
  include Rack::Utils
  def link_to_commit(commit, text=nil)
    %{<a href="/#{commit.repository.name}/commit/#{commit.sha}">#{text || commit.sha}</a>}
  end
  def gravatar(person)
    %{<img src="http://gravatar.com/avatar/#{MD5.md5(person.email).to_s}.jpg?s=40">}
  end
end