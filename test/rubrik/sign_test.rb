# frozen_string_literal: true
# typed: true

require "test_helper"

module Rubrik
  class SignTest < Minitest::Test
    def test_call
      # Arrange
      pdf_path = "test/support/simple.pdf"
      certificate = "test/support/demo_cert.pem"

      # Act
      result = Rubrik::Sign.call(pdf_path, private_key: certificate, public_key: certificate)

      # Assert
      File.open("test.pdf", "wb") do |f|
        f.write(result.read)
      end
    end
  end
end
