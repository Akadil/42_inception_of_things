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

# so reqs are:
# 1. DOMAIN - probably domain in cluster, but as I know it should also be 
# 	accessible outside of it
# 2. Just any email. For identification purposes I gues
