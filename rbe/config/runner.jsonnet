// BuildBarn Runner
// Runs inside the siso-chromium container so that build actions
// have access to the Chromium build toolchain.
//
// Listens on unix socket /worker/runner for the worker to connect.
// No authentication (insecure) for homelab use.

local common = import 'common.libsonnet';

{
  buildDirectoryPath: '/worker/build',
  global: common.global,
  grpcServers: [{
    listenPaths: ['/worker/runner'],
    authenticationPolicy: { allow: {} },
  }],
}