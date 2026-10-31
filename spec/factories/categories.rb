FactoryBot.define do
  factory :category do
    budget { association :budget }
    name { Faker::Commerce.department(max: 1) }
  end
end
