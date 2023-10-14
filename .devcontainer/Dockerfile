FROM quay.io/evl.ms/fullstaq-ruby:3.2.2-jemalloc-bookworm-slim

RUN apt-get update -q \
    && apt-get install --assume-yes -q --no-install-recommends \
      build-essential \
      watchman \
    && apt-get autoremove --assume-yes \
    && rm -rf /var/lib/apt/lists \
    && rm -fr /var/cache/apt
