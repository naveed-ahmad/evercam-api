module Evercam
  module CacheHelper

    def invalidate_for_user(username)
      ['true', 'false', ''].repeated_permutation(2) do |a|
        Evercam::Services::dalli_cache.delete("cameras|#{username}|#{a[0]}|#{a[1]}")
      end

      Pusher.trigger_async(username, 'user_cameras_changed', {})
    end

    def invalidate_for_camera(camera_exid)
      camera = Camera.by_exid!(camera_exid)
      invalidate_for_user(camera.owner.username)

      camera_sharees = CameraShare.where(camera_id: camera.id)
      unless camera_sharees.blank?
        camera_sharees.each do |user|
          username = User[user.user_id].username
          invalidate_for_user(username)
        end
      end

      Evercam::Services::dalli_cache.delete(camera_exid)
      Pusher.trigger_async(camera_exid, 'camera_changed', {})
    end
  end
end
