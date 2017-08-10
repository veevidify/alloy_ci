defmodule AlloyCi.Workers.FetchReposWorker do
  @moduledoc """
  """
  use Que.Worker
  alias AlloyCi.{Accounts, Project, ProjectPermission, Web.ProjectView}

  @github_api Application.get_env(:alloy_ci, :github_api)

  def perform({user_id, csrf_token}) do
    auth =
      user_id
      |> Accounts.get_user!
      |> Accounts.github_auth

    AlloyCi.Web.Endpoint.broadcast(
      "repos:#{user_id}",
      "repos_ready",
      %{html: rendered_content(auth, csrf_token)}
    )
  end

  def rendered_content(auth, csrf_token) do
    Phoenix.View.render_to_string(
      ProjectView,
      "repos.html",
      existing_ids: ProjectPermission.existing_ids,
      is_installed: Accounts.installed_on_owner?(auth.uid),
      repos: @github_api.fetch_repos(auth.token),
      changeset: Project.changeset(%Project{}),
      csrf: csrf_token
    )
  end
end
