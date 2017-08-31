all: apply

apply:
	terraform apply

plan:
	terraform plan

clean:
	rm -f rollbar_test.zip
