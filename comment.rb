require 'datamapper'

DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/comments.db")

class Comment
  include DataMapper::Resource
  property :id, Serial
  property :repository_name, String
  property :commit_sha, String
  property :path, String
  property :body, Text
  property :author_name, String
  property :author_email, String
  property :created_at, DateTime
  
  default_scope(:default).update(:order => [:created_at.desc])
  
  auto_upgrade!
end