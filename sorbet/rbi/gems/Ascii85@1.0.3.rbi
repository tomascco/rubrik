# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `Ascii85` gem.
# Please instead update this file by running `bin/tapioca gem Ascii85`.

# source://Ascii85//lib/ascii85.rb#17
module Ascii85
  class << self
    # Searches through +str+ and decodes the _first_ Ascii85-String found.
    #
    # #decode expects an Ascii85-encoded String enclosed in <~ and ~> — it will
    # ignore all characters outside these markers. The returned strings are always
    # encoded as ASCII-8BIT.
    #
    #     Ascii85.decode("<~;KZGo~>")
    #     => "Ruby"
    #
    #     Ascii85.decode("Foo<~;KZGo~>Bar<~;KZGo~>Baz")
    #     => "Ruby"
    #
    #     Ascii85.decode("No markers")
    #     => ""
    #
    # #decode will raise Ascii85::DecodingError when malformed input is
    # encountered.
    #
    # source://Ascii85//lib/ascii85.rb#124
    def decode(str); end

    # Encodes the bytes of the given String as Ascii85.
    #
    # If +wrap_lines+ evaluates to +false+, the output will be returned as
    # a single long line. Otherwise #encode formats the output into lines
    # of length +wrap_lines+ (minimum is 2).
    #
    #     Ascii85.encode("Ruby")
    #     => <~;KZGo~>
    #
    #     Ascii85.encode("Supercalifragilisticexpialidocious", 15)
    #     => <~;g!%jEarNoBkD
    #        BoB5)0rF*),+AU&
    #        0.@;KXgDe!L"F`R
    #        ~>
    #
    #     Ascii85.encode("Supercalifragilisticexpialidocious", false)
    #     => <~;g!%jEarNoBkDBoB5)0rF*),+AU&0.@;KXgDe!L"F`R~>
    #
    # source://Ascii85//lib/ascii85.rb#39
    def encode(str, wrap_lines = T.unsafe(nil)); end
  end
end

# This error is raised when Ascii85.decode encounters one of the following
# problems in the input:
#
# * An invalid character. Valid characters are '!'..'u' and 'z'.
# * A 'z' character inside a 5-tuple. 'z's are only valid on their own.
# * An invalid 5-tuple that decodes to >= 2**32
# * The last tuple consisting of a single character. Valid tuples always have
#   at least two characters.
#
# source://Ascii85//lib/ascii85.rb#227
class Ascii85::DecodingError < ::StandardError; end
