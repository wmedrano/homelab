// BuildBarn Worker - hardlinking mode
//
// Uses hardlinking (not FUSE) so no --privileged flag is needed,
// making it compatible with rootless Podman.
//
// Connects to the scheduler on buildbarn-scheduler:8983.
// The runner listens on a unix socket at /worker/runner which
// is shared with the buildbarn-runner container via volume.
//
// Platform properties advertise the siso-chromium container image
// which must match the runner's container image.

local common = import 'common.libsonnet';

{
  blobstore: common.blobstore,
  browserUrl: common.browserUrl,
  maximumMessageSizeBytes: common.maximumMessageSizeBytes,
  scheduler: { address: 'buildbarn-scheduler:8983' },
  global: common.global,
  buildDirectories: [{
    native: {
      buildDirectoryPath: '/worker/build',
      cacheDirectoryPath: '/worker/cache',
      maximumCacheFileCount: 10000,
      maximumCacheSizeBytes: 10 * 1024 * 1024 * 1024,  // 10 GiB cache
      cacheReplacementPolicy: 'LEAST_RECENTLY_USED',
    },
    runners: [{
      endpoint: { address: 'unix:///worker/runner' },
      concurrency: 8,
      instanceNamePrefix: 'hardlinking',
      platform: {
        properties: [
          { name: 'OSFamily', value: 'linux' },
          // Must match the runner's container image - this is the siso-chromium
          // image used by Google's RBE for Chromium builds.
          { name: 'container-image', value: 'docker://gcr.io/chops-public-images-prod/rbe/siso-chromium/linux@sha256:d7cb1ab14a0f20aa669c23f22c15a9dead761dcac19f43985bf9dd5f41fbef3a' },
        ],
      },
      workerId: {
        datacenter: 'homelab',
        rack: '1',
        slot: '1',
        hostname: 'buildbarn-worker',
      },
    }],
  }],
  inputDownloadConcurrency: 10,
  outputUploadConcurrency: 11,
  directoryCache: {
    maximumCount: 1000,
    maximumSizeBytes: 1000 * 1024,
    cacheReplacementPolicy: 'LEAST_RECENTLY_USED',
  },
}