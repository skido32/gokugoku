# 招待コード・引き継ぎコードの生成と照合(design.md 2.2)。
# 桁数が短く総当たりの余地があるため、平文ではなく秘密鍵つきの HMAC を保存する。
module SecretCode
  # 紛らわしい文字(0, 1, I, O)を除いた32種
  ALPHABET = "23456789ABCDEFGHJKLMNPQRSTUVWXYZ".chars.freeze

  module_function

  def generate(length)
    Array.new(length) { ALPHABET[SecureRandom.random_number(ALPHABET.size)] }.join
  end

  # 入力の揺れ(小文字、区切りのハイフンや空白)を吸収する
  def normalize(code)
    code.to_s.upcase.delete("^0-9A-Z")
  end

  def digest(code, purpose:)
    OpenSSL::HMAC.hexdigest("SHA256", key(purpose), normalize(code))
  end

  # secret_key_base から用途ごとに鍵を作る(新しい秘密情報を増やさない)
  def key(purpose)
    Rails.application.key_generator.generate_key("secret_code/#{purpose}", 32)
  end
end
