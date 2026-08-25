docker build . --tag phantony/transit-encrypt-service:0.4 --platform linux/amd64
docker push phantony/transit-encrypt-service:0.4

dd if=/dev/urandom of=0.2g_random.data bs=10m count=20
dd if=/dev/urandom of=0.5g_random.data bs=10m count=51
dd if=/dev/urandom of=1.0g_random.data bs=10m count=102
dd if=/dev/urandom of=2.0g_random.data bs=10m count=204
dd if=/dev/urandom of=10g_random.data bs=10m count=1024

1. kubectl patch storageclass gp2 -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
2. add s3 permissions to eks node groups.
3. refactor for any file type
4. decrypt.
5. vso / sidecar injecting token as env.


The node was low on resource: ephemeral-storage. Threshold quantity: 2139512454, available: 17672Ki. Container transit-encrypt was using 15363024Ki, request is 0, has larger consumption of ephemeral-storage.

sudo growpart /dev/nvme0n1 1
sudo xfs_growfs -d /dev/nvme0n1p1