# pvm-builds

Concrete AWS PVM build inputs for downstream consumers like `infra`.

This repo exists to export the exact flake attrs that `infra` expects in its
`prod.env` and AWS image pipeline:

- `packages.x86_64-linux.linux-port-pvm`
- `packages.x86_64-linux.firecracker-pvm`

Current upstream sources:

- kernel: `virt-pvm/linux` branch `pvm-612`
- Firecracker: `loopholelabs/firecracker` branch `main-live-migration-pvm`

The exported packages are the concrete build layer below Port's host-kit
contract:

- Port owns the host-kit contract and NixOS module surface
- `pvm-builds` owns the concrete patched kernel and VMM derivations
- `infra` consumes those derivations to build and import the AWS AMI

Typical downstream wiring:

```bash
export INFRA_AWS_PVM_BUILD_FLAKE_REF=git+file:///home/alex/workspace/spoke-sh/pvm-builds
export INFRA_AWS_PVM_KERNEL_ATTR=packages.x86_64-linux.linux-port-pvm
export INFRA_AWS_PVM_FIRECRACKER_ATTR=packages.x86_64-linux.firecracker-pvm
```

Kernel contract notes:

- AWS PVM hosts run K3s directly on this kernel, so kube-proxy and CNI hostport
  flows need working xtables support.
- Keep `CONFIG_NETFILTER_XT_MATCH_STATISTIC=y` and
  `CONFIG_NETFILTER_XT_MATCH_MULTIPORT=y` enabled when rebasing the kernel.
