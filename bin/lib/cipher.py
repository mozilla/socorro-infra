#!/usr/bin/env python

# Apply recommendation from https://wiki.mozilla.org/Security/Server_Side_TLS

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Contributors:
# Gene Wood [:gene]
# Julien Vehent [:ulfr]
# JP Schneider [:jp]

import boto.ec2.elb
import sys

if len(sys.argv) < 3:
  print "usage : %s REGION ELB-NAME <MODE>" % sys.argv[0]
  print ""
  print "Example : %s us-west-2 persona-org-0810" % sys.argv[0]
  print "MODE can be 'old', 'intermediate' (default) or 'modern'"
  print "see https://wiki.mozilla.org/Security/Server_Side_TLS"
  sys.exit(1)

region = sys.argv[1]
load_balancer_name = sys.argv[2]
try:
    conf_mode = sys.argv[3]
except IndexError:
    conf_mode = 'intermediate'
conn_elb = boto.ec2.elb.connect_to_region(region)

#import logging
#logging.basicConfig(level=logging.DEBUG)

policy = {'old':{},
          'intermediate':{},
          'modern':{}}

policy['old']['name'] = 'Mozilla-OpSec-TLS-Old-v-3-2'
policy['old']['ciphersuite'] = {
                "ECDHE-ECDSA-AES128-GCM-SHA256": True,
                "ECDHE-RSA-AES128-GCM-SHA256": True,
                "ECDHE-ECDSA-AES128-SHA256": True,
                "ECDHE-RSA-AES128-SHA256": True,
                "ECDHE-ECDSA-AES128-SHA": True,
                "ECDHE-RSA-AES128-SHA": True,
                "ECDHE-ECDSA-AES256-GCM-SHA384": True,
                "ECDHE-RSA-AES256-GCM-SHA384": True,
                "ECDHE-ECDSA-AES256-SHA384": True,
                "ECDHE-RSA-AES256-SHA384": True,
                "ECDHE-RSA-AES256-SHA": True,
                "ECDHE-ECDSA-AES256-SHA": True,
                "ADH-AES128-GCM-SHA256": False,
                "ADH-AES256-GCM-SHA384": False,
                "ADH-AES128-SHA": False,
                "ADH-AES128-SHA256": False,
                "ADH-AES256-SHA": False,
                "ADH-AES256-SHA256": False,
                "ADH-CAMELLIA128-SHA": False,
                "ADH-CAMELLIA256-SHA": False,
                "ADH-DES-CBC3-SHA": False,
                "ADH-DES-CBC-SHA": False,
                "ADH-RC4-MD5": False,
                "ADH-SEED-SHA": False,
                "AES128-GCM-SHA256": True,
                "AES256-GCM-SHA384": True,
                "AES128-SHA": True,
                "AES128-SHA256": True,
                "AES256-SHA": True,
                "AES256-SHA256": True,
                "CAMELLIA128-SHA": True,
                "CAMELLIA256-SHA": True,
                "DES-CBC3-MD5": False,
                "DES-CBC3-SHA": True,
                "DES-CBC-MD5": False,
                "DES-CBC-SHA": False,
                "DHE-DSS-AES128-GCM-SHA256": True,
                "DHE-DSS-AES256-GCM-SHA384": True,
                "DHE-DSS-AES128-SHA": True,
                "DHE-DSS-AES128-SHA256": True,
                "DHE-DSS-AES256-SHA": True,
                "DHE-DSS-AES256-SHA256": True,
                "DHE-DSS-CAMELLIA128-SHA": False,
                "DHE-DSS-CAMELLIA256-SHA": False,
                "DHE-DSS-SEED-SHA": False,
                "DHE-RSA-AES128-GCM-SHA256": True,
                "DHE-RSA-AES256-GCM-SHA384": True,
                "DHE-RSA-AES128-SHA": True,
                "DHE-RSA-AES128-SHA256": True,
                "DHE-RSA-AES256-SHA": True,
                "DHE-RSA-AES256-SHA256": True,
                "DHE-RSA-CAMELLIA128-SHA": False,
                "DHE-RSA-CAMELLIA256-SHA": False,
                "DHE-RSA-SEED-SHA": False,
                "EDH-DSS-DES-CBC3-SHA": False,
                "EDH-DSS-DES-CBC-SHA": False,
                "EDH-RSA-DES-CBC3-SHA": False,
                "EDH-RSA-DES-CBC-SHA": False,
                "EXP-ADH-DES-CBC-SHA": False,
                "EXP-ADH-RC4-MD5": False,
                "EXP-DES-CBC-SHA": False,
                "EXP-EDH-DSS-DES-CBC-SHA": False,
                "EXP-EDH-RSA-DES-CBC-SHA": False,
                "EXP-KRB5-DES-CBC-MD5": False,
                "EXP-KRB5-DES-CBC-SHA": False,
                "EXP-KRB5-RC2-CBC-MD5": False,
                "EXP-KRB5-RC2-CBC-SHA": False,
                "EXP-KRB5-RC4-MD5": False,
                "EXP-KRB5-RC4-SHA": False,
                "EXP-RC2-CBC-MD5": False,
                "EXP-RC4-MD5": False,
                "IDEA-CBC-SHA": False,
                "KRB5-DES-CBC3-MD5": False,
                "KRB5-DES-CBC3-SHA": False,
                "KRB5-DES-CBC-MD5": False,
                "KRB5-DES-CBC-SHA": False,
                "KRB5-RC4-MD5": False,
                "KRB5-RC4-SHA": False,
                "PSK-3DES-EDE-CBC-SHA": False,
                "PSK-AES128-CBC-SHA": False,
                "PSK-AES256-CBC-SHA": False,
                "PSK-RC4-SHA": False,
                "RC2-CBC-MD5": False,
                "RC4-MD5": False,
                "RC4-SHA": False,
                "SEED-SHA": False,
                "Protocol-SSLv2": False,
                "Protocol-SSLv3": True,
                "Protocol-TLSv1": True,
                "Protocol-TLSv1.1": True,
                "Protocol-TLSv1.2": True,
                "Server-Defined-Cipher-Order": True
                }

# reuse the Old policy minus SSLv3 and 3DES
policy['intermediate']['name'] = 'Mozilla-OpSec-TLS-Intermediate-v-3-2'
policy['intermediate']['ciphersuite'] = policy['old']['ciphersuite'].copy()
policy['intermediate']['ciphersuite'].update(
    {"Protocol-SSLv3": False,
    "DES-CBC3-SHA": False})

# reuse the intermediate policy minus TLSv1 and non PFS ciphers
policy['modern']['name'] = 'Mozilla-OpSec-TLS-Modern-v-3-2'
policy['modern']['ciphersuite'] = policy['intermediate']['ciphersuite'].copy()
policy['modern']['ciphersuite'].update(
    {"Protocol-TLSv1": False,
    "AES128-GCM-SHA256": False,
    "AES256-GCM-SHA384": False,
    "DHE-DSS-AES128-SHA": False,
    "AES128-SHA256": False,
    "AES128-SHA": False,
    "DHE-DSS-AES256-SHA256": False,
    "AES256-SHA256": False,
    "AES256-SHA": False,
    "CAMELLIA128-SHA": False,
    "CAMELLIA256-SHA": False})

if not conf_mode in policy.keys():
    print "Invalid policy name, must be one of %s" % policy.keys()
    sys.exit(1)

# Create the Ciphersuite Policy
params = {'LoadBalancerName': load_balancer_name,
          'PolicyName': policy[conf_mode]['name'],
          'PolicyTypeName': 'SSLNegotiationPolicyType'}
conn_elb.build_complex_list_params(
    params,
    [(x, policy[conf_mode]['ciphersuite'][x]) for x in policy[conf_mode]['ciphersuite'].keys()],
    'PolicyAttributes.member',
    ('AttributeName', 'AttributeValue'))
policy_result = conn_elb.get_list('CreateLoadBalancerPolicy', params, None, verb='POST')

# Apply the Ciphersuite Policy to your ELB
params = {'LoadBalancerName': load_balancer_name,
          'LoadBalancerPort': 443,
          'PolicyNames.member.1': policy[conf_mode]['name']}

result = conn_elb.get_list('SetLoadBalancerPoliciesOfListener', params, None)
print "New Policy '%s' created and applied to load balancer %s in %s" % (
    policy[conf_mode]['name'],
    load_balancer_name,
    region)
