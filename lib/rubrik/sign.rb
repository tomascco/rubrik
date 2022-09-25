# typed: true
# frozen_string_literal: true

module Rubrik
  module Sign
    extend T::Sig

    sig {params(
           input: T.any(IO, Tempfile, StringIO, String),
           private_key: T.any(String, Pathname, File, StringIO, Tempfile, OpenSSL::PKey::RSA),
           public_key: T.any(String, Pathname, File, StringIO, Tempfile, OpenSSL::X509::Certificate),
           password: String,
           certificate_chain: T::Array[OpenSSL::X509::Certificate])
         .returns(T.any(File, StringIO, Tempfile))}
    def self.call(input, private_key:, public_key:, password: "", certificate_chain: [])
      document = Rubrik::AddSignatureObjects.call(input)
      ready_to_sign_pdf_io = Rubrik::RebuildDocument.call(document)

      Rubrik::FillSignature.call(ready_to_sign_pdf_io,
                                 private_key:, public_key:, password:, certificate_chain:)
    end
  end
end
