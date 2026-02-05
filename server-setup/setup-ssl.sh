#!/bin/bash
# Run this after DNS propagates to get SSL certificate
# Usage: sudo bash setup-ssl.sh deliverabilityanalyzer.xyz

DOMAIN=${1:-deliverabilityanalyzer.xyz}

echo "Getting SSL certificate for $DOMAIN..."

# Get certificate
certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN --redirect

# Update Postfix to use TLS
if [ -f /etc/letsencrypt/live/$DOMAIN/fullchain.pem ]; then
  postconf -e "smtpd_tls_cert_file=/etc/letsencrypt/live/$DOMAIN/fullchain.pem"
  postconf -e "smtpd_tls_key_file=/etc/letsencrypt/live/$DOMAIN/privkey.pem"
  systemctl reload postfix
  echo "SSL configured successfully!"
else
  echo "Certificate not found. Make sure DNS is pointing to this server."
  exit 1
fi
