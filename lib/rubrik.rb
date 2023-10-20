# typed: true
# frozen_string_literal: true

require "sorbet-runtime"
require "pdf-reader"

module Rubrik
  class Error < StandardError; end
end

require_relative "rubrik/document"
require_relative "rubrik/document/increment"
require_relative "rubrik/document/serialize_object"
require_relative "rubrik/fill_signature"
require_relative "rubrik/sign"
