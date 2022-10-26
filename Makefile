install:
	kubectl apply -f httpbin.yaml
	kubectl apply -f fortio.yaml

dr:
	kubectl apply -f circuit-breaking-dr.yaml

bench%:
	./bench.sh $*
