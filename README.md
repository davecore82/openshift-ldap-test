# OpenShift LDAP Connectivity Test

Simple script to test LDAP/LDAPS connectivity in OpenShift by extracting the configuration from OAuth and running `ldapsearch`.

## What It Does

1. Extracts LDAP configuration from OpenShift OAuth (URL, bind DN, password, base DN)
2. Creates a temporary test pod with `ldapsearch` installed
3. Tests connectivity to the LDAP server
4. Cleans up automatically

## Prerequisites

- Access to an OpenShift cluster with `oc` CLI
- LDAP identity provider configured in OAuth
- Permissions to read OAuth config and secrets in `openshift-config` namespace
- Permissions to create pods

## Usage

```bash
# Test the default provider (ldap-internal)
./test-ldap.sh

# Test a specific provider
./test-ldap.sh <provider-name>
```

## Example Output

```
=== Extracting LDAP Configuration from OpenShift OAuth ===
Provider: ldap-internal

LDAP URL: ldaps://ldap.example.com:636/dc=example,dc=com?uid
LDAP Host: ldaps://ldap.example.com:636
Base DN: dc=example,dc=com
Bind DN: cn=admin,dc=example,dc=com
Search Attribute: uid

=== Testing LDAP Connectivity ===
# extended LDIF
#
# LDAPv3
# base <dc=example,dc=com> with scope subtree
# filter: (uid=*)
# requesting: dn

dn: uid=user1,ou=people,dc=example,dc=com
dn: uid=user2,ou=people,dc=example,dc=com
```

## How It Works

The script:
- Uses `oc get oauth cluster` to extract LDAP settings
- Parses the LDAP URL to separate host, base DN, and search attributes
- Retrieves the bind password from the Kubernetes secret
- Runs `ldapsearch` in a temporary ubi9 pod
- Uses `LDAPTLS_REQCERT=never` for self-signed certificates
