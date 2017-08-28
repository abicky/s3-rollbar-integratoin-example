all: apply

apply: build
	terraform apply

plan: build
	terraform plan

build: clean
	zip rollbar_test.zip index.js

clean:
	rm -f rollbar_test.zip
