# frozen_string_literal: true
# typed: true

require "test_helper"
require "stringio"

module Rubrik
  class SignTest < Minitest::Test
    def test_call
      # Arrange
      input_pdf = File.open("test/support/simple.pdf", "rb")
      output_pdf = StringIO.new
      certificate = File.open("test/support/demo_cert.pem", "rb")

      private_key = OpenSSL::PKey::RSA.new(certificate, "")
      certificate.rewind
      public_key = OpenSSL::X509::Certificate.new(certificate)

      # Act
      Sign.call(input_pdf, output_pdf, private_key:, public_key:)

      # Assert
      output_pdf.rewind

      output_pdf.close
      input_pdf.close
      certificate.close
    end
  end
end
