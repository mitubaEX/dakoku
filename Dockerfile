FROM ruby:2.6-alpine

ENV RUNTIME_PACKAGES="linux-headers libxml2-dev libxslt-dev make gcc libc-dev nodejs tzdata postgresql-dev postgresql" \
    DEV_PACKAGES="build-base curl-dev" \
    HOME="/myapp"

ADD Gemfile      $HOME/Gemfile
ADD Gemfile.lock $HOME/Gemfile.lock

WORKDIR $HOME

RUN apk update && \
    apk upgrade

RUN apk add --update --no-cache $RUNTIME_PACKAGES && \
    apk add --update --virtual build-dependencies --no-cache $DEV_PACKAGES && \
    gem install bundler:2.0.1 && \
    bundle install -j4 && \
    apk del build-dependencies

ADD . $HOME

CMD ["bundle", "exec", "ruby", "myapp.rb"]
