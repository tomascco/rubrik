# typed: true

class IO
  sig do
    params(
        src: T.any(String, IO, Tempfile, StringIO),
        dst: T.any(String, IO, Tempfile, StringIO),
        copy_length: Integer,
        src_offset: Integer,
    )
    .returns(Integer)
  end
  def self.copy_stream(src, dst, copy_length = T.unsafe(nil), src_offset = T.unsafe(nil)); end
end
