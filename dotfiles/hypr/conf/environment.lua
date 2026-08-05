-- -----------------------------------------------------
-- Environment Variables (migrated from conf/environment.conf)
-- name: "Nvidia"
-- -----------------------------------------------------

-- NVIDIA https://wiki.hypr.land/Nvidia/
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("SDL_VIDEODRIVER", "wayland")
-- hl.env("WLR_DRM_NO_ATOMIC", "1")
-- hl.env("__GL_VRR_ALLOWED", "1")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("__NV_PRIME_RENDER_OFFLOAD", "1")
hl.env("__VK_LAYER_NV_optimus", "NVIDIA_only")

-- WLR_NO_HARDWARE_CURSORS forced software cursors, which on modern NVIDIA
-- drivers causes a doubled cursor (software cursor + driver's hardware cursor
-- plane). Disabled; handled by cursor:no_hardware_cursors below instead.
hl.env("WLR_RENDERER_ALLOW_SOFTWARE", "1")

-- nvidia firefox (for hardware acceleration on FF)
-- check https://github.com/elFarto/nvidia-vaapi-driver#configuration
hl.env("MOZ_DISABLE_RDD_SANDBOX", "1")
hl.env("EGL_PLATFORM", "wayland")

hl.config({
    cursor = {
        no_hardware_cursors = false,
    },
})
