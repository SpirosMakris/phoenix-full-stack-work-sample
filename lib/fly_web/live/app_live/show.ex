defmodule FlyWeb.AppLive.Show do
  use FlyWeb, :live_view
  require Logger

  alias Fly.Client

  @impl true
  def mount(%{"name" => name}, session, socket) do
    socket =
      assign(socket,
        config: client_config(session),
        state: :loading,
        loading: false,
        app: nil,
        app_name: name,
        app_status: nil,
        count: 0,
        authenticated: true
      )


    # Make API call only on connected mount
    if connected?(socket) do
      {:ok, fetch_app(socket)}
    else
      {:ok, socket}
    end
  end

  defp client_config(session) do
    Fly.Client.config(access_token: session["auth_token"] || System.get_env("FLYIO_ACCESS_TOKEN"))
  end

  defp fetch_app(socket) do
    app_name = socket.assigns.app_name

    case Client.fetch_app(app_name, socket.assigns.config) do
      {:ok, app} ->
        Logger.debug("Successfully fetched app")

        # Now that we jave the app. get the status (async)
        show_completed = true

        send(self(), {:fetch_app_status, app_name, show_completed})

        assign(socket, :app, app)

      {:error, :unauthorized} ->
        put_flash(socket, :error, "Not authenticated")

      {:error, reason} ->
        Logger.error("Failed to load app '#{inspect(app_name)}'. Reason: #{inspect(reason)}")

        put_flash(socket, :error, reason)
    end
  end

  @impl true
  def handle_event("refresh", _params, socket) do
    Logger.debug("handle_event 'refresh'")

    app_name = socket.assigns.app_name
    show_completed = true

    send(self(), {:fetch_app_status, app_name, show_completed})

    {:noreply, assign(socket, loading: true)}
  end

  @impl true
  def handle_info({:fetch_app_status, app_name, show_completed}, socket) do
    Logger.debug("handle_info ':fetch_app_status'")

    case Client.fetch_app_status(app_name, show_completed, socket.assigns.config) do
      {:ok, app_status} ->
        Logger.debug("Successfully fetched app status")

        socket =
          assign(socket,
            app_status: app_status["appstatus"],
            loading: false
          )
        {:noreply, socket}

      # @TODO: See we if need special error case for auth
      {:error, reason} ->
        Logger.error("Failed to fetch app status. Reason: #{inspect reason}")
        socket = put_flash(socket, :error, reason)

        {:noreply, socket}
    end
  end

  # HTML helpers
  def status_bg_color(app) do
    case app["status"] do
      "running" -> "bg-green-100"
      "dead" -> "bg-red-100"
      _ -> "bg-yellow-100"
    end
  end

  def status_text_color(app) do
    case app["status"] do
      "running" -> "text-green-800"
      "dead" -> "text-red-800"
      _ -> "text-yellow-800"
    end
  end

  def preview_url(app) do
    "https://#{app["name"]}.fly.dev"
  end

end
