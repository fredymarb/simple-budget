FactoryBot.define do
  factory :budget do
    user { association :user }

    name { Faker::Lorem.word }
    currency { Faker::Currency.code }
  end
end
