require 'sinatra'
require 'md5'
require 'diff'
require 'gitnode'
require 'Builder'

GITNODE_ROOT = ENV["GITNODE_ROOT"]

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

get '/:repo/comments/rss.xml' do |repo|
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

post '/:repo/commit/:sha/comments' do |repo, sha|
  comment = Comment.new(:repository_name => repo, :commit_sha => sha, :path => params[:path],
                        :body => params[:body], :author_name => params[:author_name], :author_email => params[:author_email])
  comment.save
  redirect "/#{repo}/commit/#{sha}"
end