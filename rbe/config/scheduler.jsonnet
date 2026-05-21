// BuildBarn Scheduler
// Dispatches build actions to workers.
// No authentication (insecure) - homelab only, access via SSH tunnel.
//
// Endpoints:
//   8982 - gRPC client (frontend connects here)
//   8983 - gRPC worker  (bb_worker connects here)
//   8984 - gRPC build queue state
//   7982 - HTTP admin/metrics

local common = import 'common.libsonnet';

{
  adminHttpServers: [{
    listenAddresses: [':7982'],
    authenticationPolicy: { allow: {} },
  }],
  clientGrpcServers: [{
    listenAddresses: [':8982'],
    authenticationPolicy: { allow: {} },
  }],
  workerGrpcServers: [{
    listenAddresses: [':8983'],
    authenticationPolicy: { allow: {} },
  }],
  buildQueueStateGrpcServers: [{
    listenAddresses: [':8984'],
    authenticationPolicy: { allow: {} },
  }],
  browserUrl: common.browserUrl,
  contentAddressableStorage: common.blobstore.contentAddressableStorage,
  maximumMessageSizeBytes: common.maximumMessageSizeBytes,
  global: common.global,
  executeAuthorizer: { allow: {} },
  modifyDrainsAuthorizer: { allow: {} },
  killOperationsAuthorizer: { allow: {} },
  synchronizeAuthorizer: { allow: {} },
  actionRouter: {
    simple: {
      platformKeyExtractor: { action: {} },
      invocationKeyExtractors: [
        { correlatedInvocationsId: {} },
        { toolInvocationId: {} },
      ],
      initialSizeClassAnalyzer: {
        defaultExecutionTimeout: '3600s',   // 1 hour default for large Chromium actions
        maximumExecutionTimeout: '14400s',  // 4 hours max
      },
    },
  },
  platformQueueWithNoWorkersTimeout: '900s',
}