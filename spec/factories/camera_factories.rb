FactoryGirl.define do
  factory :camera do

    sequence(:exid) { |n| "exid#{n}" }
    sequence(:name) { |n| "name#{n}" }

    association :owner, factory: :user

    is_public true
    is_online true

    config({
      snapshots: {
        jpg: '/onvif/snapshot'
      },
      auth: {
        basic: {
          username: 'abcd',
          password: 'wxyz'
        }
      }
    })

  end

  factory :camera_endpoint do
    association :camera, factory: :camera
    scheme 'http'
    host 'www.evercam.test'
    port 80
  end
end
