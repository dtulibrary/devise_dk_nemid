include 'securerandom'

module Devise::DkNemid
  class ChallengeGenerator
    CHALLENGE_SESSION_KEY = "devise_dk_nemid_challenge"

    def self.generate_challenge
      session[CHALLENGE_SESSION_KEY] = SecureRandom.base64(21)
    end
  end
end
