#!/usr/bin/env sh

if [ -z "$HOMESERVER" ]; then
  echo "Please ensure HOMESERVER environment variable is set to the IP or hostname of the homeserver."
  exit 1
fi
if [ -z "$SYNAPSE_IP" ]; then
  echo "Please ensure SYNAPSE_IP environment variable is set to the IP of the homeserver."
  exit 1
fi
if [ -z "$INTEGRATION_USER1" ]; then
  echo "Please ensure INTEGRATION_USER1 environment variable is set to first user name."
  exit 1
fi
if [ -z "$INTEGRATION_PASSWORD1" ]; then
  echo "Please ensure INTEGRATION_PASSWORD1 environment variable is set to first user password."
  exit 1
fi
if [ -z "$INTEGRATION_USER2" ]; then
  echo "Please ensure INTEGRATION_USER2 environment variable is set to second user name."
  exit 1
fi
if [ -z "$INTEGRATION_PASSWORD2" ]; then
  echo "Please ensure INTEGRATION_PASSWORD2 environment variable is set to second user password."
  exit 1
fi

echo "Waiting for homeserver to be available... (GET http://$HOMESERVER/_matrix/client/v3/login)"

while ! curl --resolve "${HOMESERVER}:80:${SYNAPSE_IP}" -XGET "http://$HOMESERVER/_matrix/client/v3/login" >/dev/null 2>/dev/null; do
  sleep 2
  # for debugging
  # docker ps -q | xargs -n 1 docker inspect --format '{{ .Name }} {{range .NetworkSettings.Networks}} {{.IPAddress}}{{end}}' | sed 's#^/##';
done

echo "Homeserver is up."
echo "Getting well-known"

echo "get http://$HOMESERVER/.well-known/matrix/client"
curl --resolve "${HOMESERVER}:80:${SYNAPSE_IP}" -XGET "http://$HOMESERVER/.well-known/matrix/client"

# create users

echo "creating users"
curl --resolve "${HOMESERVER}:80:${SYNAPSE_IP}" -fS --retry 3 -XPOST -d "{\"username\":\"$INTEGRATION_USER1\", \"password\":\"$INTEGRATION_PASSWORD1\", \"inhibit_login\":true, \"auth\": {\"type\":\"m.login.dummy\"}}" "http://$HOMESERVER/_matrix/client/r0/register"
curl --resolve "${HOMESERVER}:80:${SYNAPSE_IP}" -fS --retry 3 -XPOST -d "{\"username\":\"$INTEGRATION_USER2\", \"password\":\"$INTEGRATION_PASSWORD2\", \"inhibit_login\":true, \"auth\": {\"type\":\"m.login.dummy\"}}" "http://$HOMESERVER/_matrix/client/r0/register"

echo "getting access tokens"
usertoken1=$(curl --resolve "${HOMESERVER}:80:${SYNAPSE_IP}" -fS --retry 3 "http://$HOMESERVER/_matrix/client/r0/login" -H "Content-Type: application/json" -d "{\"type\": \"m.login.password\", \"identifier\": {\"type\": \"m.id.user\",\"user\": \"$INTEGRATION_USER1\"},\"password\":\"$INTEGRATION_PASSWORD1\"}" | jq -r '.access_token')
usertoken2=$(curl --resolve "${HOMESERVER}:80:${SYNAPSE_IP}" -fS --retry 3 "http://$HOMESERVER/_matrix/client/r0/login" -H "Content-Type: application/json" -d "{\"type\": \"m.login.password\", \"identifier\": {\"type\": \"m.id.user\",\"user\": \"$INTEGRATION_USER2\"},\"password\":\"$INTEGRATION_PASSWORD2\"}" | jq -r '.access_token')


# get usernames' mxids
mxid1=$(curl --resolve "${HOMESERVER}:80:${SYNAPSE_IP}" -fS --retry 3 "http://$HOMESERVER/_matrix/client/r0/account/whoami" -H "Authorization: Bearer $usertoken1" | jq -r .user_id)
mxid2=$(curl --resolve "${HOMESERVER}:80:${SYNAPSE_IP}" -fS --retry 3 "http://$HOMESERVER/_matrix/client/r0/account/whoami" -H "Authorization: Bearer $usertoken2" | jq -r .user_id)

echo "usernames: $mxid1 and $mxid2"

echo "setting display names"
# setting the display name to username
curl --resolve "${HOMESERVER}:80:${SYNAPSE_IP}" -fS --retry 3 -XPUT -d "{\"displayname\":\"$INTEGRATION_USER1\"}" "http://$HOMESERVER/_matrix/client/v3/profile/$mxid1/displayname" -H "Authorization: Bearer $usertoken1"
curl --resolve "${HOMESERVER}:80:${SYNAPSE_IP}" -fS --retry 3 -XPUT -d "{\"displayname\":\"$INTEGRATION_USER2\"}" "http://$HOMESERVER/_matrix/client/v3/profile/$mxid2/displayname" -H "Authorization: Bearer $usertoken2"

echo "Set display names"

# create new room to invite user too
roomID=$(curl --resolve "${HOMESERVER}:80:${SYNAPSE_IP}" --retry 3 --silent --fail -XPOST -d "{\"name\":\"room with $INTEGRATION_USER1\"}" "http://$HOMESERVER/_matrix/client/r0/createRoom?access_token=$usertoken1" | jq -r '.room_id')
echo "Created room '$roomID'"

# send message in created room
curl --resolve "${HOMESERVER}:80:${SYNAPSE_IP}" --retry 3 --fail --silent -XPOST -d '{"msgtype":"m.text", "body":"joined room successfully"}' "http://$HOMESERVER/_matrix/client/r0/rooms/$roomID/send/m.room.message?access_token=$usertoken1"
echo "Sent message"

curl --resolve "${HOMESERVER}:80:${SYNAPSE_IP}" -fS --retry 3 -XPOST -d "{\"user_id\":\"$mxid2\"}" "http://$HOMESERVER/_matrix/client/r0/rooms/$roomID/invite?access_token=$usertoken1"
echo "Invited $INTEGRATION_USER2"
