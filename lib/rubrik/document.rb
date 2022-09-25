# typed: true
# frozen_string_literal: true

module Rubrik
  class Document
    extend T::Sig

    Xref = T.type_alias {T::Hash[Integer, T::Hash[Symbol, T.untyped]]}

    attr_reader :xref, :root_ref, :root, :io, :obj_finder

    sig {params(obj_finder: PDF::Reader::ObjectHash).void}
    def initialize(obj_finder)
      @obj_finder = obj_finder
      @xref = @obj_finder.send(:xref).instance_variable_get(:@xref).dup.map do |id, versions|
        last_version = versions.keys.max
        offset = versions[last_version]

        [id, {offset:, modified: false, obj: nil}]
      end.to_h

      @root_ref = T.let(@obj_finder.trailer[:Root], PDF::Reader::Reference)
      @root = T.let(@obj_finder.object(@root_ref), T::Hash[Symbol, T.untyped])
      @io = @obj_finder.instance_variable_get(:@io)
    end

    sig {returns(T::Boolean)}
    def has_acroform?
      root.key?(:AcroForm)
    end

    sig {returns(PDF::Reader::Reference)}
    def build_signature_dictionary
      signature_dictionary = {
        Type: :Sig,
        Filter: :"Adobe.PPKLite",
        SubFilter: :"adbe.pkcs7.detached",
        Contents: CONTENTS_PLACEHOLDER,
        ByteRange: BYTE_RANGE_PLACEHOLDER,
      }

      signature_dictionary_id = next_id
      xref[signature_dictionary_id] = {modified: true, obj: signature_dictionary}

      PDF::Reader::Reference.new(signature_dictionary_id, 0)
    end

    sig {params(signature_dictionary: PDF::Reader::Reference).returns(PDF::Reader::Reference)}
    def build_form_field(signature_dictionary:)
      form_field = {FT: :Sig, V: signature_dictionary}

      form_field_id = next_id
      xref[form_field_id] = {modified: true, obj: form_field}

      PDF::Reader::Reference.new(form_field_id, 0)
    end

    sig {params(form_fields: T::Array[PDF::Reader::Reference]).returns(PDF::Reader::Reference)}
    def build_form(form_fields:)
      form = {Fields: form_fields, SigFlags: 3}

      form_id = next_id
      xref[form_id] = {modified: true, obj: form}

      PDF::Reader::Reference.new(form_id, 0)
    end

    def object(...)
      obj_finder.object(...)
    end

    private

    sig {returns(Integer)}
    def next_id
      T.must(xref.keys.max) + 1
    end
  end
end
