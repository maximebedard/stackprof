$:.unshift File.expand_path('../../lib', __FILE__)
require 'stackprof'
require 'stackprof/middleware'
require 'minitest/autorun'
require 'mocha/setup'

class StackProf::MiddlewareTest < MiniTest::Test

  def test_path_default
    StackProf::Middleware.new(Object.new)

    assert_equal 'tmp', StackProf::Middleware.path
  end

  def test_path_custom
    StackProf::Middleware.new(Object.new, { path: '/foo' })

    assert_equal '/foo', StackProf::Middleware.path
  end

  def test_save_default
    StackProf::Middleware.new(Object.new)

    StackProf.stubs(:results).returns({ mode: 'foo' })
    FileUtils.expects(:mkdir_p).with('tmp')
    File.expects(:open).with(regexp_matches(/^tmp\/stackprof-foo/), 'wb')

    StackProf::Middleware.save
  end

  def test_save_custom
    StackProf::Middleware.new(Object.new, { path: '/foo' })

    StackProf.stubs(:results).returns({ mode: 'foo' })
    FileUtils.expects(:mkdir_p).with('/foo')
    File.expects(:open).with(regexp_matches(/^\/foo\/stackprof-foo/), 'wb')

    StackProf::Middleware.save
  end

  def test_enabled_should_use_a_proc_if_passed
    StackProf::Middleware.new(Object.new, enabled: Proc.new{ false })
    refute StackProf::Middleware.enabled?

    StackProf::Middleware.new(Object.new, enabled: Proc.new{ true })
    assert StackProf::Middleware.enabled?
  end

  def test_enabled_should_override_mode_if_a_proc
    proc_called = false
    middleware = StackProf::Middleware.new(proc {|env| proc_called = true}, enabled: Proc.new{ [true, 'foo'] })
    enabled, mode = StackProf::Middleware.enabled?
    assert enabled
    assert_equal 'foo', mode

    StackProf.expects(:start).with({mode: 'foo', interval: StackProf::Middleware.interval, raw: false})
    StackProf.expects(:stop)

    middleware.call(nil)
    assert proc_called
  end

  def test_raw_should_start_with_raw
    proc_called = false

    middleware = StackProf::Middleware.new(proc { |env| proc_called = true }, enabled: [true, 'foo'], raw: true)

    StackProf.expects(:start).with({mode: 'foo', interval: StackProf::Middleware.interval, raw: true})
    StackProf.expects(:stop)

    middleware.call(nil)

    env = Hash.new { true }
    StackProf::Middleware.new(Object.new, enabled: enable_proc)
    assert StackProf::Middleware.enabled?(env)
  end

  def test_raw
    StackProf::Middleware.new(Object.new, raw: true)
    assert StackProf::Middleware.raw
  end
end
