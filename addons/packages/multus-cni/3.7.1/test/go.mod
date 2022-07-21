module github.com/vmware-tanzu/community-edition/addons/packages/multus-cni/3.7.1/test

go 1.17

require (
	github.com/onsi/ginkgo v1.16.4
	github.com/onsi/gomega v1.20.0
	github.com/vmware-tanzu/community-edition/addons/packages/test/pkg v0.0.0-00010101000000-000000000000
)

require (
	github.com/fsnotify/fsnotify v1.4.9 // indirect
	github.com/google/go-cmp v0.5.8 // indirect
	github.com/nxadm/tail v1.4.8 // indirect
	golang.org/x/net v0.0.0-20220425223048-2871e0cb64e4 // indirect
	golang.org/x/sys v0.0.0-20220422013727-9388b58f7150 // indirect
	golang.org/x/text v0.3.7 // indirect
	gopkg.in/tomb.v1 v1.0.0-20141024135613-dd632973f1e7 // indirect
	gopkg.in/yaml.v3 v3.0.1 // indirect
)

replace github.com/vmware-tanzu/community-edition/addons/packages/test/pkg => ../../../test/pkg
