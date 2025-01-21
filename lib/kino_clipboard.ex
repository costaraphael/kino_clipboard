defmodule KinoClipboard do
  @moduledoc """
  A component that allows you to copy text to the clipboard.
  """

  use Kino.JS
  use Kino.JS.Live

  require Logger

  @doc """
  Creates a "Copy to clipboard" button.

  Data to be copied can be provided as a string or as a function that returns a string.

  ## Options

    * `:label` - The label of the button. Defaults to "Copy to clipboard".

  ## Examples

      KinoClipboard.new("Hello world!")

      KinoClipboard.new(fn -> "Hello world!" end)

      KinoClipboard.new(fn -> "Hello world!" end, label: "Copy to clipboard")
  """
  @spec new(String.t() | (-> String.t()), keyword()) :: Kino.JS.Live.t()
  def new(data_or_fun, opts \\ [])

  def new(data, opts) when is_binary(data) and is_list(opts) do
    new(fn -> data end, opts)
  end

  def new(data_fun, opts) when is_function(data_fun, 0) and is_list(opts) do
    opts = Keyword.validate!(opts, label: "Copy to clipboard")

    Kino.JS.Live.new(__MODULE__, {data_fun, opts[:label]})
  end

  def init({data_fun, label}, ctx) do
    {:ok, assign(ctx, data_fun: data_fun, label: label)}
  end

  def handle_connect(ctx) do
    {:ok, %{label: ctx.assigns.label}, ctx}
  end

  def handle_event("copy", _args, ctx) do
    try do
      data = ctx.assigns.data_fun.()
      payload = {:binary, %{}, data}

      send_event(ctx, ctx.origin, "copy_content", payload)
    rescue
      error ->
        {error, stacktrace} = Exception.blame(:error, error, __STACKTRACE__)
        formatted = Exception.format(:error, error, stacktrace)

        Logger.error("Error while generating clipboard content. #{formatted}")

        send_event(ctx, ctx.origin, "copy_content_error", %{})
    end

    {:noreply, ctx}
  end

  asset "main.js" do
    """
    export function init(ctx, data) {
      ctx.importCSS("main.css");
      ctx.importCSS("https://fonts.googleapis.com/css2?family=Inter:wght@500&display=swap");

      ctx.root.innerHTML = `
        <button class="button">
          <svg width="100%" height="100%" class="icon" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M16 4C16.93 4 17.395 4 17.7765 4.10222C18.8117 4.37962 19.6204 5.18827 19.8978 6.22354C20 6.60504 20 7.07003 20 8V17.2C20 18.8802 20 19.7202 19.673 20.362C19.3854 20.9265 18.9265 21.3854 18.362 21.673C17.7202 22 16.8802 22 15.2 22H8.8C7.11984 22 6.27976 22 5.63803 21.673C5.07354 21.3854 4.6146 20.9265 4.32698 20.362C4 19.7202 4 18.8802 4 17.2V8C4 7.07003 4 6.60504 4.10222 6.22354C4.37962 5.18827 5.18827 4.37962 6.22354 4.10222C6.60504 4 7.07003 4 8 4M9.6 6H14.4C14.9601 6 15.2401 6 15.454 5.89101C15.6422 5.79513 15.7951 5.64215 15.891 5.45399C16 5.24008 16 4.96005 16 4.4V3.6C16 3.03995 16 2.75992 15.891 2.54601C15.7951 2.35785 15.6422 2.20487 15.454 2.10899C15.2401 2 14.9601 2 14.4 2H9.6C9.03995 2 8.75992 2 8.54601 2.10899C8.35785 2.20487 8.20487 2.35785 8.10899 2.54601C8 2.75992 8 3.03995 8 3.6V4.4C8 4.96005 8 5.24008 8.10899 5.45399C8.20487 5.64215 8.35785 5.79513 8.54601 5.89101C8.75992 6 9.03995 6 9.6 6Z" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
          <span class="text">${data.label}</span>
        </button>
      `;

      const button = ctx.root.querySelector("button");
      const text = ctx.root.querySelector("button > span.text");

      const copyData = async (buffer) => {
        const decoder = new TextDecoder();
        const str = decoder.decode(buffer);

        // Navigator clipboard api needs a secure context (https)
        if (navigator.clipboard && window.isSecureContext) {
          try {
            await navigator.clipboard.writeText(str);

            return true;
          } catch (error) {
            console.error(error);

            return false;
          }
        } else {
          // Use the 'out of viewport hidden text area' trick
          const textArea = document.createElement("textarea");
          textArea.value = str;

          textArea.style.position = "absolute";
          textArea.style.opacity = 0;

          ctx.root.prepend(textArea);
          textArea.select();

          try {
            return document.execCommand('copy');
          } catch (error) {
            console.error(error);

            return false;
          } finally {
            textArea.remove();
          }
        }
      };

      const restoreButton = () => {
        setTimeout(() => {
          button.classList.remove('success', 'failure');
          button.disabled = false;
          text.innerHTML = data.label;
        }, 2000);
      };

      button.addEventListener("click", () => {
        ctx.pushEvent("copy", {});
        button.disabled = true;
        text.innerHTML = "Loading...";
      });

      ctx.handleEvent("copy_content", async ([_info, buffer]) => {
        if (await copyData(buffer)) {
          button.classList.add('success');
          text.innerHTML = 'Copied successfully';
        } else {
          button.classList.add('failure');
          text.innerHTML = 'Failed to copy';
        }

        restoreButton();
      });

      ctx.handleEvent("copy_content_error", () => {
        button.classList.add('failure');
        text.innerHTML = 'Error retrieving data';

        restoreButton();
      });
    }
    """
  end

  asset "main.css" do
    """
    .button {
      padding: 8px 20px;
      background-color: white;
      border-radius: 8px;
      border: 1px #CAD5E0 solid;
      display: flex;
      align-items: center;
      cursor: pointer;
      white-space: nowrap;
      transition: background-color 0.5s ease-in-out;
    }

    .button:hover:not(:disabled), .button:focus:not(:disabled) {
      background-color: #F0F5F9;
      outline: none;
    }

    .button:disabled {
      background-color: #F0F5F9;
      cursor: not-allowed;
    }

    .button.success {
      background-color: #E5F5E1;
    }

    .button.failure {
      background-color: #FFEBE6;
    }

    .button .icon {
      margin-right: 8px;
      height: 1.25rem;
      width: 1.25rem;
    }

    .button .text {
      color: #445668;
      font-family: "Inter";
      font-weight: 500;
      font-size: 0.875rem;
      line-height: 1.25rem;
    }
    """
  end
end
