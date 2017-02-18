require 'includes'

# Makes @file writable so it can be replaced with StringIO for testing
class StringCachingWriter < WaveFile::CachingWriter
  attr_writer :file
end

# Basic tests for CachingWriter; the integration tests test it more thoroughly.
class CachingWriterTest < Minitest::Test
  def test_mono
    buffer1_bytes = [0, 0, 1, 0, 2, 0]
    buffer2_bytes = [3, 0, 4, 0, 5, 0]

    format = WaveFile::Format.new(:mono, 16, 44100)
    writer = StringCachingWriter.new("does_not_matter", format)
    string_io = StringIO.new
    writer.file = string_io

    assert_equal(format, writer.format)

    buffer = WaveFile::Buffer.new([0, 1, 2], format)
    writer.write(buffer)
    assert_equal(buffer1_bytes, get_bytes(string_io))

    buffer = WaveFile::Buffer.new([3, 4, 5], format)
    writer.write(buffer)
    assert_equal(buffer1_bytes + buffer2_bytes, get_bytes(string_io))

    buffer = WaveFile::Buffer.new([0, 1, 2], format)
    writer.write(buffer)
    assert_equal(buffer1_bytes + buffer2_bytes + buffer1_bytes, get_bytes(string_io))
  end

  def test_stereo
    buffer1_bytes = [0, 0, 3, 0, 1, 0, 2, 0]
    buffer2_bytes = [9, 0, 6, 0, 8, 0, 7, 0]

    format = WaveFile::Format.new(:stereo, 16, 44100)
    writer = StringCachingWriter.new("does_not_matter", format)
    string_io = StringIO.new
    writer.file = string_io

    assert_equal(format, writer.format)

    buffer = WaveFile::Buffer.new([[0, 3], [1, 2]], format)
    writer.write(buffer)
    assert_equal(buffer1_bytes, get_bytes(string_io))

    buffer = WaveFile::Buffer.new([[9, 6], [8, 7]], format)
    writer.write(buffer)
    assert_equal(buffer1_bytes + buffer2_bytes, get_bytes(string_io))

    buffer = WaveFile::Buffer.new([[0, 3], [1, 2]], format)
    writer.write(buffer)
    assert_equal(buffer1_bytes + buffer2_bytes + buffer1_bytes, get_bytes(string_io))
  end

private

  def get_bytes(string_io)
    string_io.string.each_byte.inject([]) {|arr, element| arr << element }
  end
end
