// BuildBarn common configuration for homelab deployment
// Adapted from https://github.com/buildbarn/bb-deployments
//
// Single-node setup: no sharding, one storage instance,
// insecure (no auth), all services on buildbarn network.

{
  blobstore: {
    // Single storage backend (no sharding needed for homelab)
    contentAddressableStorage: {
      grpc: {
        client: {
          address: 'buildbarn-storage:8981',
        },
      },
    },
    actionCache: {
      completenessChecking: {
        backend: {
          grpc: {
            client: {
              address: 'buildbarn-storage:8981',
            },
          },
        },
        maximumTotalTreeSizeBytes: 64 * 1024 * 1024,
      },
    },
  },
  fileSystemAccessCache: {
    grpc: {
      client: {
        address: 'buildbarn-storage:8981',
      },
    },
  },
  browserUrl: 'http://localhost:7984',
  maximumMessageSizeBytes: 64 * 1024 * 1024,  // 64 MiB for large Chromium actions
  global: {
    diagnosticsHttpServer: {
      httpServers: [{
        listenAddresses: [':9980'],
        authenticationPolicy: { allow: {} },
      }],
      enablePrometheus: true,
      enablePprof: true,
      enableActiveSpans: true,
    },
  },
}