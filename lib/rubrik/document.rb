# typed: true
# frozen_string_literal: true

require "securerandom"

module Rubrik
  class Document
    extend T::Sig

    CONTENTS_PLACEHOLDER = Object.new.freeze
    BYTE_RANGE_PLACEHOLDER = Object.new.freeze
    SIGNATURE_SIZE = 8_192

    sig {returns(T.any(File, Tempfile, StringIO))}
    attr_reader :io

    sig {returns(PDF::Reader::ObjectHash)}
    attr_reader :objects

    sig {returns(T::Array[{id: PDF::Reader::Reference, value: T.untyped}])}
    attr_reader :modified_objects

    sig {returns(PDF::Reader::Reference)}
    attr_reader :interactive_form_id

    sig {returns(Integer)}
    attr_reader :last_object_id

    sig {params(input: T.any(File, Tempfile, StringIO)).void}
    def initialize(input)
      self.io = input
      self.objects = PDF::Reader::ObjectHash.new(input)
      self.last_object_id = objects.size
      self.modified_objects = []

      fetch_or_create_interactive_form!
    end

    sig {void}
    def add_signature_field
      # create signature value dictionary
      signature_value_id = assign_new_object_id!
      modified_objects << {
        id: signature_value_id,
        value: {
          Type: :Sig,
          Filter: :"Adobe.PPKLite",
          SubFilter: :"adbe.pkcs7.detached",
          Contents: CONTENTS_PLACEHOLDER,
          ByteRange: BYTE_RANGE_PLACEHOLDER
        }
      }

      first_page_reference = T.must(objects.page_references[0])

      # create signature field
      signature_field_id = assign_new_object_id!
      modified_objects << {
        id: signature_field_id,
        value: {
          T: "Signature-#{SecureRandom.hex(2)}",
          FT: :Sig,
          V: signature_value_id,
          Type: :Annot,
          Subtype: :Widget,
          Rect: [20, 20, 120, 120],
          F: 4,
          P: first_page_reference
        }
      }

      modified_page = objects.fetch(first_page_reference).dup
      (modified_page[:Annots] ||= []) << signature_field_id

      modified_objects << {id: first_page_reference, value: modified_page}

      (interactive_form[:Fields] ||= []) << signature_field_id
    end

    private

    sig {returns(T::Hash[Symbol, T.untyped])}
    def interactive_form
      T.must(modified_objects.first).fetch(:value)
    end

    sig {void}
    def fetch_or_create_interactive_form!
      root_ref = objects.trailer[:Root]
      root = T.let(objects.fetch(root_ref), Hash)

      if root.key?(:AcroForm)
        form_id = root[:AcroForm]

        modified_objects << {id: form_id, value: objects.fetch(form_id).dup}
      else
        interactive_form_id = assign_new_object_id!
        modified_objects << {id: interactive_form_id, value: {Fields: []}}

        # we also need to create a new version of the document catalog to include the new form ref
        updated_root = root.dup
        updated_root[:AcroForm] = interactive_form_id

        modified_objects << {id: root_ref, value: updated_root}
      end

      interactive_form[:SigFlags] = 3 # dont modify, append only
    end

    sig {returns(PDF::Reader::Reference)}
    def assign_new_object_id!
      PDF::Reader::Reference.new(self.last_object_id += 1, 0)
    end

    sig {params(io: T.any(File, Tempfile, StringIO)).returns(T.any(File, Tempfile, StringIO))}
    attr_writer :io

    sig {params(objects: PDF::Reader::ObjectHash).returns(PDF::Reader::ObjectHash)}
    attr_writer :objects

    sig {params(modified_objects: T::Array[{id: PDF::Reader::Reference, value: T.untyped}]).returns(T::Array[{id: PDF::Reader::Reference, value: T.untyped}])}
    attr_writer :modified_objects

    sig {params(last_object_id: Integer).returns(Integer)}
    attr_writer :last_object_id
  end
end
