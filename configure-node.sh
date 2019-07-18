#!/usr/bin/env bash

#set -x

rancher_ip=${1:-10.10.10.10}
admin_password=${2:-password}

agent_ip=`ip addr show eth1 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1`

curl_image="appropriate/curl"
jq_image="stedolan/jq"

echo ***************************
echo pulling images

docker pull ${curl_image}    &>/dev/null
docker pull ${jq_image}      &>/dev/null

echo login to rancher

while true; do

    LOGINTOKEN=$(docker run --rm --net=host ${curl_image} -s "https://mgmt01.local/v3-public/localProviders/local?action=login" -H 'content-type: application/json' --data-binary '{"username":"admin","password":"'${admin_password}'"}' --insecure | docker run --rm -i ${jq_image} -r .token)

    if [ "$LOGINTOKEN" != "null" ]; then
        break
    else
        sleep 5
    fi
done

echo creating CLUSTERID

while true; do
  CLUSTERID=$(docker run --rm --net=host ${curl_image} -sLk -H "Authorization: Bearer $LOGINTOKEN" "https://mgmt01.local/v3/clusters?name=quickstart" | docker run --rm -i ${jq_image} -r '.data[].id')

  if [ -n "$CLUSTERID" ]; then
    break
  else
    sleep 5
  fi
done

echo created CLUSTERID

case `hostname` in
		ctrl*)
			  role_flags="--etcd --controlplane"
			  ;;
		data*)
			  role_flags="--worker"
			  ;;
		*)
			  commands
			  ;;
esac

echo get agent command

while true; do
  agent_cmd=$(docker run --rm --net=host ${curl_image} -sLk -H "Authorization: Bearer $LOGINTOKEN" "https://mgmt01.local/v3/clusterregistrationtoken?clusterId=$CLUSTERID" | docker run --rm -i ${jq_image} -r '.data[].nodeCommand' | head -1)

  if [ -n "${agent_cmd}" ]; then
    break
  else
    sleep 5
  fi
done

echo got agent command

complete_cmd="${agent_cmd} ${role_flags} --internal-address ${agent_ip} --address ${agent_ip}"

echo execute agent command

echo ${complete_cmd}

${complete_cmd} &>/dev/null

echo executed agent command
echo ***************************
