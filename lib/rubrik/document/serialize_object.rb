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
          "/#{obj}"
        when Array
          serialized_objs = obj.map { |e| SerializeObject[e] }
          "[#{serialized_objs.join(" ")}]"
        when PDF::Reader::Reference
          "#{obj.id} #{obj.gen} R"
        when String
          "(#{obj})"
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
    end
  end
end
