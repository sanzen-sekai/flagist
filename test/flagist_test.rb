require 'test_helper'

require "active_model"

class FlagistTest < Minitest::Test
  class FlagistTestModel
    include ActiveModel::Model

    attr_accessor :is_ok, :is_active, :color, :roles, :status

    def initialize
      @is_ok = true
      @is_active = true
      @color = 1
      @roles = "admin,user"
      @status = "ok"
    end
  end

  def test_that_it_has_a_version_number
    refute_nil ::Flagist::VERSION
  end

  def test_it_does_install
    ::Flagist.install
    assert ActiveModel::Model.respond_to?(:flagist)
  end

  def test_it_define_flag
    ::I18n.load_path = Dir[File.expand_path("../*.yml",__FILE__)]
    ::I18n.default_locale = :ja
    ::I18n.backend.load_translations

    FlagistTestModel.__send__ :include, ::Flagist
    FlagistTestModel.class_eval do
      flagist do |flag|
        flag.is_ok true, false
        flag.is_active true, false
        flag.color nil => :blank, 1 => :yellow, 2 => :red, 3 => :green
        flag.roles :admin, :user, :guest
        flag.status({type: :array}, :ok)
      end
    end

    assert_equal({
      is_ok: {
        type: :scalar,
        flags: {
          true  => {value: true,  name: true},
          false => {value: false, name: false},
        },
      },
      is_active: {
        type: :scalar,
        flags: {
          true  => {value: true,  name: true,  label: "有効"},
          false => {value: false, name: false, label: "無効"},
        },
      },
      color: {
        type: :scalar,
        flags: {
          nil => {value: nil, name: :blank,  label: "なし"},
          1   => {value: 1,   name: :yellow, label: "黄"},
          2   => {value: 2,   name: :red,    label: "赤"},
          3   => {value: 3,   name: :green,  label: "緑"},
        },
      },
      roles: {
        type: :array,
        flags: {
          :admin => {value: :admin, name: :admin, label: "管理"},
          :user  => {value: :user,  name: :user,  label: "ユーザー"},
          :guest => {value: :guest, name: :guest, label: "ゲスト"},
        },
      },
      status: {
        type: :array,
        flags: {
          :ok => {value: :ok, name: :ok},
        },
      },
    }, FlagistTestModel.flagist)

    assert_equal({true => "有効", false => "無効"}, FlagistTestModel.is_active_labels)
    assert_equal({true => true,   false => false},  FlagistTestModel.is_active_names)
    assert_equal({nil => :blank, 1 => :yellow, 2 => :red, 3 => :green},  FlagistTestModel.color_names)
    assert_equal({admin: "管理", user: "ユーザー", guest: "ゲスト"},  FlagistTestModel.roles_labels)
    assert_equal({admin: :admin, user: :user, guest: :guest},  FlagistTestModel.roles_names)

    assert_equal({"有効" => true, "無効" => false}, FlagistTestModel.is_active_labels_inverse)
    assert_equal({true => true,   false => false},  FlagistTestModel.is_active_names_inverse)


    assert_equal 1, FlagistTestModel.color(1)
    assert_equal 1, FlagistTestModel.color(:yellow)
    assert_equal 1, FlagistTestModel.color("黄")

    assert_equal :yellow, FlagistTestModel.color_name(1)
    assert_equal :yellow, FlagistTestModel.color_name(:yellow)
    assert_equal :yellow, FlagistTestModel.color_name("黄")

    assert_equal "黄", FlagistTestModel.color_label(1)
    assert_equal "黄", FlagistTestModel.color_label(:yellow)
    assert_equal "黄", FlagistTestModel.color_label("黄")

    assert_equal nil, FlagistTestModel.color(nil)
    assert_equal :blank, FlagistTestModel.color_name(nil)
    assert_equal "なし", FlagistTestModel.color_label(nil)

    assert_equal [1,2], FlagistTestModel.color([:yellow,:red])
    assert_equal [:yellow,:red], FlagistTestModel.color_name([1,2])
    assert_equal ["黄","赤"], FlagistTestModel.color_label([1,2])

    assert_raises(::Flagist::UnknownFlagError){FlagistTestModel.color(0)}
    assert_raises(::Flagist::UnknownFlagError){FlagistTestModel.color_name(0)}
    assert_raises(::Flagist::UnknownFlagError){FlagistTestModel.color_label(0)}


    instance = FlagistTestModel.new

    assert_equal({true => "有効", false => "無効"}, instance.is_active_labels)
    assert_equal({true => true,   false => false},  instance.is_active_names)
    assert_equal({nil => :blank, 1 => :yellow, 2 => :red, 3 => :green},  instance.color_names)
    assert_equal({admin: "管理", user: "ユーザー", guest: "ゲスト"},  instance.roles_labels)
    assert_equal({admin: :admin, user: :user, guest: :guest},  instance.roles_names)

    assert_equal({"有効" => true, "無効" => false}, instance.is_active_labels_inverse)
    assert_equal({true => true,   false => false},  instance.is_active_names_inverse)


    assert_equal 1, instance.color
    assert_equal 1, instance.color(1)
    assert_equal 1, instance.color(:yellow)
    assert_equal 1, instance.color("黄")

    assert_equal :yellow, instance.color_name(1)
    assert_equal :yellow, instance.color_name(:yellow)
    assert_equal :yellow, instance.color_name("黄")

    assert_equal "黄", instance.color_label(1)
    assert_equal "黄", instance.color_label(:yellow)
    assert_equal "黄", instance.color_label("黄")

    assert_equal [1,2], instance.color([:yellow,:red])
    assert_equal [:yellow,:red], instance.color_name([1,2])
    assert_equal ["黄","赤"], instance.color_label([1,2])

    assert_equal [:admin,:user], instance.roles_name
    assert_equal ["管理","ユーザー"], instance.roles_label

    assert instance.roles_name.frozen?
    assert instance.roles_label.frozen?

    assert_raises(::Flagist::UnknownFlagError){instance.color(0)}
    assert_raises(::Flagist::UnknownFlagError){instance.color_name(0)}
    assert_raises(::Flagist::UnknownFlagError){instance.color_label(0)}


    instance.color_name = :red
    assert_equal 2, instance.color

    instance.color_label = "緑"
    assert_equal 3, instance.color

    instance.roles_label = ["管理","ゲスト"]
    assert_equal "admin,guest", instance.roles

    assert_raises(::Flagist::UnknownFlagError){instance.color_name = :blue}
    assert_raises(::Flagist::UnknownFlagError){instance.color_label = "青"}
  end
end
