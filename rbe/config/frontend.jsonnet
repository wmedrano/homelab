// BuildBarn Storage Frontend - RBE API endpoint
// Serves the CAS, Action Cache, and Execution APIs on port 8980.
// No authentication (insecure mode) for homelab SSH-tunnel access.
//
// The storage frontend proxies to the backend storage instance on port 8981.

local common = import 'common.libsonnet';

{
  grpcServers: [{
    listenAddresses: [':8980'],
    authenticationPolicy: { allow: {} },
  }],
  schedulers: {
    '': {
      endpoint: {
        address: 'buildbarn-scheduler:8982',
        addMetadataJmespathExpression: {
          expression: |||
            {
              "build.bazel.remote.execution.v2.requestmetadata-bin": incomingGRPCMetadata."build.bazel.remote.execution.v2.requestmetadata-bin"
            }
          |||,
        },
      },
    },
  },
  maximumMessageSizeBytes: common.maximumMessageSizeBytes,
  global: common.global,
  contentAddressableStorage: {
    backend: common.blobstore.contentAddressableStorage,
    getAuthorizer: { allow: {} },
    putAuthorizer: { allow: {} },
    findMissingAuthorizer: { allow: {} },
  },
  actionCache: {
    backend: common.blobstore.actionCache,
    getAuthorizer: { allow: {} },
    putAuthorizer: { allow: {} },
  },
  fileSystemAccessCache: {
    backend: common.fileSystemAccessCache,
    getAuthorizer: { allow: {} },
    putAuthorizer: { allow: {} },
  },
  executeAuthorizer: { allow: {} },
}