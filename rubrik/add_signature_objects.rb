# typed: true
# frozen_string_literal: true

module Rubrik
  module AddSignatureObjects
    extend T::Sig
    extend self

    sig {params(path: T.any(IO, Tempfile, StringIO, String)).returns(Rubrik::Document)}
    def call(path)
      document = Rubrik::Document.new(PDF::Reader::ObjectHash.new(path))

      signature_dictionary = document.build_signature_dictionary
      form_field = document.build_form_field(signature_dictionary: signature_dictionary)

      if document.has_acroform?
        acroform_entry = document.root[:AcroForm]

        case acroform_entry
        when PDF::Reader::Reference
          form_id = acroform_entry.id

          document.xref[form_id][:modified] = true

          form = document.object(acroform_entry).dup

          form[:Fields] << form_field
          form[:SigFlags] = 3

          document.xref[form_id][:obj] = form
        when Hash
          form = acroform_entry.dup

          form[:Fields] << form_field
          form[:SigFlags] = 3

          modified_root = document.root.dup
          modified_root[:AcroForm] = form

          root_id = document.root.id

          document.xref[root_id][:modified] = true
          document.xref[root_id][:obj] = modified_root
        end
      else
        document.build_form(form_fields: form_field.to_a)
      end

      document
    end
  end
end
