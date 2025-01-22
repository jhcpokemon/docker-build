FROM  quay.io/operator-framework/operator-sdk:v1.37
ADD helm /usr/local/bin
RUN chmod +x /usr/local/bin/helm; \
    helm repo add bitnami https://charts.bitnami.com/bitnami; \
    mkdir /operator; \
    cd /operator; \
    helm pull bitnami/nginx; \
    ls; \
    operator-sdk init --plugins=helm --domain=sinopec.com --group=pcitc --helm-chart=nginx-18.3.5.tgz