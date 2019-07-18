#!/usr/bin/env bash

#set -x

rancher_ip=`ip addr show eth1 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1`

admin_password=${1:-password}

rancher_version=${2:-latest}
k8s_version=           # $3

rancher_image="rancher/rancher:${rancher_version}"
curl_image="appropriate/curl"
jq_image="stedolan/jq"

echo ***************************
echo pulling images

docker pull ${rancher_image} &>/dev/null
docker pull ${curl_image}    &>/dev/null
docker pull ${jq_image}      &>/dev/null

echo starting rancher

docker run -d --restart=unless-stopped -p 80:80 -p 443:443 -v /opt/rancher:/var/lib/rancher ${rancher_image} &>/dev/null

echo waiting for rancher

while true; do
  docker run --rm --net=host ${curl_image} -sLk https://127.0.0.1/ping && break
  sleep 5
done

echo login to rancher

while true; do

    LOGINTOKEN=$(docker run --rm --net=host ${curl_image} -s "https://127.0.0.1/v3-public/localProviders/local?action=login" -H 'content-type: application/json' --data-binary '{"username":"admin","password":"admin"}' --insecure | docker run --rm -i ${jq_image} -r .token)

    if [ "$LOGINTOKEN" != "null" ]; then
        break
    else
        sleep 5
    fi

done

echo logged in as admin/admin

docker run --rm --net=host ${curl_image} -s 'https://127.0.0.1/v3/users?action=changepassword' -H 'content-type: application/json' -H "Authorization: Bearer $LOGINTOKEN" --data-binary '{"currentPassword":"admin","newPassword":"'$admin_password'"}' --insecure

echo changed to $admin_password

APITOKEN=$(docker run --rm --net=host ${curl_image} -s 'https://127.0.0.1/v3/token' -H 'content-type: application/json' -H "Authorization: Bearer $LOGINTOKEN" --data-binary '{"type":"token","description":"automation"}' --insecure | docker run --rm -i ${jq_image} -r .token)

echo APITOKEN created

RANCHER_SERVER="https://mgmt01.local"
docker run --rm --net=host ${curl_image} -s 'https://127.0.0.1/v3/settings/server-url' -H 'content-type: application/json' -H "Authorization: Bearer $APITOKEN" -X PUT --data-binary '{"name":"server-url","value":"'$RANCHER_SERVER'"}' --insecure &>/dev/null

echo Server URL configured

CLUSTERID=$(docker run --rm --net=host ${curl_image} -s 'https://127.0.0.1/v3/cluster' -H 'content-type: application/json' -H "Authorization: Bearer $APITOKEN" --data-binary '{"dockerRootDir":"/var/lib/docker","enableNetworkPolicy":false,"type":"cluster","rancherKubernetesEngineConfig":{"kubernetesVersion":"'$k8s_version'","addonJobTimeout":30,"ignoreDockerVersion":true,"sshAgentAuth":false,"type":"rancherKubernetesEngineConfig","authentication":{"type":"authnConfig","strategy":"x509"},"network":{"options":{"flannelBackendType":"vxlan"},"plugin":"canal","canalNetworkProvider":{"iface":"eth1"}},"ingress":{"type":"ingressConfig","provider":"nginx"},"monitoring":{"type":"monitoringConfig","provider":"metrics-server"},"services":{"type":"rkeConfigServices","kubeApi":{"podSecurityPolicy":false,"type":"kubeAPIService"},"etcd":{"creation":"12h","extraArgs":{"heartbeat-interval":500,"election-timeout":5000},"retention":"72h","snapshot":false,"type":"etcdService","backupConfig":{"enabled":true,"intervalHours":12,"retention":6,"type":"backupConfig"}}}},"localClusterAuthEndpoint":{"enabled":true,"type":"localClusterAuthEndpoint"},"name":"quickstart"}' --insecure | docker run --rm -i ${jq_image} -r .id)

echo CLUSTERID created

REGISTRATIONTOKEN=$(docker run --rm --net=host ${curl_image} -s 'https://127.0.0.1/v3/clusterregistrationtoken' -H 'content-type: application/json' -H "Authorization: Bearer $APITOKEN" --data-binary '{"type":"clusterRegistrationToken","clusterId":"'$CLUSTERID'"}' --insecure)

echo REGISTRATIONTOKEN created
echo ***************************