require 'securerandom'

FactoryBot.define do
  factory :transaction do
    association :budget
    association :account
    category { association :category }

    date { Date.current }
    kind { :expense }
    amount_minor { 10_000 }
    memo { "Test transaction" }

    trait :income do
      kind { :income }
    end

    trait :expense do
      kind { :expense }
    end

    trait :transfer do
      kind { :transfer }
      category { nil }
      transfer_group_id { SecureRandom.uuid }
    end

    trait :starting_balance do
      kind { :starting_balance }
    end
  end
end
