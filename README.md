\# Loan EMI Calculator on Kubernetes (Minikube)



A Loan EMI (Equated Monthly Instalment) calculator built with Node.js, Express, and MongoDB, deployed on a single-node Kubernetes cluster (Minikube) with a MongoDB replica set, NGINX Ingress, load balancing, self-healing, rolling updates, and Horizontal Pod Autoscaling.



\## Project Structure



```

.

├── app/            # Node.js + Express + MongoDB application source

│   ├── server.js

│   ├── package.json

│   ├── Dockerfile

│   ├── .dockerignore

│   └── public/

│       └── index.html

├── k8s/            # Kubernetes manifests (apply with kubectl apply -f k8s/)

├── scripts/        # Load-testing and profiling scripts

├── results/        # Load-test logs, CPU/memory CSVs, and graphs

└── README.md

```



\## Application Overview



\- \*\*Form inputs\*\*: loan amount (P), annual interest rate (%), tenure in months (n)

\- \*\*POST /api/emi\*\*: computes EMI, total payment, total interest, and returns the serving pod's name

\- \*\*GET /api/history\*\*: returns the last 10 calculations, newest first

\- \*\*GET /health\*\*: readiness/liveness probe target — returns 200 only when MongoDB is reachable

\- \*\*Storage\*\*: every calculation is saved to the `calculations` collection in MongoDB (`emidb` database)

\- \*\*Configuration\*\*: the MongoDB connection string is read from the `MONGO\_URL` environment variable (no hard-coded hosts/credentials)

\- The frontend uses AJAX (jQuery) — the page never reloads on form submit



\## Architecture



\- \*\*emi-web\*\*: a Kubernetes Deployment (default 3 replicas) running the Express app, exposed internally via a ClusterIP Service, fronted by an NGINX Ingress (`host: emi.local`)

\- \*\*mongo\*\*: a 3-member MongoDB replica set (`rs0`) running as a StatefulSet (`mongo-0`, `mongo-1`, `mongo-2`), each with its own 1Gi PersistentVolumeClaim, reachable via a headless Service

\- \*\*mongo-init\*\*: a one-off Job that initiates the replica set

\- \*\*HorizontalPodAutoscaler\*\*: scales `emi-web` between 1 and 5 replicas, targeting 50% average CPU utilization



\## Bringing Up the System on a Fresh Minikube Cluster



\### Prerequisites

\- Minikube and kubectl installed

\- Docker installed (used to build the app image)



\### Steps



1\. \*\*Start Minikube\*\* (adjust memory/cpus to your machine):

&#x20;  ```bash

&#x20;  minikube start --cpus=2 --memory=2647mb --driver=docker

&#x20;  minikube addons enable metrics-server

&#x20;  minikube addons enable ingress

&#x20;  ```



2\. \*\*Build the application image\*\* and load it into Minikube:

&#x20;  ```bash

&#x20;  cd app

&#x20;  npm install

&#x20;  docker build -t emi-web:1.0 .

&#x20;  minikube image load emi-web:1.0

&#x20;  cd ..

&#x20;  ```



3\. \*\*Load the MongoDB image into Minikube\*\* (if not already cached):

&#x20;  ```bash

&#x20;  docker pull mongo:7

&#x20;  minikube image load mongo:7

&#x20;  ```



4\. \*\*Apply all manifests\*\*, in order:

&#x20;  ```bash

&#x20;  kubectl apply -f k8s/00-namespace.yaml

&#x20;  kubectl apply -f k8s/01-mongo-headless-service.yaml

&#x20;  kubectl apply -f k8s/02-mongo-statefulset.yaml

&#x20;  kubectl apply -f k8s/04-mongo-configmap.yaml

&#x20;  ```

&#x20;  Wait for all 3 `mongo-\*` pods to be `Running`:

&#x20;  ```bash

&#x20;  kubectl get pods -n emi -w

&#x20;  ```



5\. \*\*Initiate the MongoDB replica set\*\*:

&#x20;  ```bash

&#x20;  kubectl apply -f k8s/03-mongo-init-job.yaml

&#x20;  kubectl logs job/mongo-init -n emi

&#x20;  ```



6\. \*\*Deploy the web app\*\*:

&#x20;  ```bash

&#x20;  kubectl apply -f k8s/05-web-deployment.yaml

&#x20;  kubectl apply -f k8s/06-web-service.yaml

&#x20;  ```



7\. \*\*Set up Ingress\*\*:

&#x20;  ```bash

&#x20;  kubectl apply -f k8s/07-ingress.yaml

&#x20;  echo "$(minikube ip) emi.local" | sudo tee -a /etc/hosts

&#x20;  ```

&#x20;  Open `http://emi.local` in a browser (or use `kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8081:80` and browse to `http://emi.local:8081` if `emi.local` is not directly reachable from your host).



8\. \*\*Enable autoscaling\*\*:

&#x20;  ```bash

&#x20;  kubectl apply -f k8s/08-hpa.yaml

&#x20;  kubectl get hpa -n emi

&#x20;  ```



9\. \*\*Verify everything is up\*\*:

&#x20;  ```bash

&#x20;  kubectl get all,pvc,configmap -n emi -o wide

&#x20;  ```



\## Load Testing and Profiling



Scripts in `scripts/` were used to generate the results in `results/`:

\- `run\_test.sh` — runs a single Apache Bench (`ab`) load test at a given request rate and replica count

\- `profile\_run.sh` — samples pod CPU/memory (`kubectl top`) and host CPU during a test run, writing CSVs

\- `run\_one.sh` — runs a load test and its profiling in parallel

\- `run\_matrix.sh` — runs all 5 request rates (10/25/50/100/200 req/s) for a given replica count

\- `hpa\_test.sh` — runs the 10-minute autoscaling test (2 min @ 10 req/s → 5 min @ 100 req/s → 3 min @ 10 req/s) while sampling HPA replica count



Results include logs and CSVs for all 15 fixed-replica runs (1/2/3 replicas × 5 rates), pod CPU/memory profiling data, and the HPA autoscaling timeline, along with the 3 required graphs.



\## Notes



\- Developed and tested on a single-node Minikube cluster running inside a VirtualBox Ubuntu VM with limited resources (2 CPUs, \~2.6GB RAM). Some load-test results show resource contention effects from this constrained environment, noted in the accompanying report.

\- The app uses the native `mongodb` Node.js driver (not Mongoose), connecting to all 3 replica set members for automatic failover.

