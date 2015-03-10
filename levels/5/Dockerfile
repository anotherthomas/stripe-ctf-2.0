FROM ruby:1.9-onbuild

RUN gem install bundler; touch production
cmd ./srv.rb

EXPOSE 4567
