defmodule Protobufex.Protoc.Generator.MessageTest do
  use ExUnit.Case, async: true

  alias Protobufex.Protoc.Context
  alias Protobufex.Protoc.Generator.Message, as: Generator

  test "generate/2 has right name" do
    ctx = %Context{package: ""}
    desc = Google.Protobuf.DescriptorProto.new(name: "Foo")
    [msg] = Generator.generate(ctx, desc)
    assert msg =~ "defmodule Foo do\n"
    assert msg =~ "use Protobufex\n"
  end

  test "generate/2 has right syntax" do
    ctx = %Context{package: "", syntax: :proto3}
    desc = Google.Protobuf.DescriptorProto.new(name: "Foo")
    [msg] = Generator.generate(ctx, desc)
    assert msg =~ "defmodule Foo do\n"
    assert msg =~ "use Protobufex, syntax: :proto3\n"
  end

  test "generate/2 has right name with package" do
    ctx = %Context{package: "pkg.name"}
    desc = Google.Protobuf.DescriptorProto.new(name: "Foo")
    [msg] = Generator.generate(ctx, desc)
    assert msg =~ "defmodule Pkg.Name.Foo do\n"
  end

  test "generate/2 has right options" do
    ctx = %Context{package: "pkg.name"}
    desc = Google.Protobuf.DescriptorProto.new(name: "Foo", options: Google.Protobuf.MessageOptions.new(map_entry: true))
    [msg] = Generator.generate(ctx, desc)
    assert msg =~ "use Protobufex, map: true\n"
  end

  test "generate/2 has right fields" do
    ctx = %Context{package: ""}
    desc = Google.Protobuf.DescriptorProto.new(name: "Foo", field: [
      Google.Protobuf.FieldDescriptorProto.new(name: "a", number: 1, type: 5, label: 1),
      Google.Protobuf.FieldDescriptorProto.new(name: "b", number: 2, type: 9, label: 2)
    ])
    [msg] = Generator.generate(ctx, desc)
    assert msg =~ "defstruct [:a, :b]\n"
    assert msg =~ "a: integer"
    assert msg =~ "b: String.t"
    assert msg =~ "field :a, 1, optional: true, type: :int32\n"
    assert msg =~ "field :b, 2, required: true, type: :string\n"
  end

  test "generate/2 has right fields for proto3" do
    ctx = %Context{package: "", syntax: :proto3}
    desc = Google.Protobuf.DescriptorProto.new(name: "Foo", field: [
      Google.Protobuf.FieldDescriptorProto.new(name: "a", number: 1, type: 5, label: 1),
      Google.Protobuf.FieldDescriptorProto.new(name: "b", number: 2, type: 9, label: 2),
      Google.Protobuf.FieldDescriptorProto.new(name: "c", number: 3, type: 5, label: 3)
    ])
    [msg] = Generator.generate(ctx, desc)
    assert msg =~ "defstruct [:a, :b, :c]\n"
    assert msg =~ "a: integer"
    assert msg =~ "b: String.t"
    assert msg =~ "field :a, 1, type: :int32\n"
    assert msg =~ "field :b, 2, type: :string\n"
    assert msg =~ "field :c, 3, repeated: true, type: :int32\n"
  end

  test "generate/2 supports option :default" do
    ctx = %Context{package: ""}
    desc = Google.Protobuf.DescriptorProto.new(name: "Foo", field: [
      Google.Protobuf.FieldDescriptorProto.new(name: "a", number: 1, type: 5, label: 1, default_value: "42")
    ])
    [msg] = Generator.generate(ctx, desc)
    assert msg =~ "a: integer"
    assert msg =~ "field :a, 1, optional: true, type: :int32, default: 42\n"
  end

  test "generate/2 supports option :packed" do
    ctx = %Context{package: ""}
    desc = Google.Protobuf.DescriptorProto.new(name: "Foo", field: [
      Google.Protobuf.FieldDescriptorProto.new(name: "a", number: 1, type: 5, label: 1,
        options: %Google.Protobuf.FieldOptions{packed: true})
    ])
    [msg] = Generator.generate(ctx, desc)
    assert msg =~ "field :a, 1, optional: true, type: :int32, packed: true\n"
  end

  test "generate/2 supports option :deprecated" do
    ctx = %Context{package: ""}
    desc = Google.Protobuf.DescriptorProto.new(name: "Foo", field: [
      Google.Protobuf.FieldDescriptorProto.new(name: "a", number: 1, type: 5, label: 1,
      options: %Google.Protobuf.FieldOptions{deprecated: true})
    ])
    [msg] = Generator.generate(ctx, desc)
    assert msg =~ "field :a, 1, optional: true, type: :int32, deprecated: true\n"
  end

  test "generate/2 supports map field" do
    ctx = %Context{package: "foo_bar.ab_cd"}
    desc = Google.Protobuf.DescriptorProto.new(name: "Foo", field: [
      Google.Protobuf.FieldDescriptorProto.new(name: "a", number: 1, type: 11, label: 3, type_name: ".foo_bar.ab_cd.Foo.ProjectsEntry")
    ], nested_type: [Google.Protobuf.DescriptorProto.new(
      name: "ProjectsEntry", options: Google.Protobuf.MessageOptions.new(map_entry: true),
      field: [
        Google.Protobuf.FieldDescriptorProto.new(name: "key", number: 1, label: 1, type: 5, type_name: "int32"),
        Google.Protobuf.FieldDescriptorProto.new(name: "value", number: 2, label: 1, type: 11, type_name: ".foo_bar.ab_cd.Bar")
      ]
    )])
    [msg, _] = Generator.generate(ctx, desc)
    assert msg =~ "a: %{integer => FooBar.AbCd.Bar.t}"
    assert msg =~ "field :a, 1, repeated: true, type: FooBar.AbCd.Foo.ProjectsEntry, map: true\n"
  end

  test "generate/2 supports enum field" do
    ctx = %Context{package: "foo_bar.ab_cd"}
    desc = Google.Protobuf.DescriptorProto.new(name: "Foo", field: [
      Google.Protobuf.FieldDescriptorProto.new(name: "a", number: 1, type: 14, label: 1, type_name: ".foo_bar.ab_cd.EnumFoo")
    ])
    [msg] = Generator.generate(ctx, desc)
    assert msg =~ "a: integer"
    assert msg =~ "field :a, 1, optional: true, type: FooBar.AbCd.EnumFoo, enum: true\n"
  end

  test "generate/2 generate right enum type name with different package" do
    ctx = %Context{package: "foo_bar.ab_cd", dep_pkgs: ["other_pkg"]}
    desc = Google.Protobuf.DescriptorProto.new(name: "Foo", field: [
      Google.Protobuf.FieldDescriptorProto.new(name: "a", number: 1, type: 14, label: 1, type_name: ".other_pkg.EnumFoo")
    ])
    [msg] = Generator.generate(ctx, desc)
    assert msg =~ "field :a, 1, optional: true, type: OtherPkg.EnumFoo, enum: true\n"
  end

  test "generate/2 generate right message type name with different package" do
    ctx = %Context{package: "foo_bar.ab_cd", dep_pkgs: ["other_pkg"]}
    desc = Google.Protobuf.DescriptorProto.new(name: "Foo", field: [
      Google.Protobuf.FieldDescriptorProto.new(name: "a", number: 1, type: 11, label: 1, type_name: ".other_pkg.MsgFoo")
    ])
    [msg] = Generator.generate(ctx, desc)
    assert msg =~ "a: OtherPkg.MsgFoo.t"
    assert msg =~ "field :a, 1, optional: true, type: OtherPkg.MsgFoo\n"
  end

  test "generate/2 use longest package name for type" do
    ctx = %Context{package: "foo_bar.ab_cd", dep_pkgs: ["foo.bar", "foo"]}
    desc = Google.Protobuf.DescriptorProto.new(name: "Foo", field: [
      Google.Protobuf.FieldDescriptorProto.new(name: "a", number: 1, type: 14, label: 1, type_name: ".foo.bar.EnumFoo")
    ])
    [msg] = Generator.generate(ctx, desc)
    assert msg =~ "field :a, 1, optional: true, type: Foo.Bar.EnumFoo, enum: true\n"
  end

  test "generate/2 supports nested messages" do
    ctx = %Context{package: ""}
    desc = Google.Protobuf.DescriptorProto.new(name: "Foo", nested_type: [
      Google.Protobuf.DescriptorProto.new(name: "Nested")
    ])
    [_, [msg]] = Generator.generate(ctx, desc)
    assert msg =~ "defmodule Foo.Nested do\n"
    assert msg =~ "defstruct []\n"
  end

  test "generate/2 supports nested enum messages" do
    ctx = %Context{package: ""}
    desc = Google.Protobuf.DescriptorProto.new(name: "Foo", nested_type: [
      Google.Protobuf.DescriptorProto.new(enum_type: [
        Google.Protobuf.EnumDescriptorProto.new(name: "EnumFoo",
          value: [%Google.Protobuf.EnumValueDescriptorProto{name: "a", number: 0},
                  %Google.Protobuf.EnumValueDescriptorProto{name: "b", number: 1}]
        )
      ], name: "Nested")
    ])
    [_, [_, msg]] = Generator.generate(ctx, desc)
    assert msg =~ "defmodule Foo.Nested.EnumFoo do\n"
    assert msg =~ "use Protobufex, enum: true\n"
    assert msg =~ "field :a, 0\n  field :b, 1\n"
  end

  test "generate/2 supports oneof" do
    ctx = %Context{package: ""}
    desc = Google.Protobuf.DescriptorProto.new(name: "Foo", oneof_decl: [
      Google.Protobuf.OneofDescriptorProto.new(name: "first"),
      Google.Protobuf.OneofDescriptorProto.new(name: "second")
    ], field: [
      Google.Protobuf.FieldDescriptorProto.new(name: "a", number: 1, type: 5, label: 1, oneof_index: 0),
      Google.Protobuf.FieldDescriptorProto.new(name: "b", number: 2, type: 5, label: 1, oneof_index: 0),
      Google.Protobuf.FieldDescriptorProto.new(name: "c", number: 3, type: 5, label: 1, oneof_index: 1),
      Google.Protobuf.FieldDescriptorProto.new(name: "d", number: 4, type: 5, label: 1, oneof_index: 1),
      Google.Protobuf.FieldDescriptorProto.new(name: "other", number: 4, type: 5, label: 1),
    ])
    [msg] = Generator.generate(ctx, desc)
    assert msg =~ "first: {atom, any},\n"
    assert msg =~ "second: {atom, any},\n"
    assert msg =~ "other: integer\n"
    refute msg =~ "a: integer,\n"
    assert msg =~ "defstruct [:first, :second, :other]\n"
    assert msg =~ "oneof :first, 0\n"
    assert msg =~ "oneof :second, 1\n"
    assert msg =~ "field :a, 1, optional: true, type: :int32, oneof: 0\n"
    assert msg =~ "field :b, 2, optional: true, type: :int32, oneof: 0\n"
    assert msg =~ "field :c, 3, optional: true, type: :int32, oneof: 1\n"
    assert msg =~ "field :d, 4, optional: true, type: :int32, oneof: 1\n"
    assert msg =~ "field :other, 4, optional: true, type: :int32\n"
  end
end