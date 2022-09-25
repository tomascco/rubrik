# typed: true
# frozen_string_literal: true

require "openssl"

module Rubrik
  module FillSignature
    extend T::Sig
    extend self
    include Kernel

    sig {params(
          input: T.any(String, Pathname, IO, StringIO, Tempfile),
          private_key: T.any(String, Pathname, File, StringIO, Tempfile, OpenSSL::PKey::RSA),
          public_key: T.any(String, Pathname, File, StringIO, Tempfile, OpenSSL::X509::Certificate),
          password: String,
          certificate_chain: T::Array[OpenSSL::X509::Certificate])
        .returns(T.any(File, StringIO, Tempfile))}
    def call(input, private_key:, public_key:, password: "", certificate_chain: [])
      io = convert_input_to_io(input)
      io.rewind

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

      pkey = convert_input_to_private_key(private_key, password)
      pubkey = convert_input_to_public_key(public_key)

      signature = OpenSSL::PKCS7.sign(pubkey, pkey, data_to_sign, certificate_chain,
                                      OpenSSL::PKCS7::DETACHED | OpenSSL::PKCS7::BINARY).to_der
      hex_signature = T.let(signature, String).unpack1("H*")

      padded_contents_field = "<#{hex_signature.ljust(SIGNATURE_SIZE - 2, "0")}>"

      io.pos = first_length_in_bytes
      io.write(padded_contents_field)

      io.rewind
      io
    end

    private

    sig {params(input: T.any(String, Pathname, IO, StringIO, Tempfile, File))
         .returns(T.any(File, StringIO, Tempfile))}
    def convert_input_to_io(input)
      case input
      when String, Pathname
        string_io = StringIO.new
        file = File.new(input, mode: "rb")

        IO.copy_stream(file, T.unsafe(string_io))

        string_io
      when File, StringIO, Tempfile
        input
      else
        raise NotImplementedError.new("Can't convert #{input} to IO")
      end
    end

    sig {params(input: T.any(String, Pathname, File, StringIO, Tempfile, OpenSSL::PKey::RSA), password: String)
         .returns(OpenSSL::PKey::RSA)}
    def convert_input_to_private_key(input, password)
      case input
      when String
        File.open(input, mode: "rb") do |cert|
          OpenSSL::PKey::RSA.new(cert, password)
        end
      when IO, StringIO, Tempfile
        input.rewind
        OpenSSL::PKey::RSA.new(input, password)
      when OpenSSL::PKey::RSA
        input
      else
        raise NotImplementedError.new("Can't convert #{input} to IO")
      end
    end

    sig {params(input: T.any(String, Pathname, File, StringIO, Tempfile, OpenSSL::X509::Certificate))
      .returns(OpenSSL::X509::Certificate)}
    def convert_input_to_public_key(input)
      case input
      when String
        File.open(input, mode: "rb") do |cert|
          OpenSSL::X509::Certificate.new(cert)
        end
      when IO, StringIO, Tempfile
        input.rewind
        OpenSSL::X509::Certificate.new(input)
      when OpenSSL::X509::Certificate
        input
      else
        raise NotImplementedError.new("Can't convert #{input} to IO")
      end
    end
  end
end
