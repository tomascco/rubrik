# typed: true
# frozen_string_literal: true

module Rubrik
  module RebuildDocument
    include Kernel

    extend T::Sig
    extend self

    sig {params(document: Rubrik::Document).returns(StringIO)}
    def call(document)
      rebuilt_document = StringIO.new
      new_xref = []

      rebuilt_document << "%PDF-#{document.obj_finder.pdf_version}\n"

      document.xref.each do |id, metadata|
        new_xref << {id:, offset: rebuilt_document.pos}

        if metadata[:modified]
          rebuilt_document << "#{id} 0 obj\n" "#{serialize(metadata[:obj])}\n" "endobj\n"
        else
          document.io.seek(metadata[:offset], IO::SEEK_SET)
          loop do
            current_line = document.io.readline
            rebuilt_document << current_line

            break if current_line.include?("endobj")
          end
        end
      end

      xref_pos = rebuilt_document.pos

      rebuilt_document << "xref\n"
      rebuilt_document << "0 #{new_xref.size}\n"
      rebuilt_document << "0000000000 65535 f\n"
      new_xref.each do |entry|
        rebuilt_document << "#{format("%010d", entry[:offset])} 00000 n\n"
      end
      rebuilt_document << "trailer\n"
      rebuilt_document << "#{serialize(document.obj_finder.trailer)}\n"
      rebuilt_document << "startxref\n"
      rebuilt_document << "#{xref_pos.to_s}\n"
      rebuilt_document << "%%EOF\n"

      rebuilt_document.rewind
      rebuilt_document
    end

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
      when CONTENTS_PLACEHOLDER
        "\x00" * SIGNATURE_SIZE
      when BYTE_RANGE_PLACEHOLDER
        "[0 ********** ********** **********]"
      when Integer
        obj.to_s
      else
        raise NotImplementedError.new("Don't know how to serialize #{obj}")
      end
    end
  end
end
