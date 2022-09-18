# typed: true
# frozen_string_literal: true

require "bundler"
Bundler.setup(:default)

require "debug"
require "sorbet-runtime"

TOLERANCE_OFFSET = 5000

class PDF
  extend T::Sig

  sig {params(io: File).void}
  def initialize(io)
    @io = io
    xref_offset = find_xref_offset

    @ref_table, @trailer = parse_xref_table_and_trailer(xref_offset)
  end


  private

  attr_reader :io, :ref_table, :trailer


  sig {params(xref_offset: Integer).returns([T::Array[T::Hash[Symbol, Integer]], T::Hash[Symbol, String]])}
  def parse_xref_table_and_trailer(xref_offset)
    io.seek(xref_offset, IO::SEEK_SET)
    io.readline

    start_at, entries = (io.readline.scan(/\d+/).flatten.map(&:to_i))
    xref_info = {start_at:, entries:}
    xref_table = Array.new(xref_info[:entries]) do |index|
      offset, generation_number = io.readline.scan(/\d+/).flatten.map(&:to_i)

      {id: xref_info[:start_at] + index , offset:, generation_number:}
    end

    trailer_offset = io.pos

    io.readline # => "trailer\n"
    trailer = []
    loop do
      current_line = io.readline
      trailer << current_line

      break if current_line.include?(">>")
    end

    cleaned_trailer = trailer.join.delete_prefix("trailer").delete("<>").gsub(/[\x00\t\n\f\r]+/, " ").strip.delete_prefix("/")

    trailer = cleaned_trailer.split("/").map { |s| s.split(" ", 2) }.to_h.transform_keys(&:to_sym)

    [xref_table, trailer]
  end

  sig {returns(Integer)}
  def find_xref_offset
    backward_read_offset = [io.size, TOLERANCE_OFFSET].min
    io.seek(-backward_read_offset, IO::SEEK_END)

    T.must(io.read).split(/[\n\r]+/) => [*, xref_offset, "%%EOF", *]

    Integer(xref_offset)
  end
end

pdf_io = File.open("../../Documentos/documento_Doc-1643.pdf", "rb")
document = PDF.new(pdf_io)
binding.b
