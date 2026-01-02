## Tasks

All changes in this section must be made in **Helm values or templates**, unless explicitly stated otherwise.

By default, the application is expected to be reachable at:

BASE_URL = http://kube-lab-api.127.0.0.1.nip.io

### Warm-up: Helm Values Basics

These tasks focus on becoming familiar with Helm values and how they affect the running Deployment.

1) Set the number of API replicas to 3  
   - File: devops/kube-lab/values.yaml  
   - Key: api.replicas

2) Set the image pull policy to Always  
   - Key: api.image.pullPolicy

3) Add a greeting configuration value  
   - Key: config.APP_GREETING  
   - Value: Welcome to the Lab

4) Add an application environment flag  
   - Key: config.APP_ENV  
   - Value: lab

5) Ensure a secret is present at runtime  
   - Create a Kubernetes Secret containing API_KEY  
   - The value can be any non-empty string  
   - The application must report that the secret is present


### Deployment Tuning

These tasks focus on production-style Deployment configuration.

6) Configure resource requests  
   - cpu: 100m  
   - memory: 128Mi  

7) Configure resource limits  
   - cpu: 250m  
   - memory: 256Mi  

8) Add a pod annotation  
   - Key: example.com/release  
   - Value: lab  

9) Add Service annotations for Prometheus scraping  
   - prometheus.io/scrape: "true"  
   - prometheus.io/port: "5000"  

10) Configure a rolling update strategy  
    - maxSurge: 1  
    - maxUnavailable: 0  
    - Location: api.strategy


### Placement and Routing

These tasks control where pods run and how traffic reaches them.

11) Add a node selector  
    - kubernetes.io/os: linux  

12) Add a toleration  
    - key: workload  
    - operator: Exists  
    - effect: NoSchedule  

13) Add pod anti-affinity  
    - Spread pods by app.kubernetes.io/name  
    - Preferred or required affinity is acceptable  

14) Add an additional Ingress host  
    - Host: kube-lab.local  

15) Enable TLS for the new host  
    - Secret name: kube-lab-tls  
    - Must cover kube-lab.local  


### Autoscaling

These tasks enable and configure the Horizontal Pod Autoscaler.

16) Enable autoscaling  
    - autoscaling.enabled: true  

17) Set the minimum number of replicas  
    - autoscaling.minReplicas: 2  

18) Set the maximum number of replicas  
    - autoscaling.maxReplicas: 5  

19) Configure the CPU utilization target  
    - autoscaling.targetCPUUtilizationPercentage: 60  


### Overrides

This task introduces environment-specific overrides.

20) Create a development override file  
    - File: devops/kube-lab/values.dev.yaml  

    The file must contain:
    - api.replicas: 1  
    - api.ingress.hosts: [ "kube-lab-dev.127.0.0.1.nip.io" ]


## Grading

1) Deploy the application so it is reachable via Ingress  
   - Default BASE_URL: http://kube-lab-api.127.0.0.1.nip.io  

2) Run the automated grader:

   make grade

   or explicitly specify the base URL:

   BASE_URL=http://kube-lab.local ./tasks.sh

3) Review the output  
   - Each task is marked as pass or fail  
   - A final score out of 20 is displayed  

The grader represents the **contract** for this lab.
If all checks pass, the deployment is considered correct.
