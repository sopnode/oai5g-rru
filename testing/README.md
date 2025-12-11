## Prerequisites:

Open5gs core is up and running:

``` bash
$ kubectl get pods -n open5gs
NAME                             READY   STATUS    RESTARTS   AGE
mongodb-0                        1/1     Running   0          46m
open5gs-amf-777756df7f-2lrkl     1/1     Running   0          46m
open5gs-ausf-595c98fc96-5dgmm    1/1     Running   0          46m
open5gs-bsf-585446f69b-wjlph     1/1     Running   0          46m
open5gs-nrf-7d55d67687-gmltc     1/1     Running   0          46m
open5gs-nssf-7dd8c874c5-8z6wn    1/1     Running   0          46m
open5gs-pcf-7dc68755b9-kk7s8     1/1     Running   0          46m
open5gs-scp-76ff9cf4df-xd6nl     1/1     Running   0          46m
open5gs-smf1-7c88965ff6-kk5rv    1/1     Running   0          46m
open5gs-smf2-6858845f8b-4b448    1/1     Running   0          46m
open5gs-udm-97b89c496-glzn6      1/1     Running   0          46m
open5gs-udr-d7b6ff4d6-qhltt      1/1     Running   0          46m
open5gs-upf1-6c59d5b747-cgtft    1/1     Running   0          46m
open5gs-upf2-5c878f6688-g2bbw    1/1     Running   0          46m
open5gs-webui-669b694b5c-dgd2k   1/1     Running   0          45m
```

(See https://github.com/niloysh/testbed-automator and https://github.com/turletti/open5gs-k8s/tree/main)


## Instructions:

Create a new empty directory and copy the 'prepare-demo-oai.sh' file.

Run: `./prepare-demo-oai.sh -a`. This will pull the necessary files with the mofified values.

Run: `./demo-oai.sh start-gnb`. This should create the 'oaiw1-ci' namespace and lauch the 'oai-gnb' pod:

``` bash
$ kubectl -n oaiw1-ci get pods
NAME                     READY   STATUS    RESTARTS   AGE
oai-gnb-6f56bc76-k7pmw   2/2     Running   0          43s
```

Check the 'open5gs-amf' pod to see if the gnb is connected:

``` bash
$ kubectl -n open5gs logs open5gs-amf-777756df7f-2lrkl

...
04/15 09:20:24.956: [amf] INFO: gNB-N2 accepted[10.10.3.205]:54845 in ng-path module (../src/amf/ngap-sctp.c:113)
04/15 09:20:24.956: [amf] INFO: gNB-N2 accepted[10.10.3.205] in master_sm module (../src/amf/amf-sm.c:741)
04/15 09:20:24.963: [amf] INFO: [Added] Number of gNBs is now 1 (../src/amf/context.c:1231)
04/15 09:20:24.963: [amf] INFO: gNB-N2[10.10.3.205] max_num_of_ostreams : 2 (../src/amf/amf-sm.c:780)
```

Modify the imsi in the '/open5gs-k8s/mongo-tools/generate-data.py' file to correspond to that of oai-nr-ue:

``` bash
...
simulated_subscriber_data = {
    "subscriber_1": {
        "_id": "",
        "imsi": "001010000001121",
        "subscribed_rau_tau_timer": 12,
        "network_access_mode": 0,
        "subscriber_status": 0,
        "access_restriction_data": 32,
        "slice": [slice_data["slice_1"]],
        "ambr": {
            "uplink": {"value": 1, "unit": Open5GS.Unit.Gbps},
            "downlink": {"value": 1, "unit": Open5GS.Unit.Gbps},
        },
        "security": {
            "k": "fec86ba6eb707ed08905757b1bb44b8f",
            "amf": "8000",
            "op": None,
            "opc": "C42449363BBAD02B66D16BC975D77CC1",
        },
        "schema_version": 1,
        "__v": 0,
    },
...
```

Run these commands to add the UE data to the mongo database:

``` bash
~/open5gs-k8s$ python mongo-tools/generate-data.py
2025-04-15 11:29:41 |     INFO | Loading existing data...
2025-04-15 11:29:41 |  WARNING | No existing slice data found at data/slices.yaml
2025-04-15 11:29:41 |  WARNING | No existing subscriber data found at data/subscribers.yaml
2025-04-15 11:29:41 |     INFO | Creating 2 slices ...
2025-04-15 11:29:41 |     INFO | Generating 0 new slices...
2025-04-15 11:29:41 |     INFO | Saving slices to data/slices.yaml
2025-04-15 11:29:41 |     INFO | Adding 3 sample subscribers ...
2025-04-15 11:29:41 |     INFO | Saving subscribers to data/subscribers.yaml
2025-04-15 11:29:41 |     INFO | Slice and subscriber creation complete.

~/open5gs-k8s$ python mongo-tools/add-subscribers.py 
2025-04-15 11:30:02 |     INFO | Added subscriber_1
2025-04-15 11:30:02 |     INFO | Added subscriber_2
2025-04-15 11:30:02 |     INFO | Added subscriber_3
```

Now on the new directory where 'demo-oai.sh' is located, run `./demo-oai.sh start-nr-ue` to deploy the 'oai-nr-ue' pod:

``` bash
~/oai-gnb$ ./demo-oai.sh start-nr-ue
./demo-oai.sh: running start-nr-ue
Running start-nr-ue() on namespace: oaiw1-ci, NODE_GNB=precision-7530
cd /home/ziyad-mabrouk/oai-gnb/oai-cn5g-fed/charts/oai-5g-ran
helm -n oaiw1-ci install oai-nr-ue oai-nr-ue/
NAME: oai-nr-ue
LAST DEPLOYED: Tue Apr 15 11:30:51 2025
NAMESPACE: oaiw1-ci
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
1. Get the application name by running these commands:
  export NR_UE_POD_NAME=$(kubectl get pods --namespace oaiw1-ci -l "app.kubernetes.io/name=oai-nr-ue,app.kubernetes.io/instance=oai-nr-ue" -o jsonpath="{.items[0].metadata.name}")
2. Dockerhub images of OpenAirInterface requires avx2 capabilities in the cpu and they are built for x86 architecture, tested on UBUNTU OS only.
3. Note: This helm chart of OAI-NR-UE is only tested in RF-simulator mode not tested with hardware on Openshift/Kubernetes Cluster
4. In case you want to test these charts with USRP then make sure your CPU sleep states are off
Wait until oai-nr-ue pod is READY
pod/oai-gnb-6f56bc76-k7pmw condition met
pod/oai-nr-ue-555587f964-h7vdv condition met
```

Check that the newly added UE is connected by verifying the logs of the 'open5gs-smf1' pod (since it's attached to slice 1):

``` bash
$ kubectl -n open5gs logs open5gs-smf1-7c88965ff6-kk5rv

 ...
04/15 09:31:15.418: [smf] INFO: [Added] Number of SMF-UEs is now 1 (../src/smf/context.c:1019)
04/15 09:31:15.419: [smf] INFO: [Added] Number of SMF-Sessions is now 1 (../src/smf/context.c:3068)
04/15 09:31:15.427: [smf] INFO: UE SUPI[imsi-001010000001121] DNN[internet] IPv4[10.41.0.2] IPv6[] (../src/smf/npcf-handler.c:539)
04/15 09:31:15.428: [gtp] INFO: gtp_connect() [10.10.3.1]:2152 (../lib/gtp/path.c:60)
```