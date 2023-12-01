# frozen_string_literal: true
# typed: true

require "test_helper"

class Rubrik::Document
  class SerializeObjectTest < Rubrik::Test
    def test_hash_serialization
      # Arrange
      hash = {Test: {Key: :Value, Array: []}}

      # Act
      result = SerializeObject[hash]

      # Assert
      assert_equal("<</Test <</Key /Value /Array []>>>>", result)
    end

    def test_symbol_serialization
      # Act
      result = SerializeObject[:Test]

      # Assert
      assert_equal("/Test", result)
    end

    def test_array_serialization
      # Arrange
      array = [0, [PDF::Reader::Reference.new(1, 0), {Key: :Value}]]

      # Act
      result = SerializeObject[array]

      # Assert
      assert_equal("[0 [1 0 R <</Key /Value>>]]", result)
    end

    def test_reference_serialization
      # Act
      result = SerializeObject[PDF::Reader::Reference.new(2, 1)]

      # Assert
      assert_equal("2 1 R", result)
    end

    def test_string_serialization
      # Act + Assert
      [
        ["(Test)", "Test"],
        ["(Test\\))", "Test)"],
        ["(Test\\\n)", "Test\n"],
        ["(hello \\\f\\\b hi)", "hello \f\b hi"],
        ["(This is \\(\\)n inverted backslash \\\\)", "This is ()n inverted backslash \\"],
        ["(Really \\(\\) \\\r\\\n complicated\\\ttest)", "Really () \r\n complicated\ttest"]
      ].each do |(expected, subject)|
        assert_equal(expected, SerializeObject[subject])
      end
    end

    def test_booleans_serialization
      # Assert
      assert_equal("true", SerializeObject[true])
      assert_equal("false", SerializeObject[false])
    end

    def test_contents_placeholder_serialization
      # Assert
      expected_result = "<#{"0" * 8_192}>"
      assert_equal(expected_result, SerializeObject[CONTENTS_PLACEHOLDER])
    end

    def test_byte_range_placeholder_serialization
      # Assert
      assert_equal("[0 0000000000 0000000000 0000000000]", SerializeObject[BYTE_RANGE_PLACEHOLDER])
    end

    def test_numeric_serialization
      # Assert
      [
        ["30", SerializeObject.call(30)],
        ["-30", SerializeObject.call(-30)],
        ["-1.5", SerializeObject.call(-1.5)],
        ["3.3", SerializeObject.call(3.3)]
      ].each { |expectation| assert_equal(*expectation) }
    end

    def test_nil_serialization
      # Assert
      assert_equal("null", SerializeObject[nil])
    end

    def test_stream_serialization
      # Arrange
      data = "Test Text\nTest x\x9C\xBDX[o\u00147\u0014\xB6\xB4HH\xF3\u0002)"
      stream = PDF::Reader::Stream.new({Length: data.bytesize}, data)

      # Act
      result = SerializeObject[stream]

      # Assert
      assert_equal(<<~STREAM.chomp, result)
        <</Length 31>>
        stream
        #{data}
        endstream
      STREAM
    end

    def test_raise_on_unknown_object_serialization
      # Assert
      assert_raises(RuntimeError, "Don't know how to serialize Object") do
        SerializeObject[Object.new]
      end
    end
  end
end
