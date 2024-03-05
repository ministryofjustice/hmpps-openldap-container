# hmpps-openldap-container

# Vars

```
# Host to listen on for connections on LDAP_PORT
LDAP_HOST="0.0.0.0"
# Log level for slapd - see https://www.openldap.org/doc/admin24/slapdconfig.html Table 6.1: Debugging Levels
SLAPD_LOG_LEVEL="-1"
# Port to serve slapd on
LDAP_PORT=389
# S3 URI for seed ldif file
MIGRATION_S3_LOCATION=s3://<bucket>/seed.ldif"
# Password assigned to the root user
BIND_PASSWORD=secure_password
```

 

# Bastion access
## Steps to gain SSH access:
### Generate a Public Key

`ssh-keygen -t ed25519 -C "your_email@example.com"`
You’ll be asked where to save this, we’d recommend ~/.ssh/delius-core-<env>

You’ll also be asked to add a passphrase to the key, which we’d also recommend.

Raise a PR adding your public key to this file: https://github.com/ministryofjustice/modernisation-platform-environments/blob/main/terraform/environments/delius-core/bastion_linux.json

You should provide a different key for each environment, and one request access to those you need
```
{
  "keys": {
    "development": {
      "<firstinital><lastname>": "ssh-ed25519 key email"
    }
  }
}
```

Follow the Modernisation Platform Guide on how to setup the ssh config. The section “Using the Bastion as a jump server to access Linux EC2s” details how to access an EC2 via the bastion.

https://user-guide.modernisation-platform.service.justice.gov.uk/user-guide/accessing-ec2s.html#port-forwarding-to-ec2-using-the-bastion

As this access method is documented by the Modernisation Platform, the above document should be treated as the best source for configuration guidelines. However, the below is an example that is working at the time of writing:

### Example ssh config
```
Host delius-core-dev-bastion
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
  LogLevel QUIET
  IdentityFile ~/.ssh/id_ed25519_mp
  User username
  ProxyCommand sh -c "aws ssm start-session --target \$(aws ec2 describe-instances --no-cli-pager --filters 'Name=tag:Name,Values=bastion-dev' --query 'Reservations[0].Instances[0].InstanceId' --profile delius-core-development/modernisation-platform-sandbox | tr -d '\"') --document-name AWS-StartSSHSession --parameters 'portNumber=%p' --profile delius-core-development/modernisation-platform-sandbox --region eu-west-2"
```

Remember to replace the username, filter name tag value and the aws profile.

There is one bastion per delius environment and the filter should be written as bastion-<env>.

### Connecting
1. Assume an AWS Role

2. `ssh delius-core-dev-bastion`

You’ll be presented with a bash shell and the openldap client tools are pre-installed.

 
