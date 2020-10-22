## Standalone JBoss Deployment

- Expects ansible 2.9.11 or newer
- Expects CentOS/RHEL 7 hosts
- Expects Jboss 7.2.0 
	1. Download Jboss EAP 7.2 from https://developers.redhat.com/download-manager/file/jboss-eap-7.2.0.zip
	2. Place the jboss-eap-7.2.0.zip file in roles/jboss-eap-standalone/files folder	

These playbooks deploy a very basic implementation of JBoss Enterprise Application Server
7.2 version. To use them, first edit the `hosts` inventory file to contain the
hostnames of the machines on which you want JBoss deployed, and edit the 
group_vars/all file to set any JBoss configuration parameters you need.

Then run the playbook, like this:

	ansible-playbook -i hosts roleplay.yml

When the playbook run completes, you should be able to see the JBoss
Application Server running on the ports you chose, on the target machines.

This is a very simple playbook and could serve as a starting point for more
complex JBoss-based projects. 

## Application deployment

The playbook deploy-application.yml may be used to deploy the HelloWorld and Ticket Monster demo applications to JBoss hosts that have been deployed using site.yml, as above.

Run the playbook using:

	ansible-playbook -i hosts deploy-application.yml
	
The HelloWorld application will be available at `http://<jboss server>:<http_port>/helloworld`

The Ticket Monster application will be available at `http://<jboss server>:<http_port>/ticket-monster`


