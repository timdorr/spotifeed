FROM ruby:2.7.2-alpine as ruby

FROM ruby as bundler
WORKDIR /home/app
COPY Gemfile* /home/app/
RUN apk add --update --no-cache build-base
WORKDIR /home/app
RUN bundle config set deployment 'true' \
  && bundle config set frozen 'true' \
  && bundle install \
  && find vendor/bundle/ -name ".git" -exec rm -rv {} + \
  && find vendor/bundle/ -name "*.c" -delete \
  && find vendor/bundle/ -name "*.o" -delete \
  && rm -rf vendor/bundle/ruby/*/cache \
  && apk del build-base

FROM ruby as runner
RUN apk add --update --no-cache gettext \
  && addgroup -g 1000 -S app \
  && adduser -u 1000 -S app -G app

USER app
WORKDIR /home/app

COPY --chown=app:app --from=bundler /usr/local/bundle/config /usr/local/bundle/config
COPY --chown=app:app --from=bundler /home/app/vendor /home/app/vendor
COPY --chown=app:app . /home/app
ENV PORT 9292

EXPOSE 9292

CMD ["sh", "./run.sh"]

FROM runner as release
RUN bundle install --local --clean --without development test \
  && find vendor/bundle/ -name "*.gem" -delete \
  && rm -rf spec tmp/cache node_modules app/assets vendor/assets lib/assets
