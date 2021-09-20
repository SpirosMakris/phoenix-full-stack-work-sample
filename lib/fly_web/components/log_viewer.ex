defmodule FlyWeb.Components.LogViewer do
  use Phoenix.LiveComponent
  require Logger

  alias Fly.Client

  def mount(socket) do
    Logger.debug("LogViewer mount()")

    IO.inspect socket
    {:ok, assign(socket, logs: nil)}

  end


  def update(assigns, socket) do
    Logger.debug("LogViewer update()")

    IO.inspect assigns

    if connected?(socket) do
      Logger.debug("Connected, fetching logs")
      app_name = assigns.app_name
      config = assigns.config
      {:ok, fetch_logs(app_name, config, socket)}
    else
      Logger.debug("Not connected, can't fetch logs")
      {:ok, socket}
    end

  end

  defp fetch_logs(app_name, config, socket) do

    case Client.fetch_app_logs(app_name, 50,3600, config) do
      {:ok, resp} ->
        Logger.debug("Got app logs for: #{inspect(app_name)}")
        alloc_logs = resp["appstatus"]["allocations"]
        assign(socket, alloc_logs: alloc_logs)

      {:error, :unauthorized} ->
        Logger.error("Not authenticated. Can't fetch app logs")
        put_flash(socket, :error, "Not authenticated")

      {:error, reason} ->
        Logger.error("Failed to fetch app logs for app: '#{inspect(app_name)}'. Reason: #{inspect(reason)} ")
        put_flash(socket, :error, reason)
    end
  end

  def render(assigns) do
    ~H"""
    <div>
      <div> Log Viewer </div>
      <%= if @alloc_logs do %>
        <ul>
        <%= for alloc <- @alloc_logs do %>

          <p> Alloc ID: <%= alloc["id"] %>
          <%= for log <- alloc["recentLogs"] do%>
            <p> <%= log["message"] %> </p>
          <% end %>
        <% end %>
        </ul>
      <% end %>
    </div>
    """
  end
end
