defmodule Protobufex do
  defmacro __using__(opts) do
    quote do
      import Protobufex.DSL, only: [field: 3, field: 2, oneof: 2]
      Module.register_attribute(__MODULE__, :fields, accumulate: true)
      Module.register_attribute(__MODULE__, :oneofs, accumulate: true)

      @options unquote(opts)
      unquote(encode_decode())
      @before_compile Protobufex.DSL

      def new(attrs \\ %{}) do
        Protobufex.Builder.new(__MODULE__, attrs)
      end

      def from_params(params \\ %{}) do
        Protobufex.Builder.from_params(__MODULE__, params)
      end
    end
  end

  defp encode_decode() do
    quote do
      def decode(data), do: Protobufex.Decoder.decode(data, __MODULE__)
      def encode(struct), do: Protobufex.Encoder.encode(struct)
    end
  end

  def decode(%{__struct__: mod} = data) do
    Protobufex.Decoder.decode(data, mod)
  end

  def encode(struct) do
    Protobufex.Encoder.encode(struct)
  end
end
