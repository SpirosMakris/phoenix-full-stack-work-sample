defmodule FlyWeb.AppLive.Show do
  use FlyWeb, :live_view
  require Logger

  use Phoenix.Component

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
        authenticated: true,
        refresh_rate: 5
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

  def handle_event("select-refresh-rate", %{"refresh-rate" => rate}, socket) do
    Logger.debug("handle-event 'select-refresh-rate'")


    {:noreply, assign(socket, refresh_rate: rate)}
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

  # Logic helpers
  def depl_status(app_status), do: app_status["deploymentStatus"]

  def depl_status(app_status, field) when not is_nil(app_status) do
    depl = app_status["deploymentStatus"]
    depl["#{field}"]
  end

  def depl_status(nil, _field) do
    nil
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


  # Function components/blocks
  def card(assigns) do
    ~H"""
    <div class="mt-8 mb-4 flex-1 flex flex-col px-4 py-4 bg-white shadow-lg rounded-lg cursor-pointer">
      <h3> <%= assigns.title %> </h3>
      <%= render_block(@inner_block) %>

    </div>
    """
  end

  def card_entry(assigns) do
    ~H"""
      <div class="py-2 mr-12 flex flex-col capitalize text-gray-700">
        <span> <%= assigns.title %> </span>
        <span class="mt-1 text-black">
          <%= assigns.value %>
        </span>
      </div>
    """
  end

  def refresh_rate(assigns) do
    ~H"""
    <div id="select-refresh-rate">
      <form phx-change="select-refresh-rate">
        <label for="refresh-rate">Refresh rate: </label>
        <select name="refresh-rate">
          <%= options_for_select(["2s": 2, "5s": 5], assigns.rate) %>
        </select>

      </form>
    </div>
    """
  end

  def depl_instances_table(assigns) do
    IO.inspect assigns
    ~H"""
    <div class="mt-2">
      <div> Deployment Instances </div>
      <table class="max-w-5xl table-auto">
        <thead class="justify-between">
          <tr class="bg-gray-100">
            <th class="px-16 py-2">
              <span class="text-white-100 font-semibold">Desired</span>
            </th>

            <th class="px-16 py-2">
              <span class="text-white-100 font-semibold">Placed</span>
            </th>

            <th class="px-16 py-2">
              <span class="text-green-600 font-semibold">Healthy</span>
            </th>

            <th class="px-16 py-2">
              <span class="text-red-600 font-semibold">Unealthy</span>
            </th>

          </tr>
        </thead>
        <tbody class="bg-gray-200">
          <tr class="bg-white border-b-2 border-gray-200">

            <td class="px-16 py-2">
              <span class="px-16 py-2"><%= assigns.depl_status["desiredCount"] %></span>
            </td>

            <td class="px-16 py-2">
              <span class="px-16 py-2"><%= assigns.depl_status["placedCount"] %></span>
            </td>

            <td class="px-16 py-2">
              <span class="px-16 py-2"><%= assigns.depl_status["healthyCount"] %></span>
            </td>

            <td class="px-16 py-2">
              <span class="px-16 py-2"><%= assigns.depl_status["unhealthyCount"] %></span>
            </td>

          </tr>
        </tbody>
      </table>
    </div>
    """
  end

end
