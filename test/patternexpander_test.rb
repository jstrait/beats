$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/includes'

class PatternExpanderTest < Test::Unit::TestCase
  def test_valid_flow?
    # Contains nothing but :, always valid
    assert_equal(true, PatternExpander.valid_flow?(""))
    assert_equal(true, PatternExpander.valid_flow?(":"))
    assert_equal(true, PatternExpander.valid_flow?("::"))
    assert_equal(true, PatternExpander.valid_flow?(":::"))
    assert_equal(true, PatternExpander.valid_flow?("::::"))
    assert_equal(true, PatternExpander.valid_flow?("|:--:|----|:--:|"))
    
    # Contains characters other than :|- and [0-9]
    assert_equal(false, PatternExpander.valid_flow?("a"))
    assert_equal(false, PatternExpander.valid_flow?("1"))
    assert_equal(false, PatternExpander.valid_flow?(":--:z---"))
    assert_equal(false, PatternExpander.valid_flow?(":   :"))
    
    assert_equal(true, PatternExpander.valid_flow?(":0"))
    assert_equal(true, PatternExpander.valid_flow?(":1"))
    assert_equal(true, PatternExpander.valid_flow?(":4"))
    assert_equal(true, PatternExpander.valid_flow?(":4"))
    assert_equal(true, PatternExpander.valid_flow?(":16"))
    assert_equal(true, PatternExpander.valid_flow?("::4"))
    assert_equal(true, PatternExpander.valid_flow?(":::4"))
    assert_equal(true, PatternExpander.valid_flow?(":2::4"))
    assert_equal(true, PatternExpander.valid_flow?("::2::4"))
    
    assert_equal(false, PatternExpander.valid_flow?(":4:"))
    assert_equal(false, PatternExpander.valid_flow?("::4:"))
    assert_equal(false, PatternExpander.valid_flow?(":4:4"))
    assert_equal(false, PatternExpander.valid_flow?("::2:4"))
    assert_equal(false, PatternExpander.valid_flow?("::2:"))
    assert_equal(false, PatternExpander.valid_flow?("::2:::"))
  end
end