# typed: true
# frozen_string_literal: true

module Rubrik
  module FillSignature
    extend T::Sig
    extend self
    include Kernel

    sig {params(
          io: T.any(File, StringIO, Tempfile),
          signature_value_ref: PDF::Reader::Reference,
          private_key: OpenSSL::PKey::RSA,
          certificate: OpenSSL::X509::Certificate,
          certificate_chain: T::Array[OpenSSL::X509::Certificate])
        .void}

    FIRST_OFFSET = 0

    def call(io, signature_value_ref:, private_key:, certificate:, certificate_chain: [])
      io.rewind

      signature_value_offset = PDF::Reader::XRef.new(io)[signature_value_ref]

      io.pos = signature_value_offset
      io.gets("/Contents")
      io.gets("<")

      first_length = io.pos - 1
      # We need to sum +2 to account for "<" and ">" of the hex string
      second_offset = first_length + Document::SIGNATURE_SIZE + 2
      second_length = io.size - second_offset

      byte_range_array = [FIRST_OFFSET, first_length, second_offset, second_length]

      io.pos = signature_value_offset

      io.gets("/ByteRange")
      byte_range_start = io.pos - "/ByteRange".size

      io.gets("]")
      byte_range_end = io.pos

      byte_range_size = byte_range_end - byte_range_start + 1
      actual_byte_range = " /ByteRange [#{byte_range_array.join(" ")}]".ljust(byte_range_size, " ")

      io.seek(-byte_range_size, IO::SEEK_CUR)
      io.write(actual_byte_range)

      io.pos = FIRST_OFFSET
      data_to_sign = T.must(io.read(first_length))

      io.pos = second_offset
      data_to_sign += T.must(io.read(second_length))

      signature = PKCS7Signature.call(data_to_sign, private_key:, certificate:)
      hex_signature = T.let(signature, String).unpack1("H*")

      padded_contents_field = "<#{hex_signature.ljust(Document::SIGNATURE_SIZE, "0")}>"

      io.pos = first_length
      io.write(padded_contents_field)

      io.rewind
      io
    end
  end
end
