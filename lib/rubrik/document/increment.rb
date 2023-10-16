# typed: true
# frozen_string_literal: true

module Rubrik
  class Document
    module Increment
      include Kernel

      extend T::Sig
      extend self

      sig {params(document: Rubrik::Document, io: T.any(File, Tempfile, StringIO)).returns(T.any(File, Tempfile, StringIO))}
      def call(document, io:)
        document.io.rewind
        IO.copy_stream(T.unsafe(document.io), T.unsafe(io))

        io << "\n"
        new_xref = Array.new

        document.modified_objects.each do |object|
          integer_id = T.let(object[:id].to_i, Integer)
          new_xref << {id: integer_id, offset: io.pos}

          io << "#{integer_id} 0 obj\n" "#{serialize(object[:value])}\n" "endobj\n\n"
        end

        updated_trailer = document.objects.trailer.dup
        updated_trailer[:Prev] = last_xref_pos(document)
        updated_trailer[:Size] = document.last_object_id + 1

        new_xref_pos = io.pos

        new_xref_subsections = new_xref
          .sort_by { _1[:id] }
          .chunk_while { _1[:id] + 1 == _2[:id] }

        io << "xref\n"
        io << "0 1\n"
        io << "0000000000 65535 f\n"

        new_xref_subsections.each do |subsection|
          starting_id = subsection.first[:id]
          length = subsection.length

          io << "#{starting_id} #{length}\n"
          subsection.each { |entry| io << "#{format("%010d", entry[:offset])} 00000 n\n" }
        end

        io << "trailer\n"
        io << "#{serialize(updated_trailer)}\n"
        io << "startxref\n"
        io << "#{new_xref_pos.to_s}\n"
        io << "%%EOF\n"

        io.rewind
        io
      end

      private

      sig {params(obj: T.untyped).returns(String)}
      def serialize(obj)
        case obj
        when Hash
          serialized_objs = obj.flatten.map { |e| serialize(e) }
          "<<#{serialized_objs.join(" ")}>>"
        when Symbol
          "/#{obj}"
        when Array
          serialized_objs = obj.map { |e| serialize(e) }
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
        when Numeric
          obj.to_s
        when NilClass
          "null"
        when PDF::Reader::Stream
          <<~OBJECT.chomp
            #{serialize(obj.hash)}
            stream
            #{obj.data}
            endstream
          OBJECT
        else
          raise NotImplementedError.new("Don't know how to serialize #{obj}")
        end
      end

      sig {params(document: Rubrik::Document).returns(Integer)}
      def last_xref_pos(document)
        PDF::Reader::Buffer.new(document.io, seek: 0).find_first_xref_offset
      end
    end
  end
end
