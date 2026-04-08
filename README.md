# pvm-builds

Concrete AWS PVM build inputs for downstream consumers like `infra`.

This repo exists to export the exact flake attrs that `infra` expects in its
`prod.env` and AWS image pipeline:

- `packages.x86_64-linux.linux-port-pvm`
- `packages.x86_64-linux.linux-port-pvm-guest`
- `packages.x86_64-linux.firecracker-pvm`

Current upstream sources:

- kernel: `virt-pvm/linux` branch `pvm-612`
- Firecracker: `loopholelabs/firecracker` branch `main-live-migration-pvm`

The exported packages are the concrete build layer below Port's host-kit
contract:

- Port owns the host-kit contract and NixOS module surface
- `pvm-builds` owns the concrete patched kernel and VMM derivations
- `infra` consumes those derivations to build and import the AWS AMI
- Port's hosted PVM guest artifact pipeline can also consume the dedicated
  `linux-port-pvm-guest` derivation for `x86_64/firecracker/pvm`

Typical downstream wiring:

```bash
export INFRA_AWS_PVM_BUILD_FLAKE_REF=git+file:///home/alex/workspace/spoke-sh/pvm-builds
export INFRA_AWS_PVM_KERNEL_ATTR=packages.x86_64-linux.linux-port-pvm
export INFRA_AWS_PVM_FIRECRACKER_ATTR=packages.x86_64-linux.firecracker-pvm
```

Kernel contract notes:

- AWS PVM hosts run K3s directly on this kernel, so kube-proxy and CNI hostport
  flows need working xtables support.
- AWS PVM hosts must expose the host-side PVM path, not just guest support.
  Keep `CONFIG_EXPERT=y`, `CONFIG_KVM=y`, `CONFIG_KVM_SW_PROTECTED_VM=y`, and
  `CONFIG_KVM_PVM=y` enabled when rebasing the kernel.
- PVM guests need a separate kernel contract from the host image. Keep
  `CONFIG_X86_PIE=y` and `CONFIG_PVM_GUEST=y` enabled for the
  `linux-port-pvm-guest` derivation so the guest lane does not silently reuse
  the standard Firecracker kernel.
- Firecracker guests on the PVM lane still surface block, net, and vsock
  devices over `virtio_mmio`, so keep `CONFIG_VIRTIO_MMIO=y` and
  `CONFIG_VIRTIO_MMIO_CMDLINE_DEVICES=y` enabled for the
  `linux-port-pvm-guest` derivation, along with guest-side vsock support via
  `CONFIG_VSOCKETS=y` and `CONFIG_VIRTIO_VSOCKETS=y`.
- Hosted K3s on the PVM guest lane expects flannel VXLAN and standard pod
  networking to work without a module-loading step. Keep `CONFIG_TUN=y`,
  `CONFIG_BRIDGE=y`, `CONFIG_BRIDGE_NETFILTER=y`,
  `CONFIG_NET_UDP_TUNNEL=y`, `CONFIG_VXLAN=y`, and `CONFIG_VETH=y` enabled for
  the `linux-port-pvm-guest` derivation.
- Hosted K3s guests also need the standard container namespace surface. Keep
  `CONFIG_NAMESPACES=y`, `CONFIG_UTS_NS=y`, `CONFIG_IPC_NS=y`,
  `CONFIG_NET_NS=y`, `CONFIG_PID_NS=y`, `CONFIG_CGROUP_NS=y`, and
  `CONFIG_TIME_NS=y` enabled for the `linux-port-pvm-guest` derivation so
  containerd and kubelet can resolve `/proc/<pid>/ns/*` entries correctly.
- Keep `CONFIG_NETFILTER_XT_MATCH_STATISTIC=y` and
  `CONFIG_NETFILTER_XT_MATCH_MULTIPORT=y` enabled when rebasing the kernel.
