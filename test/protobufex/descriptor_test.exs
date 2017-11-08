defmodule Protobufex.DescriptorTest do
  use ExUnit.Case, async: true

  test "generates protobuf from request" do
    input_bin = File.read!("./test/support/request.bin")
    expected = File.read!("./test/support/response.eex")

    code_generator_response = Protobufex.Protoc.CLI.run(input_bin)
    [file] = code_generator_response.file

    assert expected == file.content
  end
end
