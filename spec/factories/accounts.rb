FactoryBot.define do
  factory :account do
    budget { association :budget }
    name { Faker::Lorem.word }
  end
end
