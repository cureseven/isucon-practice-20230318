.PHONY: *

gogo: stop-services build truncate-logs start-services

build:
	cd go && go build -o isucondition
	scp go/isucondition isucon-app3:~/webapp/go

stop-services:
	sudo systemctl stop nginx
	sudo systemctl stop isucondition.go.service
	ssh isucon-app3 "sudo systemctl stop isucondition.go.service"
	ssh isucon-app3 "sudo systemctl stop mysql"
	ssh isucon-app2 "sudo systemctl stop mysql"

start-services:
	ssh isucon-app2 "sudo systemctl start mysql"
	sleep 2
	ssh isucon-app3 "sudo systemctl start mysql"
	sleep 2
	ssh isucon-app3 "sudo systemctl start isucondition.go.service"
	sudo systemctl start isucondition.go.service
	sudo systemctl start nginx

truncate-logs:
	sudo truncate --size 0 /var/log/nginx/access.log
	sudo truncate --size 0 /var/log/nginx/error.log
	ssh isucon-app3 "sudo truncate --size 0 /var/log/mysql/mysql-slow.log"
	ssh isucon-app3 "sudo chmod 777 /var/log/mysql/mysql-slow.log"
	ssh isucon-app2 "sudo truncate --size 0 /var/log/mysql/mysql-slow.log"
	ssh isucon-app2 "sudo chmod 777 /var/log/mysql/mysql-slow.log"
	sudo journalctl --vacuum-size=1K

kataribe:
	sudo cat /var/log/nginx/access.log | ./kataribe -conf kataribe.toml | grep --after-context 20 "Top 20 Sort By Total"

bench:
	ssh bench-server "cd ~/bench && ./bench -all-addresses isucondition-1.t.isucon.dev -target isucondition-1.t.isucon.dev -tls -jia-service-url http://172.31.44.190:5000"