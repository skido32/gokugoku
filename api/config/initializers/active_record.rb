# 日時は、すべてタイムゾーンつき(timestamptz)で保存する(design.md 4.5)
ActiveSupport.on_load(:active_record_postgresqladapter) do
  self.datetime_type = :timestamptz
end
