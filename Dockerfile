ARG RUBY_VERSION=3.3.9
FROM ruby:$RUBY_VERSION-slim AS base
WORKDIR /rails
ENV RAILS_ENV="production" BUNDLE_DEPLOYMENT="1" BUNDLE_PATH="/usr/local/bundle" BUNDLE_WITHOUT="development"

FROM base AS build
RUN apt-get update -qq && apt-get install -y build-essential git libpq-dev libvips pkg-config libyaml-dev fontconfig fonts-noto-cjk \
  && rm -rf /var/lib/apt/lists/*
COPY Gemfile Gemfile.lock ./
RUN bundle install && bundle exec bootsnap precompile --gemfile
COPY . .
RUN bundle exec bootsnap precompile app/ lib/
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

FROM base
RUN apt-get update -qq && apt-get install -y curl libvips postgresql-client fontconfig fonts-noto-cjk \
  && rm -rf /var/lib/apt/lists/*
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /rails /rails
RUN useradd rails --create-home --shell /bin/bash && chown -R rails:rails db log storage tmp
USER rails:rails
ENTRYPOINT ["/rails/bin/docker-entrypoint"]
EXPOSE 3000
CMD ["./bin/rails", "server"]
