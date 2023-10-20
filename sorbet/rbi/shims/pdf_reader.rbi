# typed: true

class PDF::Reader::ObjectHash
  sig { returns(T::Array[PDF::Reader::Reference]) }
  def page_references; end
end
