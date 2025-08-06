FactoryBot.define do
  factory :user_sport do
    user { nil }
    sport { nil }
    position { "MyString" }
    skill_level { 1 }
    years_experience { 1 }
    primary { false }
  end
end
