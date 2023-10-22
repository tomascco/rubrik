# typed: true
# frozen_string_literal: true

require "openssl"

module Rubrik
  module PKCS7Signature
    extend T::Sig
    extend self

    OPEN_SSL_FLAGS = OpenSSL::PKCS7::DETACHED | OpenSSL::PKCS7::BINARY

    sig {params(
        data: String,
        private_key: OpenSSL::PKey::RSA,
        certificate: OpenSSL::X509::Certificate,
        certificate_chain: T::Array[OpenSSL::X509::Certificate]
      ).returns(String)
    }
    def call(data, private_key:, certificate:, certificate_chain: [])
      OpenSSL::PKCS7.sign(certificate, private_key, data, certificate_chain, OPEN_SSL_FLAGS).to_der
    end
  end
end
