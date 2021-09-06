defmodule FlyWeb.Components.AppStatus do
  use FlyWeb, :live_view
  require Logger

  use Phoenix.Component

  alias Fly.Client

  @impl true
  def mount(_params, %{"name" => name} = session, socket) do
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
        refresh_period: 30
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

        # Now that we have the app. get the status (async)
        show_completed = true

        # Use message to self to fetch status
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

  def handle_event("select-refresh-period", %{"refresh-period" => period}, socket) do
    Logger.debug("handle-event 'select-refresh-period'")

    ref_period =
      if is_integer(period) do
        period
      else
        {period, ""} = Integer.parse(period)
        period
      end

    {:noreply, assign(socket, refresh_period: ref_period)}
  end

  @impl true
  def handle_info({:fetch_app_status, app_name, show_completed}, socket) do
    Logger.debug("handle_info ':fetch_app_status'")

    period = socket.assigns.refresh_period

    Process.send_after(self(), {:fetch_app_status, app_name, show_completed}, period * 1000)

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
        Logger.error("Failed to fetch app status. Reason: #{inspect(reason)}")
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
      <h3 class="text-black"> <%= assigns.title %> </h3>
      <%= render_block(@inner_block) %>

    </div>
    """
  end

  def card_entry(assigns) do
    ~H"""
      <div class="py-2 mr-12 flex flex-col capitalize">
        <span class="font-semibold text-gray-500"> <%= assigns.title %> </span>
        <span class="mt-1 text-black">
          <%= assigns.value %>
        </span>
      </div>
    """
  end

  def refresh_period(assigns) do
    ~H"""
    <div id="select-refresh-period" class="my-4">
      <form phx-change="select-refresh-period">
        <!-- <label for="refresh-period">Refresh period: </label> -->
        <button type="button" phx-click="refresh">
          <%= if assigns.loading do %>
            <%= __MODULE__.loading_svg(%{}) %>
          <% else %>
            Refresh
          <% end %>
        </button>
        <select name="refresh-period">
          <%= options_for_select(["2s": 2, "5s": 5, "15s": 15, "30s": 30, "1m": 60, "2m": 120], assigns.period) %>
        </select>


      </form>
    </div>
    """
  end

  def depl_instances_table(assigns) do
    IO.inspect(assigns)

    ~H"""
    <div class="mt-2">
      <div> Deployment Instances </div>
      <table class="max-w-5xl table-auto">
        <thead class="justify-between">
          <tr class="bg-gray-100 text-sm">
            <th class="px-2 py-2">
              <span class="text-white-100 font-semibold">Desired</span>
            </th>

            <th class="px-2 py-2">
              <span class="text-white-100 font-semibold">Placed</span>
            </th>

            <th class="px-2 py-2">
              <span class="text-green-600 font-semibold">Healthy</span>
            </th>

            <th class="px-2 py-2">
              <span class="text-red-600 font-semibold">Unhealthy</span>
            </th>

          </tr>
        </thead>
        <tbody class="bg-gray-200">
          <tr class="bg-white border-b-2 border-gray-200 text-sm">

            <td class="px-2 py-2">
              <span class="px-4 py-2"><%= assigns.depl_status["desiredCount"] %></span>
            </td>

            <td class="px-2 py-2">
              <span class="px-4 py-2"><%= assigns.depl_status["placedCount"] %></span>
            </td>

            <td class="px-2 py-2">
              <span class="px-4 py-2"><%= assigns.depl_status["healthyCount"] %></span>
            </td>

            <td class="px-2 py-2">
              <span class="px-4 py-2"><%= assigns.depl_status["unhealthyCount"] %></span>
            </td>

          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  def instances_table(assigns) do
    IO.inspect(assigns)

    ~H"""
    <div class="mt-2">
      <table class="max-w-screen table-auto">
        <thead class="justify-between">
          <tr class="bg-gray-100 text-sm">
            <th class="px-2 py-2">
              <span class="text-white-100 font-semibold">ID</span>
            </th>

            <th class="px-2 py-2">
              <span class="text-white-100 font-semibold">Task</span>
            </th>

            <th class="px-2 py-2">
              <span class="text-white-100 font-semibold">Version</span>
            </th>

            <th class="px-2 py-2">
              <span class="text-white-100 font-semibold">Region</span>
            </th>

            <th class="px-2 py-2">
              <span class="text-white-100 font-semibold">Desired</span>
            </th>

            <th class="px-2 py-2">
              <span class="text-white-100 font-semibold">Status</span>
            </th>

            <th class="px-2 py-2">
              <span class="text-white-100 font-semibold">Health Checks</span>
            </th>

            <th class="px-2 py-2">
              <span class="text-white-100 font-semibold">Restarts</span>
            </th>

            <th class="px-2 py-2">
              <span class="text-white-100 font-semibold">Created</span>
            </th>

          </tr>
        </thead>
        <tbody class="bg-gray-200">

          <%= for alloc <- assigns.allocations do %>
            <tr class="bg-white border-b-2 border-gray-200 text-right text-sm">

              <td class="px-2 py-2">
                <span class="px-2 py-2"><%= alloc["idShort"] %></span>
              </td>

              <td class="px-2 py-2">
                <span class="px-2 py-2"><%= alloc["taskName"] %></span>
              </td>

              <td class="px-2 py-2">
                <span class="px-2 py-2"><%= alloc["version"] %></span>
              </td>

              <td class="px-2 py-2">
                <span class="px-2 py-2"><%= alloc["region"] %></span>
              </td>

              <td class="px-2 py-2">
                <span class="px-2 py-2"><%= alloc["desiredStatus"] %></span>
              </td>

              <td class="px-2 py-2">
                <span class="px-2 py-2"><%= alloc["status"] %></span>
              </td>

              <td class="px-2 py-2">
                <span class="px-2 py-2 whitespace-pre-wrap text-right"><%= "#{alloc["totalCheckCount"]} total,\n #{alloc["passingCheckCount"]} passing" %></span>
              </td>

              <td class="px-2 py-2">
                <span class="px-2 py-2"><%= alloc["restarts"] %></span>
              </td>

              <td class="px-2 py-2">
                <span class="px-2 py-2"><%= "#{format_created_at(alloc["createdAt"])} ago" %></span>
              </td>
            </tr>

          <% end %>
        </tbody>
      </table>
    </div>
    """
  end

  defp format_created_at(started_dt) do
    with {:ok, now} <- DateTime.now("Etc/UTC"),
         {:ok, started_at, 0} <- DateTime.from_iso8601(started_dt) do
      DateTime.diff(now, started_at, :second)
      |> format_duration()
    else
      error ->
        Logger.error("Failed to format created_at field for instance: Error: #{inspect(error)}")
        "@ERROR"
    end
  end

  defp format_duration(seconds) do
    ~T[00:00:00]
    |> Time.add(seconds)
    |> Calendar.strftime("%-0X")
  end

  def loading_svg(assigns) do
    ~H"""

    <svg class="fill-current text-white-500 h-2" viewBox="0 0 120 30" xmlns="http://www.w3.org/2000/svg">
    <circle cx="15" cy="15" r="15">
        <animate attributeName="r" from="15" to="15"
                 begin="0s" dur="0.8s"
                 values="15;9;15" calcMode="linear"
                 repeatCount="indefinite" />
        <animate attributeName="fill-opacity" from="1" to="1"
                 begin="0s" dur="0.8s"
                 values="1;.5;1" calcMode="linear"
                 repeatCount="indefinite" />
    </circle>
    <circle cx="60" cy="15" r="9" fill-opacity="0.3">
        <animate attributeName="r" from="9" to="9"
                 begin="0s" dur="0.8s"
                 values="9;15;9" calcMode="linear"
                 repeatCount="indefinite" />
        <animate attributeName="fill-opacity" from="0.5" to="0.5"
                 begin="0s" dur="0.8s"
                 values=".5;1;.5" calcMode="linear"
                 repeatCount="indefinite" />
    </circle>
    <circle cx="105" cy="15" r="15">
        <animate attributeName="r" from="15" to="15"
                 begin="0s" dur="0.8s"
                 values="15;9;15" calcMode="linear"
                 repeatCount="indefinite" />
        <animate attributeName="fill-opacity" from="1" to="1"
                 begin="0s" dur="0.8s"
                 values="1;.5;1" calcMode="linear"
                 repeatCount="indefinite" />
    </circle>
    </svg>
    """
  end
end
