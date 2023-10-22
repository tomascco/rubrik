# frozen_string_literal: true
# typed: true

require "test_helper"

class Rubrik::PKCS7SignatureTest < Rubrik::Test
  def test_signature_generation
    # Arrange
    certificate_file = File.open("test/support/demo_cert.pem", "rb")

    private_key = OpenSSL::PKey::RSA.new(certificate_file, "")
    certificate_file.rewind
    certificate = OpenSSL::X509::Certificate.new(certificate_file)

    # Act
    raw_result = Rubrik::PKCS7Signature.call("test", private_key:, certificate:)

    # Assert
    result = OpenSSL::ASN1.decode(raw_result)

    assert_kind_of(OpenSSL::ASN1::Sequence, result)

    content_type = result.value.first
    assert_equal("pkcs7-signedData", content_type.value)

  ensure
    certificate_file&.close
  end
end
