require File.expand_path('../helper', __FILE__)

class TestArchive < Test::Unit::TestCase
  def setup
    @original = "Yeah" * 100
  end

  def test_gzip
    gzip = Archive.new :gzip

    compressed = (gzip.compress @original, 9).read
    decompressed = (gzip.decompress compressed).read

    assert compressed.length < @original.length

    assert_equal @original, decompressed

    assert_not_nil compressed
    assert_not_nil decompressed

    assert_not_equal @original, compressed
    assert_not_equal decompressed, compressed
  end

  def test_lzo
    lzo = Archive.new :lzo

    compressed = (lzo.compress @original, 9).read
    decompressed = (lzo.decompress compressed).read

    assert compressed.length < @original.length

    assert_equal @original, decompressed

    assert_not_nil compressed
    assert_not_nil decompressed

    assert_not_equal @original, compressed
    assert_not_equal decompressed, compressed
  end
end
