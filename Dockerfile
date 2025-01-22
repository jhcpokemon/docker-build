FROM  quay.io/operator-framework/operator-sdk:v1.37
RUN mkdir /operator; \
    cd /operator; \
    operator-sdk init --plugins=helm --domain=sinopec.com --group=pcitc --helm-chart=nginx --helm-chart-repo=https://charts.bitnami.com/bitnami