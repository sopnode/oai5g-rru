## Performance tuning on 2-NUMA sopnode server

The following setup works not too badly both for AW2S scenario and N3XX USRP scenarios.

#### grub configuration

```
biosdevname=0 net.ifnames=0 mitigations=off intel_iommu=on iommu=pt selinux=0 enforcing=0 isolcpus=managed_irq,8-35 nohz_full=8-35 nohz=on rcu_nocbs=8-35 kthread_cpus=0,1 irqaffinity=0,1 rcu_nocb_poll nosoftlockup intel_iommu=on iommu=pt skew_tick=1 tsc=nowatchdog nmi_watchdog=0 softlockup_panic=0 audit=0 intel_pstate=disable idle=poll
```

#### /etc/systemd/system.conf 

Add the line :

```
CPUAffinity=2-7
```

#### /etc/sysctl.conf :

```
## For kubernetes
fs.inotify.max_user_instances=65536
## Realtime kernel settings
kernel.sched_rt_runtime_us=-1
kernel.timer_migration=0 
```

#### kubeadm k8s config

Add following:

```
---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
# kubelet specific options here
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
cgroupDriver: systemd
cpuManagerPolicy: static
cpuManagerPolicyOptions:
   "full-pcpus-only": "true"
reservedSystemCPUs: 0-7
memorySwap: {}
failSwapOn: false
containerLogMaxSize: 50Mi
featureGates:
   CPUManager: true
   CPUManagerPolicyOptions: true
   CPUManagerPolicyBetaOptions: true
---
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
ipvs:
  strictARP: true
```


#### in gnb.conf :

```
        L1_rx_thread_core = 8;
        L1_tx_thread_core = 10;

        num_tp_cores   = 8;
        rxfh_core_id   = 12;
        txfh_core_id   = 14;
        tp_cores       = [16,18,20,22,24,26,28,30];
```

#### nr-softmodem command line :

```
“/opt/oai-gnb-aw2s/bin/nr-softmodem” “-O” “/tmp/gnb.conf” “--sa” “--thread-pool” “9,11,13,15,17,19,21,23" “--log_config.global_log_options” “level,nocolor,time”
```

### Parameters check

```
root@sopnode-w1 # cat /proc/cmdline

BOOT_IMAGE=(hd0,msdos1)/vmlinuz-5.14.0-503.15.1.el9_5.x86_64 root=/dev/mapper/rl_sopnode--w1-root ro crashkernel=1G-4G:192M,4G-64G:256M,64G-:512M resume=/dev/mapper/rl_sopnode--w1-swap rd.lvm.lv=rl_sopnode-w1/root rd.lvm.lv=rl_sopnode-w1/swap rhgb quiet biosdevname=0 net.ifnames=0 mitigations=off intel_iommu=on iommu=pt selinux=0 enforcing=0 isolcpus=managed_irq,8-35 nohz_full=8-35 nohz=on rcu_nocbs=8-35 kthread_cpus=0,1 irqaffinity=0,1 rcu_nocb_poll nosoftlockup intel_iommu=on iommu=pt skew_tick=1 tsc=nowatchdog nmi_watchdog=0 softlockup_panic=0 audit=0 intel_pstate=disable idle=poll vt.color=0x17
```

```
root@sopnode-w1 ~# numactl --hardware
available: 2 nodes (0-1)
node 0 cpus: 0 2 4 6 8 10 12 14 16 18 20 22 24 26 28 30 32 34
node 0 size: 31558 MB
node 0 free: 17196 MB
node 1 cpus: 1 3 5 7 9 11 13 15 17 19 21 23 25 27 29 31 33 35
node 1 size: 32205 MB
node 1 free: 18817 MB
node distances:
node     0    1
   0:   10   21
   1:   21   10
```


```
root@sopnode-w1 ~# numactl -s

policy: default
preferred node: current
physcpubind: 2 3 4 5 6 7
cpubind: 0 1
nodebind: 0 1
membind: 0 1
```

```
root@sopnode-w1 ~# numastat
                           node0           node1
numa_hit               369550708       147589049
numa_miss                      0               0
numa_foreign                   0               0
interleave_hit              2236            2750
local_node             368969457       147569994
other_node                581251           19055
```



```
root@sopnode-w1 ~# cpupower monitor

intel-rapl/intel-rapl:0
0
intel-rapl/intel-rapl:0/intel-rapl:0:0
0
              | Nehalem                   || Mperf              || RAPL
 PKG|CORE| CPU| C3   | C6   | PC3  | PC6   || C0   | Cx   | Freq  || pack | dram
   0|   0|   0|  0.00|  0.00|  0.00|  0.00||100.00|  0.00|  3888||140900518|1699234
   0|   1|   4|  0.00|  0.00|  0.00|  0.00||100.00|  0.00|  3888||140900518|1699234
   0|   2|   8|  0.00|  0.00|  0.00|  0.00||100.00|  0.00|  3888||140900518|1699234
   0|   3|   6|  0.00|  0.00|  0.00|  0.00||100.00|  0.00|  3888||140900518|1699234
   0|   4|   2|  0.00|  0.00|  0.00|  0.00||100.00|  0.00|  3888||140900518|1699234
   0|   8|  12|  0.00|  0.00|  0.00|  0.00||100.00|  0.00|  3888||140900518|1699234
   0|   9|  16|  0.00|  0.00|  0.00|  0.00||100.00|  0.00|  3888||140900518|1699234
   0|  10|  14|  0.00|  0.00|  0.00|  0.00||100.00|  0.00|  3888||140900518|1699234
   0|  11|  10|  0.00|  0.00|  0.00|  0.00||100.00|  0.00|  3888||140900518|1699234
   0|  16|  20|  0.00|  0.00|  0.00|  0.00||100.00|  0.00|  3888||140900518|1699234
   0|  17|  24|  0.00|  0.00|  0.00|  0.00||100.00|  0.00|  3888||140900518|1699234
   0|  18|  26|  0.00|  0.00|  0.00|  0.00||100.00|  0.00|  3888||140900518|1699234
   0|  19|  22|  0.00|  0.00|  0.00|  0.00||100.00|  0.00|  3888||140900518|1699234
   0|  20|  18|  0.00|  0.00|  0.00|  0.00||100.00|  0.00|  3888||140900518|1699234
   0|  24|  28|  0.00|  0.00|  0.00|  0.00||100.00|  0.00|  3888||140900518|1699234
   0|  25|  32|  0.00|  0.00|  0.00|  0.00||100.00|  0.00|  3888||140900518|1699234
   0|  26|  34|  0.00|  0.00|  0.00|  0.00||100.00|  0.00|  3888||140900518|1699234
   0|  27|  30|  0.00|  0.00|  0.00|  0.00||100.00|  0.00|  3888||140900518|1699234
   1|   0|   1|  0.00|  0.00|  0.00|  0.00||100.00|  0.00|  3888||140900518|1699234
   1|   1|   5|  0.00|  0.00|  0.00|  0.00||100.00|  0.00|  3888||140900518|1699234
   1|   2|   9|  0.00|  0.00|  0.00|  0.00||100.00|  0.00|  3888||140900518|1699234
   1|   3|   7|  0.00|  0.00|  0.00|  0.00||100.00|  0.00|  3888||140900518|1699234
   1|   4|   3|  0.00|  0.00|  0.00|  0.00||100.00|  0.00|  3888||140900518|1699234
   1|   8|  13|  0.00|  0.00|  0.00|  0.00||100.00|  0.00|  3888||140900518|1699234
   1|   9|  17|  0.00|  0.00|  0.00|  0.00||100.00|  0.00|  3888||140900518|1699234
   1|  10|  15|  0.00|  0.00|  0.00|  0.00||100.00|  0.00|  3888||140900518|1699234
   1|  11|  11|  0.00|  0.00|  0.00|  0.00||100.00|  0.00|  3888||140900518|1699234
   1|  16|  21|  0.00|  0.00|  0.00|  0.00||100.00|  0.00|  3888||140900518|1699234
   1|  17|  25|  0.00|  0.00|  0.00|  0.00||100.00|  0.00|  3888||140900518|1699234
   1|  18|  27|  0.00|  0.00|  0.00|  0.00||100.00|  0.00|  3888||140900518|1699234
   1|  19|  23|  0.00|  0.00|  0.00|  0.00||100.00|  0.00|  3888||140900518|1699234
   1|  20|  19|  0.00|  0.00|  0.00|  0.00||100.00|  0.00|  3888||140900518|1699234
   1|  24|  29|  0.00|  0.00|  0.00|  0.00||100.00|  0.00|  3888||140900518|1699234
   1|  25|  33|  0.00|  0.00|  0.00|  0.00||100.00|  0.00|  3888||140900518|1699234
   1|  26|  35|  0.00|  0.00|  0.00|  0.00||100.00|  0.00|  3888||140900518|1699234
   1|  27|  31|  0.00|  0.00|  0.00|  0.00||100.00|  0.00|  3888||140900518|1699234
```

```
root@sopnode-w1 ~# taskset -pc $$
pid 2395076's current affinity list: 2-7
```


