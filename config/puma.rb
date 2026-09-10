max_threads_count = Integer(ENV.fetch("RAILS_MAX_THREADS", 5))
min_threads_count = Integer(ENV.fetch("RAILS_MIN_THREADS", max_threads_count))
threads min_threads_count, max_threads_count

# 開発環境ではデフォルト0（シングルモード）。本番投入時にWEB_CONCURRENCYを設定してcluster modeへ。
web_concurrency = Integer(ENV.fetch("WEB_CONCURRENCY", 0))
if web_concurrency.positive?
  workers web_concurrency
  preload_app!
end

port ENV.fetch("PORT", 3000)
environment ENV.fetch("RAILS_ENV", "development")

plugin :tmp_restart

pidfile ENV["PIDFILE"] if ENV["PIDFILE"]
