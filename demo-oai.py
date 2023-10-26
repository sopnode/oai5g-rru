#!/usr/bin/env python3 -u

"""
This script prepares one fit R2lab node to join the SophiaNode k8s cluster as a worker node for the oai5g demo.
Then, it clones the oai5g-rru and oai-cn5g-fed git directories on one a fit node and applies
different patches on the various OAI5G charts to make them run on the SophiaNode k8s cluster.
Finally, it deploys the different OAI5G pods through the same fit node.

In this demo, the oai-gnb pod can be a USRP N300/N320 device or a jaguar/panther AW2S device located in R2lab.
A variable number of UEs (currently 0 to 6) could be used using -Q option.
Each UE will run on a fit node attached to a Quectel RM 500Q-GL device in R2lab.

This version requires asynciojobs-0.16.3 or higher; if needed, upgrade with
pip install -U asynciojobs

As opposed to a former version that created 4 different schedulers,
here we create a single one that describes the complete workflow from
the very beginning (all fit nodes off) to the end (all fit nodes off)
and then remove some parts as requested by the script options
"""

from argparse import ArgumentParser, ArgumentDefaultsHelpFormatter

# the default for asyncssh is to be rather verbose
from asyncssh.logging import set_log_level as asyncssh_set_log_level

from asynciojobs import Scheduler

from apssh import YamlLoader, SshJob, Run, Service # Push

# make sure to pip install r2lab
from r2lab import r2lab_hostname, ListOfChoices, ListOfChoicesNullReset, find_local_embedded_script

##########################################################################################
#    Configure here OAI5G_RRU and OAI_CN5G_FED repo and tag
OAI5G_RRU_REPO = 'https://github.com/sopnode/oai5g-rru.git'
#OAI5G_RRU_TAG = 'k8s-ansible'
OAI5G_RRU_TAG = 'master'
#OAI5G_RRU_TAG = 'v1.5.1-1.3-1.0'
OAI_CN5G_FED_REPO = 'https://gitlab.eurecom.fr/oai/cn5g/oai-cn5g-fed.git'
#OAI_CN5G_FED_TAG = 'r2lab-rrus'
OAI_CN5G_FED_TAG = 'v1.5.1-1.3'
##########################################################################################

# Currently, TWO k8s clusters are available on the SophiaNode:
# - A Production k8s cluster with 2 PowerEdge servers :
#K8S_MASTER_PROD = 'sopnode-l1.inria.fr'
K8S_MASTER_PROD = 'sopnode-w1.inria.fr'
K8S_WORKER_PROD = 'sopnode-w1.inria.fr'
# - An Experimental/Devel cluster with 2 servers :
K8S_MASTER_DEVEL = 'sopnode-w2.inria.fr'
K8S_WORKER_DEVEL = 'sopnode-w3.inria.fr'

# By default, the script uses the Production k8s cluster
default_master = K8S_MASTER_PROD

# Default R2lab FIT node images
#default_image = 'kubernetes'
default_image = 'u18-lowlat-kube-uhd'
#default_quectel_image = 'quectel-mbim'
default_quectel_image = 'quectel-mbim-single-dnn'

# This script uses one R2lab FIT node as a k8s worker attached to the cluster
# in order to launch the scenario 
default_k8s_fit = 1

# Default FIT node used to run oai-gnb with USRP B210
default_b210_node = 2

# Default Phones used as UE
default_phones = []

# Default FIT nodes used as UE Quectel
default_quectel_nodes = []

# Default Qhat (Raspberry pi 4 nodes used as UE Quectel) nodes
default_qhat_nodes = []

# Default RRU used for the scenario.
# Currently, following possible options:
# ['b210', 'n300', 'n320', 'jaguar', 'panther', 'rfsim'] 
default_rru = 'n300'

default_gateway  = 'faraday.inria.fr'
default_slicename  = 'inria_sopnode'
default_namespace = 'oai5g'

default_regcred_name = 'r2labuser'
default_regcred_password = 'r2labuser-pwd'
default_regcred_email = 'r2labuser@turletti.com'


def run(*, mode, gateway, slicename, master, namespace, logs,
        pcap, auto_start, gnb_only, load_images, k8s_reset,
        k8s_fit, amf_spgwu, gnb, phones, quectel_nodes, qhat_nodes, rru, 
        regcred_name, regcred_password, regcred_email,
        image, quectel_image, verbose, dry_run, demo_tag, charts_tag):
    """
    run the OAI5G demo on the k8s cluster

    Arguments:
        slicename: the Unix login name (slice name) to enter the gateway
        master: k8s master host
        pcap: pcap trace files will be generated
        logs: logs files will be generated
        auto_start: pods will be launched
        gnb_only: OAI5G cn pods will not be started/stopped
        load_images: FIT images will be deployed
        k8s_reset: with k8s deployment
        k8s_fit: FIT node number attached to the k8s cluster as worker node
        amf_spgwu: node name in which amf and spgwu-tiny will be deployed
        gnb: node name in which oai-gnb will be deployed
        phones: list of indices of phones to use
        quectel_nodes: list of indices of quectel UE nodes to use
        qhat_nodes: list of indices of qhat UE nodes to use
        rru: hardware device attached to gNB
        image: R2lab k8s image name
        demo_tag: this demo script tag
        charts_tag: oai_cn5g_fed charts tag
    """

    wait1_dict = dict()
    wait2_dict = dict()
    if phones:
        sleeps_ran = (55, 75)
        phone_msgs = [f"wait for {sleep}s for eNB to start up before waking up phone{id}"
                      for sleep, id in zip(sleeps_ran, phones)]
        wait1_cmd = [f"echo '{msg}'; sleep {sleep}"
                     for msg, sleep in zip(phone_msgs, sleeps_ran)]
        sleeps_phone = (15, 20)
        phone2_msgs = [f"wait for {sleep}s for phone{id} before starting tests"
                       for sleep, id in zip(sleeps_phone, phones)]
        wait2_cmd = [f"echo '{msg}'; sleep {sleep}"
                     for msg, sleep in zip(phone2_msgs, sleeps_phone)]
        for i, n in enumerate(phones):
            wait1_dict.update({n: wait1_cmd[i]})
            wait2_dict.update({n: wait2_cmd[i]})
    
    quectel_dict = dict((n, r2lab_hostname(n)) for n in quectel_nodes)
    qhat_dict = dict((n, "qhat0"+n) for n in qhat_nodes)

    INCLUDES = [find_local_embedded_script(x) for x in (
      "r2labutils.sh", "nodes.sh", "faraday.sh"
    )]

    jinja_variables = dict(
        gateway=gateway,
        master=master,
        namespace=namespace,
        logs=logs,
        pcap=pcap,
        auto_start=auto_start,
        nodes=dict(
            k8s_fit=r2lab_hostname(k8s_fit),
            amf_spgwu=amf_spgwu,
            gnb=gnb,
        ),
        phones=phones,
        wait1_dict=wait1_dict,
        wait2_dict=wait2_dict,
        quectel_dict=quectel_dict,
        qhat_dict=qhat_dict,
        gnb_only=gnb_only,
        rru=rru,
        regcred=dict(
            name=regcred_name,
            password=regcred_password,
            email=regcred_email,
        ),
        image=image,
        quectel_image=quectel_image,
        oai5g_rru_repo=OAI5G_RRU_REPO,
        oai5g_rru_tag=demo_tag,
        oai_cn5g_fed_repo=OAI_CN5G_FED_REPO,
        oai_cn5g_fed_tag=charts_tag,
        verbose=verbose,
        nodes_sh=find_local_embedded_script("nodes.sh"),
        faraday_sh=find_local_embedded_script("faraday.sh"),
        INCLUDES=INCLUDES,
    )

    # (*) first compute the complete logic (but without check_lease)
    # (*) then simplify/prune according to the mode
    # (*) only then add check_lease in all modes

    loader = YamlLoader("demo-oai.yaml.j2")
    nodes_map, jobs_map, scheduler = loader.load_with_maps(jinja_variables, save_intermediate = verbose)
    scheduler.verbose = verbose
    # debug: to visually inspect the full scenario
    if verbose:
        complete_output = "demo-oai-complete"
        print(f"Verbose: storing full scenario (before mode processing) in {complete_output}.svg")
        scheduler.export_as_svgfile(complete_output)
        print(f"Verbose: storing full scenario (before mode processing) in {complete_output}.png")
        scheduler.export_as_pngfile(complete_output)


    # retrieve jobs for the surgery part
    j_load_images = jobs_map['load-images']
    j_start_demo = jobs_map['start-demo']
    j_stop_demo = jobs_map['stop-demo']
    j_cleanups = [jobs_map[k] for k in jobs_map if k.startswith('cleanup')]

    j_leave_joins = [jobs_map[k] for k in jobs_map if k.startswith('leave-join')]
    if quectel_nodes:
        j_prepare_quectels = jobs_map['prepare-quectels']
    j_init_quectels = [jobs_map[k] for k in jobs_map if k.startswith('init-quectel-')]
    j_attach_quectels = [jobs_map[k] for k in jobs_map if k.startswith('attach-quectel-')]
    j_detach_quectels = [jobs_map[k] for k in jobs_map if k.startswith('detach-quectel-')]
    #j_stop_quectels = [jobs_map[k] for k in jobs_map if k.startswith('stop-quectel-')]

    if qhat_nodes:
        j_prepare_qhats = jobs_map['prepare-qhats']
    j_init_qhats = [jobs_map[k] for k in jobs_map if k.startswith('init-qhat-')]
    j_attach_qhats = [jobs_map[k] for k in jobs_map if k.startswith('attach-qhat-')]
    j_detach_qhats = [jobs_map[k] for k in jobs_map if k.startswith('detach-qhat-')]
    #j_stop_qhats = [jobs_map[k] for k in jobs_map if k.startswith('stop-qhat-')]

    j_attach_phones = [jobs_map[k] for k in jobs_map if k.startswith('attach-phone')]
    j_test_cx_phones = [jobs_map[k] for k in jobs_map if k.startswith('test-cx-phone')]
    j_detach_phones = [jobs_map[k] for k in jobs_map if k.startswith('detach-phone')]
    
    # run subparts as requested
    purpose = f"{mode} mode"
    ko_message = f"{purpose} KO"

    if mode == "cleanup":
        scheduler.keep_only(j_cleanups)
        ko_message = f"Could not cleanup demo"
        ok_message = f"Thank you, the k8s {master} cluster is now clean and FIT nodes have been switched off"
    elif mode == "stop":
        #scheduler.keep_only_between(starts=[j_stop_demo], ends=j_cleanups, keep_ends=False)
        scheduler.keep_only([j_stop_demo]+j_detach_quectels+j_detach_qhats+j_detach_phones)
        ko_message = f"Could not delete OAI5G pods"
        ok_message = f"""No more OAI5G pods on the {master} cluster
Nota: If you are done with the demo, do not forget to clean up the k8s {master} cluster by running:
\t ./demo-oai.py [--master {master}] --cleanup
"""
    elif mode == "start":
        scheduler.keep_only([j_start_demo] + j_attach_quectels + j_attach_qhats + j_attach_phones + j_test_cx_phones)
        ok_message = f"OAI5G demo started, you can check kubectl logs on the {master} cluster"
        ko_message = f"Could not launch OAI5G pods"
    else:
        if auto_start:
            scheduler.keep_only_between(ends=[j_start_demo] + j_attach_quectels + j_attach_qhats + j_attach_phones + j_test_cx_phones, keep_ends=True)
        else:
            scheduler.keep_only_between(ends=[j_start_demo] + j_init_quectels + j_init_qhats, keep_ends=True)
        if not load_images:
            scheduler.bypass_and_remove(j_load_images)
#TT see how to add scheduler.bypass_and_remove(j_init_quectels)
            purpose += f" (no image loaded)"
            if quectel_nodes and j_prepare_quectels in scheduler.jobs:
                scheduler.bypass_and_remove(j_prepare_quectels)
            purpose += f" (no quectel node prepared)"
            if qhat_nodes and j_prepare_qhats in scheduler.jobs:
                scheduler.bypass_and_remove(j_prepare_qhats)
            purpose += f" (no qhat node prepared)"
        else:
            purpose += f" WITH rhubarbe imaging the FIT nodes"
            if not quectel_nodes:
                purpose += f" (no quectel node prepared)"
            else:
                purpose += f" (quectel node(s) prepared: {quectel_nodes})"
            if not qhat_nodes:
                purpose += f" (no qhat node prepared)"
            else:
                purpose += f" (qhat node(s) prepared: {qhat_nodes})"
            if not phones:
                purpose += f" (no phone prepared)"
            else:
                purpose += f" (phone(s) prepared: {phones})"

        if not auto_start:
            scheduler.bypass_and_remove(j_start_demo)
            purpose += f" (NO auto start)"
            ok_message = f"RUN SetUp OK. You can now start the demo by running ./demo-oai.py --master {master} --start"
        else:
            ok_message = f"RUN SetUp and demo started OK. You can now check the kubectl logs on the k8s {master} cluster."
        if not k8s_reset:
            for job in j_leave_joins:
                scheduler.bypass_and_remove(job)
            purpose += " (k8s reset SKIPPED)"
        else:
            purpose += " (k8s RESET)"


    # add this job as a requirement for all scenarios
    check_lease = SshJob(
        scheduler=scheduler,
        node = nodes_map['faraday'],
        critical = True,
        verbose=verbose,
        command = Run("rhubarbe leases --check"),
    )
    # this becomes a requirement for all entry jobs
    for entry in scheduler.entry_jobs():
        entry.requires(check_lease)


    scheduler.check_cycles()
    print(10*'*', purpose, "\n", 'See main scheduler in', scheduler.export_as_svgfile("demo-oai-graph"))

    if verbose:
        scheduler.list()

    if dry_run:
        return True

    if not scheduler.orchestrate():
        print(f"{ko_message}: {scheduler.why()}")
        scheduler.debrief()
        return False
    print(ok_message)

    print(80*'*')
    return True

HELP = """
all the forms of the script assume there is a kubernetes cluster
up and running on the chosen master node,
and that the provided slicename holds the current lease on FIT/R2lab

In its simplest form (no option given), the script will
  * load images on board of the FIT nodes
  * get the nodes to join that cluster
  * and then deploy the k8s pods on that substrate (unless the --no-auto-start is not provided)

Thanks to the --stop and --start option, one can relaunch
the scenario without the need to re-image the selected FIT nodes;
a typical sequence of runs would then be

  * with no option
  * then with the --stop option to destroy the deployment
  * and then with the --start option to re-create the deployment a second time

Or,

  * with the --no-auto-start option to simply load images
  * then with the --start option to create the network
  * and then again any number of --stop / --start calls

At the end of your tests, please run the script with the --cleanup option to clean the k8s cluster and
switch off FIT nodes.
"""


def main():
    """
    CLI frontend
    """
    
    parser = ArgumentParser(usage=HELP, formatter_class=ArgumentDefaultsHelpFormatter)

    parser.add_argument(
        "--start", default=False,
        action='store_true', dest='start',
        help="start the oai-demo, i.e., launch OAI5G pods")

    parser.add_argument(
        "--stop", default=False,
        action='store_true', dest='stop',
        help="stop the oai-demo, i.e., delete OAI5G pods")

    parser.add_argument(
        "--cleanup", default=False,
        action='store_true', dest='cleanup',
        help="Remove smoothly FIT nodes from the k8s cluster and switch them off")

    parser.add_argument(
        "-a", "--no-auto-start", default=True,
        action='store_false', dest='auto_start',
        help="default is to start the oai-demo after setup")

    parser.add_argument(
        "--gnb-only", default=False,
        action='store_true', dest='gnb_only',
        help="default is to manage not only gnb but also CN pods")

    parser.add_argument(
        "-k", "--no-k8s-reset", default=True,
	action='store_false', dest='k8s_reset',
	help="default is to reset k8s before setup")

    parser.add_argument(
        "-l", "--load-images", default=False, action='store_true',
        help="load the kubernetes image on the nodes before anything else")

    parser.add_argument(
        "-i", "--image", default=default_image,
        help="kubernetes image to load on nodes")

    parser.add_argument("--quectel-image", dest="quectel_image",
                        default=default_quectel_image)

    parser.add_argument(
        "--master", default=default_master,
        help="kubernetes master node")

    parser.add_argument(
        "--devel", action='store_true', default=False,
        help=f"equivalent to --master {K8S_MASTER_DEVEL}")


    parser.add_argument("--k8s_fit", default=default_k8s_fit,
                        help="id of the FIT node that attachs to the k8s cluster")

    parser.add_argument("--amf_spgwu", default=default_master,
                        help="node name that runs oai-amf and oai-spgwu")

    parser.add_argument("--gnb", default=default_master,
                        help="node name that runs oai-gnb")

    parser.add_argument(
        "--namespace", default=default_namespace,
        help=f"k8s namespace in which OAI5G pods will run")

    parser.add_argument(
        "-s", "--slicename", default=default_slicename,
        help="slicename used to book FIT nodes")

    parser.add_argument(
        "--regcred_name", default=default_regcred_name,
        help=f"registry credential name for docker pull")

    parser.add_argument(
        "--regcred_password", default=default_regcred_password,
        help=f"registry credential password for docker pull")

    parser.add_argument(
        "--regcred_email", default=default_regcred_email,
        help=f"registry credential email for docker pull")

    parser.add_argument("-P", "--phones", dest='phones',
                        action=ListOfChoicesNullReset, type=int, choices=(1, 2, 0),
                        default=default_phones,
                        help='Commercial phones to use; use -p 0 to choose no phone')

    parser.add_argument(
        "-Q", "--quectel-id", dest='quectel_nodes',
        default=default_quectel_nodes,
        choices=["7", "9", "18", "31", "32", "34"],
	action=ListOfChoices,
	help="specify as many node ids with Quectel UEs as you want.")

    parser.add_argument(
        "-q", "--qhat-id", dest='qhat_nodes',
        default=default_qhat_nodes,
        choices=["1", "2", "3"],
	action=ListOfChoices,
	help="specify as many node ids with Quectel UEs as you want.")

    parser.add_argument(
        "-R", "--rru", dest='rru',
        default=default_rru,
        choices=("b210", "n300", "n320", "jaguar", "panther", "rfsim"),
	help="specify the hardware RRU to use for gNB or rfsim if simulation")

    parser.add_argument("-p", "--pcap", default=False,
                        action='store_true', dest='pcap',
                        help="run tcpdump on OAI5G pods to store pcap/logs files")

    parser.add_argument("-L", "--logs", default=False,
                        action='store_true', dest='logs',
                        help="run tcpdump on OAI5G pods to only store logs files")

    parser.add_argument("-v", "--verbose", default=False,
                        action='store_true', dest='verbose',
                        help="run script in verbose mode")

    parser.add_argument("-n", "--dry-runmode", default=False,
                        action='store_true', dest='dry_run',
                        help="only pretend to run, don't do anything")

    parser.add_argument(
        "--demo_tag", default=OAI5G_RRU_TAG,
        help=f"this demo script tag, default is {OAI5G_RRU_TAG}")

    parser.add_argument(
        "--charts_tag", default=OAI_CN5G_FED_TAG,
        help=f"oai-cn5g-fed charts tag, default is {OAI_CN5G_FED_TAG}")


    args = parser.parse_args()
    print(f"Running the demo version {args.demo_tag} with oai-cn5g-fed {args.charts_tag} tag")
    if args.devel:
        args.master = K8S_MASTER_DEVEL
        # in case of Devel Cluster, modify the default servers to run amf/spgwu/gnb pods
        if args.amf_spgwu == K8S_WORKER_PROD:
            args.amf_spgwu = K8S_WORKER_DEVEL
        if args.gnb == K8S_MASTER_PROD:
            args.gnb = K8S_MASTER_DEVEL

    if args.rru == "b210":
        if args.gnb == default_master:
            args.gnb = r2lab_hostname(default_b210_node)
            
    if args.quectel_nodes:
        for quectel in args.quectel_nodes:
            print(f"Using Quectel UE on node {r2lab_hostname(quectel)}")
    else:
        print("No Quectel UE involved")

    if args.phones:
        for i in args.phones:
            print(f"Using UE phone {i} ")
    else:
        print("No UE phone involved")
        args.phones.clear()

    if args.qhat_nodes:
        for i in args.qhat_nodes:
            print(f"Using qhat0{i} UE")
    else:
        print("No qhat UE involved")

    if args.start:
        print(f"**** Launch all pods of the oai5g demo on the k8s {args.master} cluster")
        mode = "start"
    elif args.stop:
        print(f"delete all pods in the {args.namespace} namespace")
        mode = "stop"
    elif args.cleanup:
        print(f"**** Drain and remove FIT nodes from the {args.master} cluster, then swith off FIT nodes")
        mode = "cleanup"
    else:
        print(f"**** Prepare oai5g demo setup on the k8s {args.master} cluster with {args.slicename} slicename")
        print(f"OAI5G pods will run on the {args.namespace} k8s namespace")
        print(f"the following nodes will be used:")
        print(f"\t{r2lab_hostname(args.k8s_fit)} as k8s worker node")
        print(f"\t{args.amf_spgwu} for oai-amf and oai-spgwu-tiny")
        if args.rru == "rfsim":
            print(f"\toai-gnb running in simulation mode")
        else:
            print(f"\t{args.gnb} for oai-gnb with {args.rru} as RRU hardware device")
        print(f"FIT image loading:",
              f"YES with {args.image}" if args.load_images
              else "NO (use --load-images if needed)")
        if args.auto_start:
            print("Automatically start the demo after setup")
        else:
            print("Do not start the demo after setup")
        if args.gnb_only:
            print("Only start/stop oai-gnb pod")
        mode = "run"
    if args.pcap:
        print(f"generate both pcap and logs files")
        pcap_str='True'
    else:
        pcap_str='False'
        if args.logs:
            print("generate only logs files")
            logs_str='True'
        else:
            print("do not generate pcap/logs files")
            logs_str='False'
    run(mode=mode, gateway=default_gateway, slicename=args.slicename,
        master=args.master, namespace=args.namespace, logs=logs_str,
        pcap=pcap_str, auto_start=args.auto_start, gnb_only=args.gnb_only,
        load_images=args.load_images,
        k8s_fit=args.k8s_fit, amf_spgwu=args.amf_spgwu, gnb=args.gnb,
        phones=args.phones, quectel_nodes=args.quectel_nodes,
        qhat_nodes=args.qhat_nodes, rru=args.rru,
        regcred_name=args.regcred_name,
        regcred_password=args.regcred_password,
        regcred_email=args.regcred_email,
        dry_run=args.dry_run, verbose=args.verbose, image=args.image,
        quectel_image=args.quectel_image, k8s_reset=args.k8s_reset,
        demo_tag=args.demo_tag, charts_tag=args.charts_tag)


if __name__ == '__main__':
    # return something useful to your OS
    exit(0 if main() else 1)
