#!/bin/bash
# OpenShift LDAP Connectivity Test
# Extracts LDAP configuration from OAuth and tests connectivity with ldapsearch

set -e

# Configuration
PROVIDER_NAME="${1:-ldap-internal}"

echo "=== Extracting LDAP Configuration from OpenShift OAuth ==="
echo "Provider: $PROVIDER_NAME"
echo ""

# Get LDAP configuration from OAuth
LDAP_URL=$(oc get oauth cluster -o jsonpath="{.spec.identityProviders[?(@.name=='$PROVIDER_NAME')].ldap.url}")
BIND_DN=$(oc get oauth cluster -o jsonpath="{.spec.identityProviders[?(@.name=='$PROVIDER_NAME')].ldap.bindDN}")
BIND_SECRET=$(oc get oauth cluster -o jsonpath="{.spec.identityProviders[?(@.name=='$PROVIDER_NAME')].ldap.bindPassword.name}")
BIND_PASSWORD=$(oc get secret $BIND_SECRET -n openshift-config -o jsonpath='{.data.bindPassword}' | base64 -d)

# Parse URL components
LDAP_HOST=$(echo $LDAP_URL | sed 's|\(.*://[^/]*\)/.*|\1|')
BASE_DN=$(echo $LDAP_URL | sed 's|.*://[^/]*/\([^?]*\).*|\1|')
SEARCH_ATTR=$(echo $LDAP_URL | sed 's|.*?\(.*\)|\1|')

# Display configuration
echo "LDAP URL: $LDAP_URL"
echo "LDAP Host: $LDAP_HOST"
echo "Base DN: $BASE_DN"
echo "Bind DN: $BIND_DN"
echo "Search Attribute: $SEARCH_ATTR"
echo ""

# Test LDAP connectivity
echo "=== Testing LDAP Connectivity ==="
oc run ldap-test --rm -it --image=registry.access.redhat.com/ubi9/ubi:latest --restart=Never -- bash -c "
dnf install -y openldap-clients -q -y && \
LDAPTLS_REQCERT=never ldapsearch -x -H $LDAP_HOST \
  -D '$BIND_DN' -w '$BIND_PASSWORD' \
  -b '$BASE_DN' '($SEARCH_ATTR=*)' dn
"

echo ""
echo "=== Test Complete ==="
