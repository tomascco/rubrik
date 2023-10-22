# frozen_string_literal: true
# typed: true

require "test_helper"

module Rubrik
  class SignTest < Rubrik::Test
    def test_document_with_interactive_form
      # Arrange
      input_pdf = File.open(SupportPDF["with_interactive_form"], "rb")
      output_pdf = StringIO.new
      certificate_file = File.open("test/support/demo_cert.pem", "rb")

      private_key = OpenSSL::PKey::RSA.new(certificate_file, "")
      certificate_file.rewind
      certificate = OpenSSL::X509::Certificate.new(certificate_file)

      # Act
      Sign.call(input_pdf, output_pdf, private_key:, certificate:)

      # Assert
      expected_output = File.open(SupportPDF["with_interactive_form.expected"], "rb")

      expected_output.readlines.zip(output_pdf.readlines).each do |(expected_line, actual_line)|
        # We must erase the signature because it is timestampped
        if actual_line&.match?("/Type /Sig")
          actual_line.sub!(/<[a-f0-9]+>/, "")
          expected_line.sub!(/<[a-f0-9]+>/, "")
        # The signature field name is also random
        elsif actual_line&.match?(/Signature-[a-f0-9]{4}/)
          actual_line.sub!(/Signature-[a-f0-9]{4}/, "")
          expected_line.sub!(/Signature-[a-f0-9]{4}/, "")
        end

        assert_equal(expected_line, actual_line)
        end
    ensure
      certificate_file&.close
      output_pdf&.close
      input_pdf&.close
      expected_output&.close
    end

    def test_document_without_interactive_form
      # Arrange
      input_pdf = File.open(SupportPDF["without_interactive_form"], "rb")
      output_pdf = StringIO.new
      certificate_file = File.open("test/support/demo_cert.pem", "rb")

      private_key = OpenSSL::PKey::RSA.new(certificate_file, "")
      certificate_file.rewind
      certificate = OpenSSL::X509::Certificate.new(certificate_file)

      # Act
      Sign.call(input_pdf, output_pdf, private_key:, certificate:)

      # Assert
      expected_output = File.open(SupportPDF["without_interactive_form.expected"], "rb")

      expected_output.readlines.zip(output_pdf.readlines).each do |(expected_line, actual_line)|
        # We can't verify the signature because it changes on every run
        if actual_line&.match?("/Type /Sig")
          actual_line.sub!(/<[a-f0-9]+>/, "")
          expected_line.sub!(/<[a-f0-9]+>/, "")
        # The signature field name is also random
        elsif actual_line&.match?(/Signature-[a-f0-9]{4}/)
          actual_line.sub!(/Signature-[a-f0-9]{4}/, "")
          expected_line.sub!(/Signature-[a-f0-9]{4}/, "")
        end

        assert_equal(expected_line, actual_line)
      end
    ensure
      certificate_file&.close
      output_pdf&.close
      input_pdf&.close
      expected_output&.close
    end
  end
end
