FactoryBot.define do
  factory :account do
    budget { association :budget }
    sequence(:name) { |n| "#{Faker::Lorem.word} #{n}" }
  end
end
