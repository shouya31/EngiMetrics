# frozen_string_literal: true

require 'httparty'
require 'date'

class GithubCodeMetricsFetcherService
  USERS_EVENT_ENDPOINT = "https://api.github.com/users/%{username}/events"

  def initialize(username, github_token)
    @username = username
    @github_token = github_token
  end

  def call
    yesterday = Date.yesterday

    response = HTTParty.get(USERS_EVENT_ENDPOINT, headers: { "Authorization" => "token #{@github_token}" })

    # TODO: メモリを節約するために、push_eventsをresponseから抽出する
    push_events = response.select { |event| event["type"] == "PushEvent" && Date.parse(event["created_at"]) == yesterday }

    total_characters = 0

    push_events.each do |event|
      event["payload"]["commits"].each do |commit|
        commit_url = commit["url"]
        commit_data = HTTParty.get(commit_url, headers: { "Authorization" => "token #{@github_token}" })

        commit_data["files"].each do |file|
          changes = file["patch"].to_s
          total_characters += changes.length
        end
      end
    end

    total_characters
  end
end

