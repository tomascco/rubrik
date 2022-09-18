# typed: true
# frozen_string_literal: true

require "bundler"
Bundler.setup(:default)

require "sorbet-runtime"
require "pdf-reader"
require "debug"

module Rubrik
  CONTENTS_PLACEHOLDER = Object.new.freeze
  BYTE_RANGE_PLACEHOLDER = Object.new.freeze
  SIGNATURE_SIZE = 8_192
end

require_relative "rubrik/document"
require_relative "rubrik/add_signature_objects"
require_relative "rubrik/rebuild_document"
