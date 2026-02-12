# steps:
# 1. Install helm
#
#	curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4 | bash
#
# 2. Install helm repository Gitlab (chart to use)
#
# 	helm repo add gitlab https://charts.gitlab.io/
# 
# 3. Then something like this with bunch of parameters, which I don't know  

helm install gitlab gitlab/gitlab \
  --set global.hosts.domain=DOMAIN \
  --set certmanager-issuer.email=me@example.com

helm upgrade --install gitlab gitlab/gitlab -n gitlab -f https://gitlab.com/gitlab-org/charts/gitlab/raw/master/examples/values-minikube-minimum.yaml --set global.hosts.domain=k3d.gitlab.com  --set global.hosts.externalIP=0.0.0.0   --set global.hosts.https=false   --timeout 600s --debug --wait-for-jobs

# so reqs are:
# 1. DOMAIN - probably domain in cluster, but as I know it should also be 
# 	accessible outside of it
# 2. Just any email. For identification purposes I guess
#
kubectl port-forward -n gitlab svc/gitlab-webservice-default 8181:8080

