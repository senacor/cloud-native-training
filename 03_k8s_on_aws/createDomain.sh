parentZoneID=Z20TZEMMWGSQZX

echo "create new hosted zone ${DOMAIN}"
# Note: This example assumes you have jq installed locally.
ID=$(uuidgen)

nameserver=`aws route53 create-hosted-zone --name ${DOMAIN} --caller-reference $ID | jq .DelegationSet.NameServers`
nameserver1=`echo $nameserver | jq .[0]`
nameserver2=`echo $nameserver | jq .[1]`
nameserver3=`echo $nameserver | jq .[2]`
nameserver4=`echo $nameserver | jq .[3]`

echo "List old hosted zone"
# Note: This example assumes you have jq installed locally.
aws route53 list-hosted-zones | jq '.HostedZones[] | select(.Name=="${domain}.") | .Id'

FILE="./${DOMAIN}.json"

echo "Create JSON config"
cat > $FILE <<- EOM
{
  "Comment": "Create a subdomain NS record in the parent domain",
  "Changes": [
    {
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "${DOMAIN}",
        "Type": "NS",
        "TTL": 300,
        "ResourceRecords": [
          {
            "Value": ${nameserver1}
          },
          {
            "Value": ${nameserver2}
          },
          {
            "Value": ${nameserver3}
          },
          {
            "Value": ${nameserver4}
          }
        ]
      }
    }
  ]
}
EOM

echo "Change resource record sets"
aws route53 change-resource-record-sets \
 --hosted-zone-id $parentZoneID \
 --change-batch file://${DOMAIN}.json


