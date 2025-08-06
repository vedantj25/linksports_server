FactoryBot.define do
  factory :profile do
    user { nil }
    type { "" }
    first_name { "MyString" }
    last_name { "MyString" }
    display_name { "MyString" }
    bio { "MyText" }
    date_of_birth { "2025-08-03" }
    gender { 1 }
    location_city { "MyString" }
    location_state { "MyString" }
    location_country { "MyString" }
    website_url { "MyString" }
    instagram_url { "MyString" }
    youtube_url { "MyString" }
  end
end
