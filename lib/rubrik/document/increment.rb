# typed: true
# frozen_string_literal: true

module Rubrik
  class Document
    module Increment
      include Kernel

      extend T::Sig
      extend self

      sig {params(document: Rubrik::Document, io: T.any(File, Tempfile, StringIO)).void}
      def call(document, io:)
        document.io.rewind
        IO.copy_stream(document.io, io)

        io << "\n"

        new_xref = T.let([], T::Array[T::Hash[Symbol, Integer]])
        new_xref << {id: 0}

        document.modified_objects.each do |object|
          integer_id = T.let(object[:id].to_i, Integer)
          new_xref << {id: integer_id, offset: io.pos}

          value = object[:value]
          io << "#{integer_id} 0 obj\n" "#{SerializeObject[value]}\n" "endobj\n\n"
        end

        updated_trailer = document.objects.trailer.dup
        updated_trailer[:Prev] = last_xref_pos(document)
        updated_trailer[:Size] = document.last_object_id + 1

        new_xref_pos = io.pos

        new_xref_subsections = new_xref
          .sort_by { |entry| entry.fetch(:id) }
          .chunk_while {  _1.fetch(:id) + 1 == _2[:id] }

        io << "xref\n"

        new_xref_subsections.each do |subsection|
          starting_id = T.must(subsection.first).fetch(:id)
          length = subsection.length

          io << "#{starting_id} #{length}\n"

          if starting_id.zero?
            io << "0000000000 65535 f\n"
            subsection.shift
          end

          subsection.each { |entry| io << "#{format("%010d", entry[:offset])} 00000 n\n" }
        end

        io << "trailer\n"
        io << "#{SerializeObject[updated_trailer]}\n"
        io << "startxref\n"
        io << "#{new_xref_pos.to_s}\n"
        io << "%%EOF\n"
      end

      private

      sig {params(document: Rubrik::Document).returns(Integer)}
      def last_xref_pos(document)
        PDF::Reader::Buffer.new(document.io, seek: 0).find_first_xref_offset
      end
    end
  end
end
