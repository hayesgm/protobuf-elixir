defmodule Protobufex.DecodeError do
  defexception message: "something wrong when decoding"
end
defmodule Protobufex.InvalidError do
  defexception [:message]
end
