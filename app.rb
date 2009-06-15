require 'sinatra'
require 'md5'
require 'diff'
require 'gitnode'

GITNODE_ROOT = ENV["GITNODE_ROOT"]

def load_repository(repo, branch=nil)
  @repository = GitNode::Repository.new(repo)
  @branch = branch || 'master'
end

def get_cookies
  @author_name = request.cookies["author_name"] || ""
  @author_email = request.cookies["author_email"] || ""
end

def set_cookies
  set_cookie "author_name", params[:author_name]
  set_cookie "author_email", params[:author_email]
end

helpers do
  include Rack::Utils
  def link_to_commit(commit, text=nil)
    %{<a href="/#{commit.repository.name}/commit/#{commit.sha}">#{text || commit.sha}</a>}
  end
  def link_to_repository
    %{<a href="/#{@repository.name}">#{@repository.name}</a>}
  end
  def link_to_feed
    %{<a href="/#{@repository.name}/comments/rss.xml">comment feed</a>}
  end
  def link_to_branch(branch)
    %{<a href="/#{branch.repository.name}/branch/#{branch.name}">#{branch.name}</a>}
  end
  def gravatar(email)
    %{<img src="http://gravatar.com/avatar/#{MD5.md5(email).to_s}.jpg?s=30">}
  end
  def link_to_server(path)
    url = request.scheme + "://" + request.host
    if request.scheme == "https" && request.port != 443 ||
        request.scheme == "http" && request.port != 80
      url << ":#{request.port}"
    end 
    url + "/" + path
  end
  def pagination_links
    links = ""
    page = params[:page] ? params[:page].to_i : 1
    links += %{<a href="#{request.path}?page=#{page-1}">prev</a> | } if page > 1
    links += %{<a href="#{request.path}?page=#{page+1}">next</a>}
    links
  end
end

get '/favicon.ico' do
end

get '/*/commit/:sha/?' do |repo, sha|
  get_cookies
  load_repository(repo)
  @commit = @repository.commit(sha)
  erb :commit
end

get '/*/comments/rss.xml' do |repo|
  comments = Comment.all(:repository_name => repo)
  builder do |xml|
    xml.instruct! :xml, :version => '1.0'
    xml.rss :version => "2.0" do
      xml.channel do
        xml.title "#{repo} comments"
        xml.description "Comments on the #{repo} repository"
        xml.link link_to_server("#{repo}")

        comments.each do |comment|
          xml.item do
            xml.title "#{comment.path} [#{comment.commit_sha[0..8]}]"
            xml.author "#{comment.author_name} <#{comment.author_email}>"
            xml.link link_to_server("#{repo}/commit/#{comment.commit_sha}#comment_#{comment.id}")
            xml.description comment.body
            xml.pubDate Time.parse(comment.created_at.to_s).rfc822()
            xml.guid link_to_server("#{repo}/commit/#{comment.commit_sha}#comment_#{comment.id}")
          end
        end
      end
    end
  end
end

post '/*/commit/:sha/comments' do |repo, sha|
  comment = Comment.new(:repository_name => repo, :commit_sha => sha, :path => params[:path],
                        :body => params[:body], :author_name => params[:author_name], :author_email => params[:author_email])
  comment.save
  set_cookies
  redirect "/#{repo}/commit/#{sha}"
end

get '/*/branch/:branch' do |repo, branch|
  load_repository(repo, branch)
  erb :repository
end

get '/*/?' do |repo|
  load_repository(repo)
  erb :repository
end

