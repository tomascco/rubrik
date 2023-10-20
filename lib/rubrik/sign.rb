# typed: true
# frozen_string_literal: true

module Rubrik
  module Sign
    extend T::Sig

    sig {params(
           input: T.any(File, Tempfile, StringIO),
           output: T.any(File, Tempfile, StringIO),
           private_key: OpenSSL::PKey::RSA,
           public_key: OpenSSL::X509::Certificate,
           certificate_chain: T::Array[OpenSSL::X509::Certificate])
         .void}
    def self.call(input, output, private_key:, public_key:, certificate_chain: [])
      input.binmode
      output.reopen(T.unsafe(output), "wb+") if !output.is_a?(StringIO)

      document = Rubrik::Document.new(input)

      document.add_signature_field

      Document::Increment.call(document, io: output)

      signature_value = T.must(document.modified_objects.find { _1.dig(:value, :Type) == :Sig })

      signature_value_ref = T.let(signature_value[:id], PDF::Reader::Reference)
      FillSignature.call(output, signature_value_ref:, private_key:, public_key:, certificate_chain:)
    end
  end
end
