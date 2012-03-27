require 'includes'

# Makes @file writable so it can be replaced with StringIO for testing
class StringCachingWriter < WaveFile::CachingWriter
  attr_writer :file
end

# Basic tests for CachingWriter; the integration tests test it more thoroughly.
class CachingWriterTest < Test::Unit::TestCase
  def test_foo
    format = WaveFile::Format.new(:mono, 16, 44100)
    writer = StringCachingWriter.new("foo", format)
    string_io = StringIO.new
    writer.file = string_io

    assert_equal(format, writer.format)
    assert_equal("", string_io.string)

    buffer = WaveFile::Buffer.new([0, 1, 2], format)
    writer.write(buffer)
    assert_equal("\000\000\001\000\002\000", string_io.string)

    buffer = WaveFile::Buffer.new([3, 4, 5], format)
    writer.write(buffer)
    assert_equal("\000\000\001\000\002\000" +
                 "\003\000\004\000\005\000",
                 string_io.string)

    buffer = WaveFile::Buffer.new([0, 1, 2], format)
    writer.write(buffer)
    assert_equal("\000\000\001\000\002\000" +
                   "\003\000\004\000\005\000" +
                   "\000\000\001\000\002\000",
                 string_io.string)
  end
end
