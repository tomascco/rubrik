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
      second_byte_range_offset = io.pos + SIGNATURE_SIZE
      second_length_in_bytes = io.size - second_byte_range_offset

      byte_range_array = [0, first_length_in_bytes, second_byte_range_offset, second_length_in_bytes]

      io.pos = second_byte_range_offset
      byte_array_size = T.must(io.gets("]")).size
      actual_byte_range = " /ByteRange [#{byte_range_array.join(" ")}]".ljust(byte_array_size, " ")

      io.seek(-byte_array_size, IO::SEEK_CUR)
      io.write(actual_byte_range)

      chunks_to_digest = Digest::SHA256.new

      io.pos = 0
      chunks_to_digest << T.must(io.read(first_length_in_bytes))

      io.pos = second_byte_range_offset
      chunks_to_digest << T.must(io.read(second_length_in_bytes))

      cert_file = File.open("/home/tomas/trabalho/pdf_experiment/certificate-dev.pem")
      cert = OpenSSL::X509::Certificate.new(cert_file)

      cert_file.rewind
      pkey = OpenSSL::PKey::RSA.new(cert_file)

      signature = OpenSSL::PKCS7.sign(cert, pkey, chunks_to_digest.digest, [], OpenSSL::PKCS7::BINARY).to_der

      io.pos = first_length_in_bytes
      io.write("<#{T.let(signature, String).unpack("H*").join.upcase}>")

    ensure
      T.must(io).close
      T.must(cert_file).close
    end
  end
end
