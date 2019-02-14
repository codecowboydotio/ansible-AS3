# create projects
tower-cli project create --name ansible-AS3 --scm-type git --scm-url http://github.com/codecowboydotio/ansible-AS3 --organization Default
tower-cli project create --name ansible-AFM --scm-type git --scm-url http://github.com/codecowboydotio/ansible-AFM --organization Default

echo "Waiting for repos to sync"
./spinner.sh sleep 45


# Create credentials
tower-cli credential create --name bigip-ssh --organization Default --credential-type Machine --inputs='{"username":"root","password":"default"}'

# create inventories
tower-cli inventory create --name localhost --organization Default
tower-cli host create --name localhost --inventory localhost
tower-cli inventory create --name bigip --organization Default
tower-cli host create --name 10.1.1.245 --inventory bigip

# create job templates
tower-cli job_template create --name AFM-AS3-create --job-type run --inventory bigip --project ansible-AS3 --playbook AS3.yml --ask-variables-on-launch "true" --extra-vars "target_hosts=all HTTP_METHOD=POST file_name=AS3-create.json"

tower-cli job_template create --name AFM-AS3-remove-all --job-type run --inventory bigip --project ansible-AS3 --playbook AS3.yml --extra-vars "target_hosts=all  HTTP_METHOD=DELETE file_name=AS3-delete-all.json" 

tower-cli job_template create --name AFM-create-rule --job-type run --inventory bigip --project ansible-AFM --playbook AFM.yml --credential bigip-ssh --extra-vars "target_hosts=all  bigip_fw_rule_dest_addr=8.8.8.8 bigip_policy_name=test-policy bigip_rule_name=test-rule bigip_fw_rule_src_addr=2.2.2.2" 

tower-cli job_template create --name AFM-create-rule-survey --job-type run --inventory bigip --project ansible-AFM --playbook AFM.yml --credential bigip-ssh --extra-vars "target_hosts=all" 

tower-cli job_template modify --name=AFM-create-rule-survey --survey-spec=@ansible-AFM/survey.json --survey-enabled=true


tower-cli job_template create --name manual-vip --job-type run --inventory bigip --project ansible-AS3 --playbook manual-vip.yml --extra-vars "target_hosts=all" 
tower-cli job_template create --name pip-install  --job-type run --inventory localhost --project ansible-AS3 --playbook pip-modules.yml --extra-vars "target_hosts=all" 

# delete default stuff
tower-cli job_template delete --name "Demo Job Template"
tower-cli project delete --name "Demo Project"
tower-cli credential delete --name "Demo Credential"
tower-cli inventory delete --name "Demo Inventory"
