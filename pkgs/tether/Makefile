build:
	go build -mod=vendor -o tether .

test:
	go test -mod=vendor ./...

fmt:
	gofmt -w *.go

deploy: test
	rsync -a --delete --exclude tether --rsync-path="sudo rsync" ./ atlas:/etc/nixos/tether/
	@echo "next: ssh atlas 'sudo nixos-rebuild switch --flake /etc/nixos'"

provision:
	secretspec run --reason "render /var/lib/tether.env on atlas" -- ./provision.sh

.PHONY: build test fmt deploy provision
