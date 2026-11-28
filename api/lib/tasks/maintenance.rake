namespace :maintenance do
  desc "保持期間を過ぎたデータと、不要になった認証情報を消す(1日1回、外から定期実行する)"
  task cleanup: :environment do
    counts = Maintenance::Cleanup.call
    Rails.logger.info("maintenance:cleanup #{counts.to_json}")
    puts counts.to_json
  end
end
