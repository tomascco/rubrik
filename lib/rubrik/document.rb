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
    attr_accessor :io

    sig {returns(PDF::Reader::ObjectHash)}
    attr_accessor :objects

    sig {returns(Integer)}
    attr_accessor :first_free_object_id

    sig {returns(T::Array[{id: PDF::Reader::Reference, value: T.untyped}])}
    attr_accessor :modified_objects

    sig {returns(Integer)}
    attr_accessor :last_object_id

    private :io=, :objects=, :first_free_object_id=, :modified_objects=, :last_object_id=

    sig {params(input: T.any(File, Tempfile, StringIO)).void}
    def initialize(input)
      self.io = input
      self.objects = PDF::Reader::ObjectHash.new(input)

      self.last_object_id = objects.trailer[:Size] - 1
      self.first_free_object_id = find_first_free_object_id

      self.modified_objects = []

      fetch_or_create_interactive_form!
    end

    sig {returns(PDF::Reader::Reference)}
    # Returns the reference of the Signature Value dictionary.
    def add_signature_field
      # To add an signature to the PDF, we need the following structure
      # Interactive Form -> Signature Field -> Signature Value
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
          Rect: [0, 0, 0, 0],
          F: 4,
          P: first_page_reference
        }
      }

      first_page = objects.fetch(first_page_reference)
      annots = first_page[:Annots]

      if annots.is_a?(PDF::Reader::Reference)
        new_annots = objects.fetch(annots).dup
        new_annots << signature_field_id

        modified_objects << {id: annots, value: new_annots}
      else
        new_first_page = first_page.dup
        (new_first_page[:Annots] ||= []) << signature_field_id

        modified_objects << {id: first_page_reference, value: new_first_page}
      end

      (interactive_form[:Fields] ||= []) << signature_field_id

      signature_value_id
    end

    private

    sig {returns(T::Hash[Symbol, T.untyped])}
    def interactive_form
      T.must(modified_objects.first).fetch(:value)
    end

    sig{returns(Integer)}
    def find_first_free_object_id
      return 0 if last_object_id == objects.size

      xref = objects.send(:xref).instance_variable_get(:@xref)
      missing_ids = (1..last_object_id).to_a - xref.keys

      T.must(missing_ids.min)
    end

    sig {void}
    def fetch_or_create_interactive_form!
      root_ref = objects.trailer[:Root]
      root = T.let(objects.fetch(root_ref), T::Hash[Symbol, T.untyped])

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
  end
end
