# KinoClipboard

Small component that allows you to copy text to the clipboard programmatically.

## Instructions

Add `kino_clipboard` to your Livebook dependencies:

```elixir
Mix.install([
  {:kino_clipboard, "~> 0.1.0"}
])
```

Then, use it in your Livebook whenever you want to copy content straight to the clipboard:

```elixir
KinoClipboard.new("Hello world!")
```

If your content is potentially large, you can use a function to generate it instead:

```elixir
KinoClipboard.new(fn -> "Hello world!" end)
```

You can also customize the label of the button:

```elixir
KinoClipboard.new(fn -> "Hello world!" end, label: "Copy to clipboard")
```

## License

Copyright (c) 2025 Raphael Vidal Costa

Source code is licensed under the [MIT License](LICENSE).