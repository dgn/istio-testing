CURRENTDIR := ${PWD}

KC := --kubeconfig="$(shell kind get kubeconfig-path --name="kind")"
KUBECTL_WITH_CFG := kubectl ${KC}

create-cluster:
	@kind create cluster

delete-cluster:
	@kind delete cluster || echo No cluster found

