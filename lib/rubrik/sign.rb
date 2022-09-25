# typed: true
# frozen_string_literal: true

require "openssl"

module Rubrik
  module Sign
    extend T::Sig
    extend self

    sig {params(path: T.any(String, Pathname)).void}
    def call(path)
      io = File.open(path, mode: "r+b")

      io.gets("/Type /Sig")
      io.gets("/Contents ")

      first_length_in_bytes = io.pos
      second_byte_range_offset = first_length_in_bytes + SIGNATURE_SIZE
      second_length_in_bytes = io.size - second_byte_range_offset

      byte_range_array = [0, first_length_in_bytes, second_byte_range_offset, second_length_in_bytes]

      io.pos = second_byte_range_offset
      byte_array_size = T.must(io.gets("]")).size
      actual_byte_range = " /ByteRange [#{byte_range_array.join(" ")}]".ljust(byte_array_size, " ")

      io.seek(-byte_array_size, IO::SEEK_CUR)
      io.write(actual_byte_range)

      io.pos = 0
      data_to_sign = T.must(io.read(first_length_in_bytes))

      io.pos = second_byte_range_offset
      data_to_sign += T.must(io.read(second_length_in_bytes))

      cert_file = File.read("utils/demo_cert.pem")
      cert = OpenSSL::X509::Certificate.new(cert_file)
      pkey = OpenSSL::PKey::RSA.new(cert_file, "1234")

      signature = OpenSSL::PKCS7.sign(cert, pkey, data_to_sign, [],
                                      OpenSSL::PKCS7::DETACHED | OpenSSL::PKCS7::BINARY).to_der

      hex_signature = T.let(signature, String).unpack1("H*")

      padded_contents_field = "<#{hex_signature.ljust(SIGNATURE_SIZE - 2, "0")}>"

      io.pos = first_length_in_bytes
      io.write(padded_contents_field)
    ensure
      T.must(io).close
    end
  end
end
