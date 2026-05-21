# -*- bazel-starlark -*-
# Siso backend configuration for BuildBarn RBE
#
# Copy this file to your Chromium checkout at:
#   build/config/siso/backend_config/backend.star
#
# Then build with:
#   autoninja -C out/Default --config=buildbarn
#
# Or set the REAPI address explicitly:
#   siso build -C out/Default --reapi-address=localhost:8980

load("@builtin//struct.star", "module")

def __platform_properties(ctx):
    # The container-image must match the worker's platform properties
    # in the BuildBarn worker config (worker.jsonnet).
    # This is the siso-chromium image from Google's RBE infrastructure.
    container_image = "docker://gcr.io/chops-public-images-prod/rbe/siso-chromium/linux@sha256:d7cb1ab14a0f20aa669c23f22c15a9dead761dcac19f43985bf9dd5f41fbef3a"
    return {
        "default": {
            "OSFamily": "Linux",
            "container-image": container_image,
            "label:action_default": "1",
        },
        "large": {
            "OSFamily": "Linux",
            "container-image": container_image,
            "label:action_large": "1",
        },
    }

def __configs(ctx):
    # This backend is always active when specified via --reapi-address
    return ["buildbarn"]

backend = module(
    "backend",
    platform_properties = __platform_properties,
    configs = __configs,
)