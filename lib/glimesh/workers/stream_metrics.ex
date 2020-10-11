defmodule Glimesh.Workers.StreamMetrics do
  use GenServer

  require Logger
  alias Glimesh.Streams

  @interval 60_000

  def start_link(_init_args) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    Process.send_after(self(), :count_viewers, @interval)
    {:ok, %{last_run_at: nil}}
  end

  def handle_info(:count_viewers, _state) do
    Logger.info("Counting live channel viewers")
    count_current_viewers()
    Process.send_after(self(), :count_viewers, @interval)

    {:noreply, %{last_run_at: :calendar.local_time()}}
  end

  defp count_current_viewers do
    channels = Streams.list_live_channels()

    Enum.map(channels, fn channel ->
      count_viewers =
        Streams.get_subscribe_topic(:viewers, channel.id)
        |> IO.inspect()
        |> Glimesh.Presence.list_presences()
        |> IO.inspect()
        |> Enum.count()

      Streams.update_stream(channel.stream, %{
        count_viewers: count_viewers
      })
    end)
  end
end
