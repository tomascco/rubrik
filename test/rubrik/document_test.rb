# frozen_string_literal: true
# typed: true

require "test_helper"

module Rubrik
  class DocumentTest < Rubrik::Test
    def test_initialize_document_without_interactive_form
      # Arrange
      input = File.open(SupportPDF["without_interactive_form"], "rb")

      # Act
      document = Document.new(input)

      # Assert
      assert_equal(input, document.send(:io))
      # FACT: the interactive form was created
      assert_equal(6, document.last_object_id)
      assert_kind_of(PDF::Reader::ObjectHash, document.objects)

      acro_form = document.modified_objects.find { |obj| obj.is_a?(Hash) && obj.dig(:value, :Type) == :Catalog }
      acro_form_reference = T.must(acro_form).dig(:value, :AcroForm)
      assert_pattern do
        document.modified_objects => [*, {id: ^acro_form_reference, value: {Fields: [], SigFlags: 3}}, *]
      end
    ensure
      input&.close
    end

    def test_initialize_document_with_interactive_form
      # Arrange
      input = File.open(SupportPDF["with_interactive_form"], "rb")

      # Act
      document = Document.new(input)

      # Assert
      assert_equal(input, document.send(:io))
      assert_equal(5, document.last_object_id)
      assert_kind_of(PDF::Reader::ObjectHash, document.objects)

      assert_pattern do
        document.modified_objects => [{
          id: PDF::Reader::Reference, value: {Fields: [], SigFlags: 3, NeedAppearances: true}
        }]
      end
    ensure
      input&.close
    end

    def test_initialize_document_with_unexpected_interactive_form_input
      # Arrange
      input = File.open(SupportPDF["unexpected_value_interactive_form"], "rb")

      # Act + Assert
      assert_raises("Expected dictionary, reference or nil but got Array on AcroForm entry.") do
        Document.new(input)
      end
    ensure
      input&.close
    end

    def test_initialize_document_with_inline_interactive_form
      # Arrange
      input = File.open(SupportPDF["inline_interactive_form"], "rb")

      # Act
      document = Document.new(input)

      # Assert
      assert_equal(input, document.send(:io))
      assert_equal(5, document.last_object_id)
      assert_kind_of(PDF::Reader::ObjectHash, document.objects)

      root_ref = PDF::Reader::Reference.new(1, 0)
      assert_pattern do
        document.modified_objects => [
          {id: PDF::Reader::Reference, value: {Fields: [], SigFlags: 3, NeedAppearances: true}},
          {id: ^root_ref, value: Hash}
        ]
      end
    ensure
      input&.close
    end

    def test_add_signature_field
      # Arrange
      input = File.open(SupportPDF["with_interactive_form"], "rb")
      document = Document.new(input)
      initial_number_of_objects = document.modified_objects.size

      # Act
      result = document.add_signature_field

      # Assert
      number_of_added_objects = document.modified_objects.size - initial_number_of_objects
      assert_equal(3, number_of_added_objects)

      assert_pattern do
        signature_value = document.modified_objects.find { _1.is_a?(Hash) && _1[:id] == result }
        signature_value => {id: ^result,
          value: {
            Type: :Sig,
            Filter: :"Adobe.PPKLite",
            SubFilter: :"adbe.pkcs7.detached",
            Contents: Document::CONTENTS_PLACEHOLDER,
            ByteRange: Document::BYTE_RANGE_PLACEHOLDER
          }
        }
      end

      signature_field = document.modified_objects.find { _1.is_a?(Hash) && _1.dig(:value, :FT) == :Sig }
      assert_pattern do
        first_page_reference = document.objects.page_references[0]
        signature_field => {
          id: PDF::Reader::Reference,
          value: {
            T: /Signature-\w{4}/,
            V: ^result,
            Type: :Annot,
            Subtype: :Widget,
            Rect: [0, 0, 0, 0],
            F: 4,
            P: ^first_page_reference
          }
        }
      end

      signature_field_id = T.must(signature_field)[:id]

      first_page = document.modified_objects.find { _1.is_a?(Hash) && _1.dig(:value, :Type) == :Page }
      assert_pattern { first_page => {value: {Annots: [*, ^signature_field_id, *]}}}

      assert_pattern { document.send(:interactive_form) => {Fields: [*, ^signature_field_id, *]} }
    ensure
      input&.close
    end

    def test_add_signature_field_with_indirect_annots
      # Arrange
      input = File.open(SupportPDF["indirect_annots"], "rb")
      document = Document.new(input)
      initial_number_of_objects = document.modified_objects.size

      # Act
      result = document.add_signature_field

      # Assert
      number_of_added_objects = document.modified_objects.size - initial_number_of_objects
      assert_equal(3, number_of_added_objects)

      assert_pattern do
        signature_value = document.modified_objects.find { _1.is_a?(Hash) && _1[:id] == result }
        signature_value => {id: ^result,
          value: {
            Type: :Sig,
            Filter: :"Adobe.PPKLite",
            SubFilter: :"adbe.pkcs7.detached",
            Contents: Document::CONTENTS_PLACEHOLDER,
            ByteRange: Document::BYTE_RANGE_PLACEHOLDER
          }
        }
      end

      signature_field = document.modified_objects.find { _1.is_a?(Hash) && _1.dig(:value, :FT) == :Sig }
      assert_pattern do
        first_page_reference = document.objects.page_references[0]
        signature_field => {
          id: PDF::Reader::Reference,
          value: {
            T: /Signature-\w{4}/,
            V: ^result,
            Type: :Annot,
            Subtype: :Widget,
            Rect: [0, 0, 0, 0],
            F: 4,
            P: ^first_page_reference
          }
        }
      end

      signature_field_id = T.must(signature_field)[:id]

      assert_pattern do
        document.modified_objects => [*, {id: PDF::Reader::Reference, value: [signature_field_id]} , *]
      end

      assert_pattern { document.send(:interactive_form) => {Fields: [*, ^signature_field_id, *]} }
    ensure
      input&.close
    end

    def test_add_signature_field_with_indirect_fields
      # Arrange
      input = File.open(SupportPDF["indirect_fields"], "rb")
      document = Document.new(input)
      initial_number_of_objects = document.modified_objects.size

      # Act
      result = document.add_signature_field

      # Assert
      number_of_added_objects = document.modified_objects.size - initial_number_of_objects
      assert_equal(4, number_of_added_objects)

      assert_pattern do
        document.modified_objects => [{id: PDF::Reader::Reference, value: {Fields: fields_ref}}, *]
        document.modified_objects => [*, {id: ^fields_ref, value: [signature_field_ref]}]
        document.modified_objects => [*, {id: ^signature_field_ref, value: {FT: :Sig}}, *]
      end
    ensure
      input&.close
    end
  end
end
