# kube-proxy-load-balancer-fix
A simple fix to work around broken iptables rules in newer Kubernetes.

Some k8s vesions, most notably the one used by Digital Ocean, would try to optimise internal routing by rerouting requests targeting its external load balancer's address directly to the relevant service, bypassing the LB. It might lead to unpleasant surprises with apps depending on hitting the actual LB, notably JetStack's cert-manager. 

This fix runs a cronjob overriding the relevant NAT rules inside kube-proxy, making requests targeting external LBs skip the aforementioned optimisation. 
