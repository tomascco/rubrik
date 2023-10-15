FROM quay.io/evl.ms/fullstaq-ruby:3.2.2-jemalloc-bookworm

RUN apt-get update -q \
    && apt-get install --assume-yes -q --no-install-recommends \
      build-essential \
      watchman \
      libyaml-dev \
    && apt-get autoremove --assume-yes \
    && rm -rf /var/lib/apt/lists \
    && rm -fr /var/cache/apt
