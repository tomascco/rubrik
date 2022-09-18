# typed: true
# frozen_string_literal: true

require "bundler"
Bundler.setup(:default)

require "debug"
require "sorbet-runtime"

class PDF
  class Object
    extend T::Sig

    sig {params(io: File, offset: Integer).returns(PDF::Object)}
    def self.build_from(io, offset:)
      io.seek(offset, IO::SEEK_SET)

      first_line = io.readline
      first_line.match(/(\d+) (\d+) obj/).captures.map(&:to_i) => [id, generation_number]

      obj_lines = []
      loop do
        current_line = io.readline
        break if current_line.include?("endobj")

        obj_lines << current_line
      end
      obj_string = obj_lines.join

      end_index = obj_string.index(">>")

      cleaned_obj_string = obj_string[2...end_index].gsub(/[\x00\t\n\f\r]+/, " ").strip

      separeted_fields = cleaned_obj_string.split("/")[1..].map { |s| s.split(" ", 2) }
      binding.b
      fields = separeted_fields.to_h.transform_keys(&:to_sym).transform_values(&:strip)

      new(id, generation_number, fields)
    end

    def initialize(id, generation_number, fields)
      @id = id
      @generation_number = generation_number
      @fields = fields
    end

    private

    attr_reader :id, :generation_number
  end
end

pdf_io = File.open("../../Documentos/documento_Doc-1643.pdf", "rb")
obj = PDF::Object.build_from(pdf_io, offset: 68497)
binding.b
