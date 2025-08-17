
hub_infra:
	(cd hub && terraform apply)

dev_infra:
	(cd env/dev && terraform apply)

