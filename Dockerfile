FROM ruby:3.3-slim-bookworm

RUN apt update && apt install -y --no-install-recommends \
    build-essential \
    git \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

ENV TZ=Asia/Seoul
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

WORKDIR /srv/jekyll
RUN git config --global --add safe.directory /srv/jekyll

COPY Gemfile ./
RUN bundle install

EXPOSE 4000

CMD ["bundle", "exec", "jekyll", "serve", "--force_polling", "-H", "0.0.0.0", "-P", "4000"]
