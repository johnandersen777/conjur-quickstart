set -x
docker-compose up -d
# TODO Automate yes to self signed cert for client conjur init
# yes | socat - SHELL:"docker-compose exec client conjur init -u https://proxy -a myConjurAccount --self-signed",pty,ctty,echo=0
docker-compose exec client conjur init -u https://proxy -a myConjurAccount --self-signed
docker-compose exec conjur conjurctl account create myConjurAccount > admin_data
docker-compose exec client conjur login -i admin -p $(cat admin_data | grep API | awk '{print $NF}')
docker-compose exec client conjur policy load -b root -f /policy/BotApp.yml > my_app_data
docker-compose exec client conjur logout
docker-compose exec client conjur login -i Dave@BotApp -p $(cat my_app_data | jq -r '.created_roles."myConjurAccount:user:Dave@BotApp".api_key')
docker-compose exec client conjur whoami | yq -P
secretVal=$(openssl rand -hex 12 | tr -d '\r\n')
docker-compose exec client conjur variable set -i BotApp/secretVar -v ${secretVal}
docker exec -e API_KEY=$(cat my_app_data | jq -r '.created_roles."myConjurAccount:host:BotApp/myDemoApp".api_key') bot_app sh -c 'curl -sk -d "${API_KEY}" https://proxy/authn/myConjurAccount/host%2FBotApp%2FmyDemoApp/authenticate | tee /tmp/conjur_token' | yq -P
docker exec bot_app /tmp/program.sh
echo $secretVal
echo TODO 'https://docs.cyberark.com/conjur-open-source/latest/en/content/integrations/k8s-ocp/k8s-app-identity-jwt.htm?tocpath=Integrations%7COpenShift%252FKubernetes%7CSet%20up%20Kubernetes%20authentication%7CJWT-based%20Kubernetes%20authentication%7C_____1'
