# typed: true
# frozen_string_literal: true

module Rubrik
  class Document
    module SerializeObject
      include Kernel
      extend T::Sig
      extend self

      sig {params(obj: T.untyped).returns(String)}
      def [](obj)
        case obj
        when Hash
          serialized_objs = obj.flatten.map { |e| SerializeObject[e] }
          "<<#{serialized_objs.join(" ")}>>"
        when Symbol
          serialize_symbol(obj)
        when Array
          serialized_objs = obj.map { |e| SerializeObject[e] }
          "[#{serialized_objs.join(" ")}]"
        when PDF::Reader::Reference
          "#{obj.id} #{obj.gen} R"
        when String
          serialize_string(obj)
        when TrueClass
          "true"
        when FalseClass
          "false"
        when Document::CONTENTS_PLACEHOLDER
          "<#{"0" * Document::SIGNATURE_SIZE}>"
        when Document::BYTE_RANGE_PLACEHOLDER
          "[0 0000000000 0000000000 0000000000]"
        when Float, Integer
          obj.to_s
        when NilClass
          "null"
        when PDF::Reader::Stream
          <<~OBJECT.chomp
            #{SerializeObject[obj.hash]}
            stream
            #{obj.data}
            endstream
          OBJECT
        else
          raise "Don't know how to serialize #{obj}"
        end
      end

      alias call []

      private

      STRING_ESCAPE_MAP = {
        "\n" => "\\\n",
        "\r" => "\\\r",
        "\t" => "\\\t",
        "\b" => "\\\b",
        "\f" => "\\\f",
        "\\" => "\\\\",
        "(" => "\\(",
        ")" => "\\)"
      }.freeze

      sig {params(string: String).returns(String)}
      def serialize_string(string)
        "(#{string.gsub(/[\n\r\t\b\f\\()]/n, STRING_ESCAPE_MAP)})"
      end

      DELIMITERS = "()<>[]{}/%".bytes.freeze
      REGULAR_CHARACTERS =
        "!\"\#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~".bytes.freeze


      NAME_ESCAPE_CHARACTERS = (0..255).to_a - REGULAR_CHARACTERS + DELIMITERS + "#".bytes
      NAME_ESCAPE_CHARACTERS.freeze

      NAME_ESCAPE_MAP = NAME_ESCAPE_CHARACTERS.each_with_object({}) do |char, escape_map|
        escape_map[char.chr] = "##{char.to_s(16).rjust(2, "0")}"
      end.freeze

      NAME_ESCAPE_REGEX = /[#{Regexp.escape(NAME_ESCAPE_CHARACTERS.map(&:chr).join)}]/

      sig {params(symbol: Symbol).returns(String)}
      def serialize_symbol(symbol)
        "/#{symbol.to_s.b.gsub(NAME_ESCAPE_REGEX, NAME_ESCAPE_MAP)}"
      end
    end
  end
end
