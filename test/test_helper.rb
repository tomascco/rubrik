# frozen_string_literal: true
# typed: true

require "simplecov"
SimpleCov.start do
  add_filter "/test/"
  enable_coverage :branch
end

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "rubrik"

require "minitest/autorun"
require "minitest/pride"

class Rubrik::Test < Minitest::Test
  make_my_diffs_pretty!
  parallelize_me!
end

module SupportPDF
  extend self

  SUPPORT_PATH = Pathname.new(__dir__).join("support").freeze

  def [](arg)
    SUPPORT_PATH.join("#{arg}.pdf")
  end
end
