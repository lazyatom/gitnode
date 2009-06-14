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

__END__

@@ layout
<html>
  <head>
    <link rel="stylesheet" href="/appliation.css"></link>
  </head>
  <body>
    <div class="container">
      <%= yield %>
    </div>
  </body>
</html>

@@ repository
<ul>
  <% @repository.commits(params[:branch], false).each do |commit| %>
    <li><%= link_to_commit commit %></li>
  <% end %>
</ul>

@@ commit
<div class="details">
  <div class="commit_info">
    <div class="message"><%= @commit.message %></div>
    
    <div class="author person">
      <%= gravatar @commit.author %>
      <div class="contact">
        <p><%= @commit.author.name %></p>
        <p><%= @commit.authored_date.strftime("%d %b, %Y") %></p>
      </div>
    </div>
    <% if @commit.author.email != @commit.committer.email %>
      <div class="committer person">
        <%= gravatar @commit.committer %>
        <div class="contact">
          <p><%= @commit.committer.name %></p>
          <p><%= @commit.committed_date.strftime("%d %b, %Y") %></p>
        </div>
      </div>
    <% end %>
  </div>
  <dl class="related_commits">
    <dt>commit</dt><dd><%= @commit.sha %></dd>
    <dt>parents</dt>
    <dd>
      <ul class="parents">
        <% @commit.parents.each do |c|%>
          <li><%= link_to_commit c %></li>
        <% end %>
      </ul>
    </dd>
  </dl>
</div>
<% @commit.show.each do |bit| %>
  <% if bit.deleted_file %>
    <p><%= bit.b_path %> was deleted.</p>
  <% else %>
    <div class="diff">
      <h2><%= bit.b_path %></h2>
      <div class="diff_container">
        <%= diff bit %>
      </div>
    </div>
  <% end %>
<% end %>
