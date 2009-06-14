# This file goes in domain.com/config.ru
require 'rubygems'
require 'sinatra'
 
set :run, false
 
require 'app'
run Sinatra::Application