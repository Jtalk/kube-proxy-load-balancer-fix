#!/bin/sh

# set -o pipefail
set -u

add_rule () {

	pod="$1"
	expected_rule="$2"
	rule_to_add="$3"

	kubectl -n kube-system exec "$pod" -- iptables-save | grep > /dev/null -- "${expected_rule}"
	if [ ! $? -eq 0 ]; then
		echo Could not find the rule for "$pod", fixing with "$rule_to_add"
		kubectl -n kube-system exec $pod -- iptables $rule_to_add && echo Success
	else
		echo Found the rule for "$pod", skipping
	fi	
}

if [ -z "$@" ]; then
	echo "Usage: \`./fix.sh IP1 IP2 ...\` for each load balancer IP"
	exit 1;
fi

kubectl version > /dev/null && echo Kubectl check ok
if [ ! $? -eq 0 ]; then 
	echo Kubectl misconfiguration detected, exiting
	exit 1
fi

RESULT=0
PROXY_PODS=$(kubectl -n kube-system get pods | grep "^kube-proxy" | awk '{ print $1 }');

for ip in $@; do

	LB_IP="$ip" # 159.65.210.9
	RULE="-t nat -I PREROUTING -d ${LB_IP} -j RETURN"

	EXPECTED_LB_IP=$(echo "$LB_IP" | awk  '/^.+\.[0-9]+/ { $0=$0"/32" } 1')
	EXPECTED_RULE="-A PREROUTING -d ${EXPECTED_LB_IP} -j RETURN"

	for pod in $PROXY_PODS; do
		add_rule "$pod" "$EXPECTED_RULE" "$RULE"
		THIS_RESULT=$?
		RESULT=$((RESULT + THIS_RESULT))
	done
done

exit $RESULT