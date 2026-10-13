\# CTE412 Practical 15 - Campus Notice Board releases on Kubernetes



Student number: 02230153



\## 1. Purpose and software versions



Deploys the Campus Notice Board API to a local kind cluster and releases new versions with Recreate, RollingUpdate and blue/green strategies, measuring failed requests with an in-cluster availability monitor.



Final state: blue (1.0.0) and green (1.1.0, FEATURE\_PINNED=true) Deployments, production Services pointing at green, a preview Service pointing at green, and a running monitor Pod.



\- Windows with PowerShell, Docker 29.8.2

\- kind v0.33.0 (installed at C:\\kind\\kind.exe)

\- kubectl client v1.36.1

\- Application: Python 3.13 on python:3.13-alpine, non-root user 10001

\- Cluster Kubernetes version: recorded in evidence/t9-versions.txt



kind must be on PATH for the session: `$env:Path += ";C:\\kind"`



\## 2. Rebuild from an empty machine



Run from the repository root in PowerShell.



\### 2.1 Cluster (one control plane, two workers, 127.0.0.1:30090 mapped)



```

$env:Path += ";C:\\kind"

kind create cluster --name cte412-02230153 --config cluster/kind-cluster.yaml

kubectl config use-context kind-cte412-02230153

```



\### 2.2 Images (built locally, loaded into the nodes, no registry)



```

docker build -t notice-board:02230153-1.0.0 --build-arg APP\_VERSION=1.0.0 .\\app

docker build -t notice-board:02230153-1.1.0 --build-arg APP\_VERSION=1.1.0 .\\app

docker build -t notice-board:02230153-1.2.0-broken --build-arg APP\_VERSION=1.2.0-broken --build-arg BROKEN\_HEALTH=true .\\app

kind load docker-image notice-board:02230153-1.0.0 notice-board:02230153-1.1.0 notice-board:02230153-1.2.0-broken --name cte412-02230153

```



\### 2.3 Namespace, quota and limit range



```

kubectl apply -f manifests/base/namespace-quota.yaml

kubectl config set-context --current --namespace=nb-02230153

```



\### 2.4 Final state of Task 8 (order matters)



Services first, then the flag ConfigMap, then the Deployments. The ConfigMap must exist before green.yaml, otherwise the green Pods fail with CreateContainerConfigError. manifests/rolling/ is NOT applied: that Deployment was removed in Task 7 and would exceed the quota alongside blue and green.



```

kubectl apply -f manifests/bluegreen/services.yaml

kubectl apply -f manifests/bluegreen/flags.yaml

kubectl apply -f manifests/bluegreen/blue.yaml

kubectl apply -f manifests/bluegreen/green.yaml

kubectl rollout status deployment/notice-board-blue

kubectl rollout status deployment/notice-board-green

kubectl apply -f manifests/base/monitor.yaml

```



\### 2.5 Check



```

kubectl get all,configmap,endpointslices

curl.exe -s http://127.0.0.1:30090/version

curl.exe -s http://127.0.0.1:30090/notices

```



Expected: production answers with version 1.1.0 and "pinnedFirst": true; six notice-board Pods Ready.



\### 2.6 Rebuild inside an existing cluster (Task 9 test)



Delete everything except the namespace, quota and limit range, then repeat section 2.4.



```

kubectl delete deployment,service,configmap,pod --all -n nb-02230153

```



\## 3. Clean-up



```

kubectl config set-context --current --namespace=default

kind delete cluster --name cte412-02230153

```

<p align="center">
  <a href="https://github.com/TashiSeldon/CTE412_Practical15_02230153/blob/master/report/02230153_Practical15_LabReport_CTE412_4IT_AS2026.pdf">
    <img src="https://img.shields.io/badge/View%20Lab%20Report-PDF-blue?style=for-the-badge" alt="View Lab Report PDF">
  </a>
</p>



