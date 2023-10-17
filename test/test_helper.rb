# frozen_string_literal: true
# typed: true

require "simplecov"
SimpleCov.start

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "rubrik"

require "minitest/autorun"
require "minitest/pride"
