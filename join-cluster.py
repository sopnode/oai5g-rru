#!/usr/bin/env python3 -u


from argparse import ArgumentParser, ArgumentDefaultsHelpFormatter
from pathlib import Path

# the default for asyncssh is to be rather verbose
#import logging
#from asyncssh.logging import set_log_level as asyncssh_set_log_level

from asynciojobs import Job, Scheduler, PrintJob

from apssh import (LocalNode, SshNode, SshJob, Run, RunString, RunScript,
                   TimeHostFormatter, Service, Deferred, Capture, Variables)

# make sure to pip install r2lab
from r2lab import r2lab_hostname, r2lab_id, ListOfChoices, ListOfChoicesNullReset, find_local_embedded_script


default_master = 'sopnode-w1.inria.fr'

default_pb_node = 11
default_fit_worker_node = '2'
default_pc_worker_node = '0'

default_gateway  = 'faraday.inria.fr'
default_slicename  = 'inria_sopnode'

#default_image = 'u20.04-perf'
default_image = 'slices-worker'
default_bp_image = 'slices-docker-bp'

def _r2lab_name(x, prefix='fit'):
    return "{}{:02d}".format(prefix, r2lab_id(x))

def r2lab_pc_hostname(id):
    """
    returns R2lab pc hostname
    """
    return _r2lab_name(id, 'pc')

def run(*, gateway, slicename, master, bp, nodes, pcs,
        load_images=False, image, image_bp,
        verbose, dry_run,
        ):
    """
    add R2lab nodes as workers in a k8s cluster

    Arguments:
        slicename: the Unix login name (slice name) to enter the gateway
        master: k8s master node
        bp: node id for the FIT node used to run the ansible blueprint
        nodes: a list of FIT node ids to run the scenario on; strings or ints
                  are OK;
        pcs: a list of PC node ids to run the scenario on; strings or ints
                  are OK;
        node_master: the master node id, must be part of selected nodes
    """

    faraday = SshNode(hostname=gateway, username=slicename,
                      verbose=verbose,
                      formatter=TimeHostFormatter())

    bpnode =  SshNode(gateway=faraday, hostname=r2lab_hostname(bp),
                      username="root",formatter=TimeHostFormatter(),
                      verbose=verbose)

    node_index = {
        id: SshNode(gateway=faraday, hostname=r2lab_hostname(id),
                    username="root",formatter=TimeHostFormatter(),
                    verbose=verbose)
        for id in nodes
    }

    pc_index = {
        id: SshNode(gateway=faraday, hostname=r2lab_pc_hostname(id),
                    username="root",formatter=TimeHostFormatter(),
                    verbose=verbose)
        for id in pcs
    }

    fit_worker_ids = nodes[:]
    pc_worker_ids = pcs[:]

    # the global scheduler
    scheduler = Scheduler(verbose=verbose)

    ##########
    check_lease = SshJob(
        scheduler=scheduler,
        node = faraday,
        critical = True,
        verbose=verbose,
        command = Run("rhubarbe leases --check"),
    )

    green_light = check_lease
    pc_green_light = check_lease

    if load_images:
        if fit_worker_ids:
            green_light = [
                SshJob(
                    scheduler=scheduler,
                    required=check_lease,
                    node=faraday,
                    critical=True,
                    verbose=verbose,
                    label = f"Load image {image} on worker nodes",
                    commands=[
                        Run("rhubarbe", "load", *fit_worker_ids, "-i", image),
                        Run("rhubarbe", "wait", *fit_worker_ids),
                    ],
                ),
                SshJob(
                    scheduler=scheduler,
                    required=check_lease,
                    node=faraday,
                    critical=True,
                    verbose=verbose,
                    label = f"Load image {image_bp} on the bp node",
                    command=[
                        Run("rhubarbe", "load", bp, "-i", image_bp),
                        Run("rhubarbe", "wait", bp),
                    ]
                )
            ]
        else:
            green_light = [
                SshJob(
                    scheduler=scheduler,
                    required=check_lease,
                    node=faraday,
                    critical=True,
                    verbose=verbose,
                    label = f"Load image {image_bp} on the bp node",
                    command=[
                        Run("rhubarbe", "load", bp, "-i", image_bp),
                        Run("rhubarbe", "wait", bp),
                    ]
                )
            ]
        if pc_worker_ids:
            pc_green_light = [
                SshJob(
                    scheduler=scheduler,
                    required=check_lease,
                    node=faraday,
                    critical=True,
                    verbose=verbose,
                    label=f"switch on {r2lab_pc_hostname(id)}",
                    command=[
                        Run("rhubarbe-pdu", "on", r2lab_pc_hostname(id)),
                        Run("ping", "-c 30", r2lab_pc_hostname(id))
                    ]
                ) for id, node in pc_index.items()
            ]
            green_light += pc_green_light
            
    
    prepare_fit_workers = [
        SshJob(
            scheduler=scheduler,
            required=green_light,
            node=node,
            critical=True,
            verbose=verbose,
            label=f"preparing {r2lab_hostname(id)}",
            command=[
                Run("ip route replace 10.3.1.0/24 dev control via 192.168.3.100"),
                Run("ip route replace 138.96.245.0/24 dev control via 192.168.3.100"),
            ]
        ) for id, node in node_index.items()
    ]

    prepare_pc_workers = [
        SshJob(
            scheduler=scheduler,
            required=green_light,
            node=node,
            critical=True,
            verbose=verbose,
            label=f"preparing {r2lab_pc_hostname(id)}",
            command=[
                Run("ip route replace 10.3.1.0/24 dev eno1 via 192.168.3.100"),
                Run("ip route replace 138.96.245.0/24 dev eno1 via 192.168.3.100"),
            ]
        ) for id, node in pc_index.items()
    ]
    
    prepare = prepare_fit_workers + prepare_pc_workers

    all_workers = ""
    for i in fit_worker_ids:
        all_workers += r2lab_hostname(i) + " "
    for i in pc_worker_ids:
         all_workers += r2lab_pc_hostname(i) + " "

    
    join = SshJob(
        scheduler=scheduler,
        required=prepare,
        node=bpnode,
        critical=False,
        verbose=verbose,
        label=f"configuring and running the ansible blueprint on {r2lab_hostname(bp)}",
        command=[
            RunScript("config-playbook.sh", all_workers),
            # Following playbook to create a new k8s cluster wit master only
            #Run("docker run -t -v /root/SLICES/sopnode/ansible:/blueprint -v /root/.ssh/ssh_r2lab_key:/id_rsa_blueprint blueprint /root/.local/bin/ansible-playbook  -i inventories/sopnode_r2lab/cluster k8s-master.yaml --extra-vars @params.sopnode_r2lab.yaml"),
            # Following playbook to upload and rebuild all required libraries and add workers to the k8s cluster
            #Run("docker run -t -v /root/SLICES/sopnode/ansible:/blueprint -v /root/.ssh/ssh_r2lab_key:/id_rsa_blueprint blueprint /root/.local/bin/ansible-playbook  -i inventories/sopnode_r2lab/cluster k8s-node-orig.yaml --extra-vars @params.sopnode_r2lab.yaml"),
            # Following playbook optimized to speed up adding workers to the k8s cluster
            Run("docker run -t -v /root/SLICES/sopnode/ansible:/blueprint -v /root/.ssh/ssh_r2lab_key:/id_rsa_blueprint blueprint /root/.local/bin/ansible-playbook  -i inventories/sopnode_r2lab/cluster k8s-node.yaml --extra-vars @params.sopnode_r2lab.yaml"),
        ]
    )

    scheduler.check_cycles()
    name = "join-cluster"
    print(10*'*', 'See main scheduler in',
          scheduler.export_as_graphic(name, suffix='svg'))

    # orchestration scheduler jobs
    if verbose:
        scheduler.list()

    if dry_run:
        return True

    if not scheduler.orchestrate():
        print(f"RUN KO : {scheduler.why()}")
        scheduler.debrief()
        return False
    print(f"RUN OK")
    print(80*'*')


def main():
    """
    CLI frontend
    """
    parser = ArgumentParser(formatter_class=ArgumentDefaultsHelpFormatter)
    parser.add_argument("-s", "--slicename", default=default_slicename,
                        help="specify an alternate slicename")
    parser.add_argument("-B", "--node-ansible", dest='bp',
                        default=default_pb_node,
                        help="specify ansible id node")
 
    parser.add_argument("-N", "--node-id", dest='nodes', default=[default_fit_worker_node],
                        choices=[str(x) for x in range(38)],
                        action=ListOfChoices,
                        help="specify as many node ids as you want,"
                             "2 by default, use 0 not to use fit nodes")
    parser.add_argument("-P", "--pc-id", dest='pcs', default=[default_pc_worker_node],
                        choices=[str(x) for x in range(3)],
                        action=ListOfChoices,
                        help="specify as many pc ids as you want,"
                             "{default_pc_worker_node} by default, no pc nodes used")
    parser.add_argument("-M", "--master", default=default_master,
                        help="name of the k8s master node")
    parser.add_argument("-v", "--verbose", default=False,
                        action='store_true', dest='verbose',
                        help="run script in verbose mode")
    parser.add_argument("-n", "--dry-run", default=False,
                        action='store_true', dest='dry_run',
                        help="only pretend to run, don't do anything")
    parser.add_argument("-l", "--load-images", default=False, action='store_true',
                        help="use this for loading images on used nodes")
    parser.add_argument("--image", default=default_image,
                        help="image to load in k8s worker nodes")
    parser.add_argument("--image-bp", default=default_bp_image,
                        help="image to load in ansible blueprint node")
    


    args = parser.parse_args()
    if '0' in args.nodes and '0' in args.pcs:
        print("join-cluster: choose at least one FIT or PC node to be added to the cluster")
        exit(1)
    
    print("join-cluster: Please ensure that k8s master is running fine and that:")
    if '0' not in args.nodes:
        for i in args.nodes:
            print(f" - worker {r2lab_hostname(i)} not already part of the k8s cluster on {args.master}")
    else:
        args.nodes.clear()
    if '0' not in args.pcs:
        for i in args.pcs:
            print(f" - worker {r2lab_pc_hostname(i)} not already part of the k8s cluster on {args.master}")
    else:
        args.pcs.clear()
    print(f"Ansible playbook will run on node {r2lab_hostname(args.bp)}")

    run(gateway=default_gateway, slicename=args.slicename, master=args.master,
        bp=args.bp, nodes=args.nodes, pcs=args.pcs, load_images=args.load_images,
        image=args.image, image_bp=args.image_bp,
        verbose=args.verbose, dry_run=args.dry_run
    )


if __name__ == '__main__':
    # return something useful to your OS
    exit(0 if main() else 1)
