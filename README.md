# nodeapp  - autoscaling solution on GKE for the node application  (mondodb , nodejs , k8s , GCP)

1. Mongodb replicaset installed on 3 instances (not gke) - master,slave,arbiter
2. Nodeapp code should be updated to use the replicaset instead of a single server
3. Nodeapp should be deployed on GKE with autoscaling and should scale from 2 to 10 pods.
4. Nodeapp should be exposed with an ingress with http


# 1. gcp-mongodb
Open shell :
gcloud config set project candidate-6

git clone https://github.com/bahaahusari/nodeapp.git

cd nodeapp
1.	Create an SSH keypair on your machine for the VMs to be able to SSH to each other:

	ssh-keygen -f /tmp/temp_id_rsa -C ubuntu@mongodb-rs

•	2. Create an instance template: with mongo dB installed :

gcloud compute instance-templates create mongodb-replicaset-template \
    --machine-type e2-medium\
    --image-family ubuntu-1804-lts \
    --image-project ubuntu-os-cloud \
    --boot-disk-type pd-ssd \
    --boot-disk-size 25GB \
    --tags mongodb-replicaset \
	   --scopes=https://www.googleapis.com/auth/cloud-platform \
    --metadata mongodb_ssh_priv_key="$(cat /tmp/temp_id_rsa)",mongodb_ssh_pub_key="$(cat /tmp/temp_id_rsa.pub)" \
    --metadata-from-file startup-script=script.sh,shutdown-script=down-script.sh

* Create the instance group:


gcloud compute instance-groups managed create mongodb-replicaset \
    --base-instance-name mongodb-rs\
    --size 3 \
    --region europe-west1 \
    --template mongodb-replicaset-template
    
•	Set permission Login to the first instance and check if MongoDB replicaset is running well
	- Initiate the Replica Set on this node to make this a Primary node:
	
rs.initiate()

or

rs.initiate({
_id: "replicaset01",
members: [
{ _id: 0, host: "mongodb-rs-94th" },
{ _id: 1, host: "mongodb-rs-4kdq" },
{ _id: 2, host: "mongodb-rs-c8j6" }
]
})

Check the replica status with :

rs.status()

mongodb-rs-qwt6:27017   SECONDARY       arbiter

mongodb-rs-41bg:27017   PRIMARY         master

mongodb-rs-7qpb:27017   SECONDARY  slave




Convert Secondary to Arbiter Node : 

rs.remove("mongodb-rs-qwt6:27017")

rs.addArb("mongodb-rs-qwt6:27017")

Connecting arbiter node : from secondary node, we will now add arbiter node

rs.add( { host: "mongodb-rs-qwt6:27017", priority: 0, votes: 1, arbiterOnly: true, hidden: false } )


Mongo 
rs.conf()
cfg = rs.conf()
cfg.members[2].priority = 0  ## arbiter
cfg.members[0].priority = 5   ## slave
cfg.members[1].priority = 10   ## master

cfg.members[2].arbiterOnly= true
cfg.members[0].arbiterOnly= false
cfg.members[1].arbiterOnly= false

make the changes take effect, reconfigure the Replica set with new configuration :
rs.reconfig(cfg)

restart mongodb server :
sudo service mongod restart

Connecting secondary node : from the PRIMARY node, add secondary node configuration

mongodb-rs-41bg:27017   PRIMARY         uptime: 811s
mongodb-rs-7qpb:27017   SECONDARY       uptime: 810s
mongodb-rs-qwt6:27017   (not reachable/healthy)   

•	Login to the first instance and check if MongoDB replicaset is running well (please note that the bootstrap process can take 1-2 minutes):
status :

mongo --norc --quiet --eval 'rs.status().members.forEach(function(member) {print(member["name"] + "\t" + member["stateStr"] + "  \tuptime: " + member["uptime"] + "s")})'



connect to mongodb user :in mongodb 

mongo admin --username bahaa --password 123

Replica Set Connections :

mongoose.connect(
'mongodb://bahaa:123@mongodb-rs-41bg:27017/docker-node-mongo',
);

Or 

mongoose.connect(
 'mongodb://10.132.15.212:27017/docker-node-mongo',   
);


# 2. Nodeapp code updated in mongoDb

•	Push your Nodejs code to GitHub and clone it to your VM:
git clone https://github.com/bahaahusari/nodeapp.git
cd nodeapp

•	Install Nodejs, npm, and run command npm install inside the app folder to install all the dependency associated with the project:

sudo apt install -y curl
sudo curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
sudo apt install -y nodejs

replicaset instance install node app :D

sudo npm i 
sudo node nodeapp.js

on port : 80

host : mongodb-rs-41bg   (      test  )
ip : 104.199.110.161:80  


#  3. Nodeapp deployed on GKE :

export PROJECT_ID="candidate-6"
gcloud config set project $PROJECT_ID
gcloud config set compute/zone europe-west1-b

gcloud config set project candidate-6

Open shell and make cluster :  (autoscaling and should scale from 2 to 10 pods.)

gcloud container clusters create nodeapp-cluster \
	--machine-type e2-medium \
	--num-nodes 3 \

Connect to the cluster :

gcloud container clusters get-credentials nodeapp-cluster \
--region europe-west1 \
--project candidate-6
Build and push the image to the Container Registry:
gcloud auth configure-docker

docker build -t gcr.io/candidate-6/nodeapp:v2 .

docker push gcr.io/candidate-6/nodeapp:v2

Create Kubernetes Services :
gcloud components install kubectl

kubectl create deployment nodeappp --image=gcr.io/candidate-6/nodeapp:v2

kubectl expose deployment nodeappp --type=LoadBalancer --port 80 --target-port 3000

kubectl scale deployment nodeappp --replicas=3


