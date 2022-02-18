include ../../../Makefile

NAME ?= calico
CALICOCTL_VERSION = v3.22.0
CNI_VERSION = v3.21.2
CALICOCTL = calicoctl
CALICOCTL_ARM64 = calicoctl_arm64
CALICO_CNI_ARM = calico-arm
CALICO_CNI_IPAM = calico-ipam
CALICO_VERSION = v3.22.0
CNI = cni

export KUBECONFIG=/home/jmiller/.kube/config
export DATASTORE_TYPE=kubernetes
export CNI_VERSION CALICOCTL_VERSION CALICO_VERSION

$(CALICOCTL_ARM64):
	curl -L https://github.com/projectcalico/calico/releases/download/$(CALICOCTL_VERSION)/calicoctl-linux-arm64 -o calicoctl_arm64
	for node in $(ALL_WORKERS) $(ALL_CONTROLLERS); do \
		echo "---------------------------------------" ; \
		echo " COPYING calicoctl_arm64 to $$node" ; \
		echo "---------------------------------------" ; \
		scp $(CALICOCTL_ARM64) root@$$node:/usr/local/bin/calicoctl ; \
		ssh $$node sudo chmod a+x /usr/local/bin/calicoctl ; \
		ssh $$node sudo mkdir /etc/calico >/dev/null 2>&1 || true ; \
 		scp calicoctl.cfg root@$$node:/etc/calico/calicoctl.cfg ; \
        done

$(CALICO_CNI_ARM):
	curl -L -o calico-arm https://github.com/projectcalico/cni-plugin/releases/download/$(CNI_VERSION)/calico-arm64

$(CALICO_CNI_IPAM):
	curl -L -o calico-ipam https://github.com/projectcalico/cni-plugin/releases/download/$(CNI_VERSION)/calico-ipam-arm64

$(CALICOCTL):
	curl -L https://github.com/projectcalico/calico/releases/download/$(CALICOCTL_VERSION)/calicoctl-linux-amd64 -o calicoctl
	chmod a+x calicoctl

cnikubeconfig:
	ssh root@$(CONTROLLER0) openssl req -newkey rsa:4096 \
           -keyout cni.key \
           -nodes \
           -out cni.csr \
           -subj "/CN=calico-cni"
	ssh root@$(CONTROLLER0) sudo openssl x509 -req -in cni.csr \
           -CA /etc/kubernetes/pki/ca.crt \
           -CAkey /etc/kubernetes/pki/ca.key \
           -CAcreateserial \
           -out cni.crt \
           -days 900
	ssh root@$(CONTROLLER0) kubectl config set-cluster kubernetes \
	   --certificate-authority=/etc/kubernetes/pki/ca.crt \
	   --embed-certs=true \
	   --server=https://cluster-endpoint:6443 \
	   --kubeconfig=cni.kubeconfig
	ssh root@$(CONTROLLER0) kubectl config set-credentials calico-cni \
	   --client-certificate=cni.crt \
	   --client-key=cni.key \
	   --embed-certs=true \
	   --kubeconfig=cni.kubeconfig
	ssh root@$(CONTROLLER0) kubectl config set-context default \
	   --cluster=kubernetes \
	   --user=calico-cni \
	   --kubeconfig=cni.kubeconfig
	ssh root@$(CONTROLLER0) kubectl config use-context default --kubeconfig=cni.kubeconfig
	for node in $(ALL_WORKERS) $(ALL_CONTROLLERS); do \
		echo "---------------------------------------" ; \
		echo " COPYING CNI config to $$node" ; \
		echo "---------------------------------------" ; \
		scp root@$(CONTROLLER0):cni.kubeconfig root@$$node:/etc/cni/net.d/calico-kubeconfig ; \
		ssh $$node sudo chmod 600 /etc/cni/net.d/calico-kubeconfig ; \
		scp 10-calico.conflist root@$$node:/etc/cni/net.d/10-calico.conflist ; \
        done

base:
	kubectl apply --context $(KUBE_CONTEXT) -f 01_crds.yaml
	envsubst < 02_ippool.yaml | ./calicoctl apply --context $(KUBE_CONTEXT) -f -

roles:
	kubectl apply --context $(KUBE_CONTEXT) -f 03_roles.yaml

typha:
	openssl req -x509 -newkey rsa:4096 \
                  -keyout typhaca.key \
                  -nodes \
                  -out typhaca.crt \
                  -subj "/CN=Calico Typha CA" \
                  -days 900
	/usr/bin/cat typhaca.crt | sed "2,\$$s/^/    /g" > /tmp/cert.pem
	TYPHACACRT=$$(cat /tmp/cert.pem) envsubst < 04_configmap.yaml | kubectl apply --context \
		   $(KUBE_CONTEXT) -f -
	openssl req -newkey rsa:4096 \
           -keyout typha.key \
           -nodes \
           -out typha.csr \
           -subj "/CN=calico-typha"
	openssl x509 -req -in typha.csr \
                  -CA typhaca.crt \
                  -CAkey typhaca.key \
                  -CAcreateserial \
                  -out typha.crt \
                  -days 900
	kubectl delete secret -n kube-system calico-typha-certs --context $(KUBE_CONTEXT) || true
	kubectl create secret generic -n kube-system calico-typha-certs --from-file=typha.key \
		--from-file=typha.crt --context $(KUBE_CONTEXT)
	envsubst < 05_typha.yaml | kubectl apply --context $(KUBE_CONTEXT) -f -

node:
	openssl req -newkey rsa:4096 \
           -keyout calico-node.key \
           -nodes \
           -out calico-node.csr \
           -subj "/CN=calico-node"
	openssl x509 -req -in calico-node.csr \
                  -CA typhaca.crt \
                  -CAkey typhaca.key \
                  -CAcreateserial \
                  -out calico-node.crt \
                  -days 900
	kubectl delete secret -n kube-system calico-node-certs --context $(KUBE_CONTEXT) || true
	kubectl create secret generic -n kube-system calico-node-certs --from-file=calico-node.key \
		--from-file=calico-node.crt --context $(KUBE_CONTEXT)
	envsubst < 06_node.yaml | kubectl apply --context $(KUBE_CONTEXT) -f -

bgp:
	for node in $(ALL_CONTROLLERS); do \
		echo "---------------------------------------" ; \
		echo " Labelling $$node as route-reflector" ; \
		echo "---------------------------------------" ; \
		kubectl label nodes $$node --overwrite=true is-route-reflector=true --context $(KUBE_CONTEXT) ; \
		./calicoctl patch node $$node --patch \
		  '{"spec":{"bgp": {"routeReflectorClusterID": "224.0.0.1"}}}' --type json ; \
        done
	envsubst < 07_bgp.yaml | ./calicoctl apply --context $(KUBE_CONTEXT) -f -

$(CNI): $(CALICOCTL_ARM64) $(CALICO_CNI_ARM) $(CALICO_CNI_IPAM)
	for node in $(ALL_WORKERS) $(ALL_CONTROLLERS); do \
		echo "---------------------------------------" ; \
		echo " INSTALLING CNI plugin on $$node" ; \
		echo "---------------------------------------" ; \
		ssh $$node sudo mkdir -p /etc/cni/bin ; \
		scp $(CALICO_CNI_ARM) root@$$node:/opt/cni/bin/calico ; \
		scp $(CALICO_CNI_IPAM) root@$$node:/opt/cni/bin/calico-ipam ; \
		ssh $$node sudo chmod 755 /opt/cni/bin/calico ; \
		ssh $$node sudo chmod 755 /opt/cni/bin/calico-ipam ; \
		ssh $$node sudo mkdir -p /etc/cni/net.d/ ; \
        done
	touch $(CNI) ../../../installed/calico

install: $(CALICOCTL) base cnikubeconfig roles $(CNI) typha node bgp
	@echo "$(NAME) Installed"

destroy: uninstall

uninstall:
	@echo "Uninstalling $(NAME)";
	ssh root@$(CONTROLLER0) rm -f cni.crt cni.csr cni.key cni.kubeconfig
	kubectl delete secret -n kube-system calico-typha-certs --context $(KUBE_CONTEXT) || true
	kubectl delete secret -n kube-system calico-node-certs --context $(KUBE_CONTEXT) || true
	envsubst < 02_ippool.yaml | ./calicoctl delete --context $(KUBE_CONTEXT) -f - || true
	envsubst < 07_bgp.yaml | ./calicoctl delete --context $(KUBE_CONTEXT) -f - || true
	for f in 01_crds.yaml 03_roles.yaml 04_configmap.yaml 05_typha.yaml 06_node.yaml; do cat $${f} | \
		kubectl delete \
        	--wait=false \
        	--ignore-not-found=true \
        	--context $(KUBE_CONTEXT) -f - || true; done
	rm -f calico-arm calicoctl calicoctl_arm64 calico-ipam calico-node.crt \
		calico-node.csr calico-node.key cni typhaca.crt typhaca.key typhaca.srl \
		typha.crt typha.csr typha.key
	for node in $(ALL_WORKERS) $(ALL_CONTROLLERS); do \
		echo "Cleaning up /etc/cni/net.d on $${node}" ; \
		ssh $$node sudo rm -f /etc/cni/net.d/10-calico.conflist /etc/cni/net.d/calico-kubeconfig ; \
		ssh $$node sudo ip link del cni0 ; \
		scp ../../../vethcleanup.sh $$node:/tmp ; \
		ssh $$node bash /tmp/vethcleanup.sh ; \
        done
