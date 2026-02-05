#!/bin/bash
# Deliverability Checker - Server Setup Script
# Run as root on a fresh Ubuntu 22.04/24.04 VPS
# Usage: sudo bash install.sh your-domain.com

set -e

DOMAIN=${1:-deliverabilityanalyzer.xyz}
APP_USER="deliverability"
APP_DIR="/opt/deliverability-checker"
DATA_DIR="/var/lib/deliverability-checker/emails"
LOG_DIR="/var/log/deliverability-checker"

echo "=== Deliverability Checker Setup ==="
echo "Domain: $DOMAIN"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo bash install.sh)"
  exit 1
fi

# Update system
echo "[1/8] Updating system..."
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq

# Pre-configure postfix to avoid interactive prompts
echo "[2/8] Installing dependencies..."
debconf-set-selections <<< "postfix postfix/mailname string $DOMAIN"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"

DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
  postfix \
  opendkim \
  opendkim-tools \
  opendmarc \
  postfix-policyd-spf-python \
  nginx \
  certbot \
  python3-certbot-nginx \
  curl

# Install Node.js 20.x
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# Create app user
echo "[3/8] Creating application user..."
if ! id "$APP_USER" &>/dev/null; then
  useradd -r -m -s /bin/false $APP_USER
fi

# Add deliverability user to postfix group for mail processing
usermod -a -G mail $APP_USER

# Create directories
echo "[4/8] Creating directories..."
mkdir -p $APP_DIR
mkdir -p $DATA_DIR
mkdir -p $LOG_DIR
chown -R $APP_USER:$APP_USER $DATA_DIR
chown -R $APP_USER:$APP_USER $LOG_DIR
chmod 755 $DATA_DIR
chmod 755 $LOG_DIR

# Copy application files (go up from server-setup to project root)
echo "[5/8] Setting up application..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cp -r "$PROJECT_DIR"/* $APP_DIR/
rm -rf $APP_DIR/server-setup  # Don't need setup files in production

cd $APP_DIR
npm install --production
chown -R $APP_USER:$APP_USER $APP_DIR

# Make email parser executable
chmod +x $APP_DIR/src/email-parser.js

echo "[6/8] Configuring Postfix..."
# Backup original config
cp /etc/postfix/main.cf /etc/postfix/main.cf.backup 2>/dev/null || true
cp /etc/postfix/master.cf /etc/postfix/master.cf.backup 2>/dev/null || true

# Configure Postfix main.cf
cat > /etc/postfix/main.cf << EOF
# Postfix configuration for Deliverability Checker
# Accept ALL emails - do not reject based on authentication

smtpd_banner = \$myhostname ESMTP
biff = no
append_dot_mydomain = no
readme_directory = no

# TLS parameters (will be enabled after certbot)
smtpd_tls_security_level = may
smtp_tls_security_level = may

# Basic settings
myhostname = $DOMAIN
mydomain = $DOMAIN
myorigin = \$mydomain
mydestination = \$myhostname, \$mydomain, localhost, localhost.\$mydomain
mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128
inet_interfaces = all
inet_protocols = all

# IMPORTANT: Accept all mail - minimal restrictions
# We want to receive emails even if SPF/DKIM/DMARC fail
smtpd_recipient_restrictions =
    permit_mynetworks,
    check_policy_service unix:private/policyd-spf,
    permit

smtpd_relay_restrictions =
    permit_mynetworks,
    permit

# Disable strict sender checks
smtpd_sender_restrictions =
smtpd_helo_required = no
strict_rfc821_envelopes = no
disable_vrfy_command = yes

# Transport to our custom handler
transport_maps = regexp:/etc/postfix/transport
local_recipient_maps =

# Milters for authentication checking (adds headers, doesn't reject)
smtpd_milters = unix:/run/opendkim/opendkim.sock, unix:/run/opendmarc/opendmarc.sock
non_smtpd_milters = unix:/run/opendkim/opendkim.sock, unix:/run/opendmarc/opendmarc.sock
milter_default_action = accept
milter_protocol = 6

# Limits
message_size_limit = 10485760
mailbox_size_limit = 0
EOF

# Transport map - route test emails to our handler
cat > /etc/postfix/transport << EOF
/^test-[a-f0-9]+@${DOMAIN//./\\.}\$/   deliverability:
EOF

postmap /etc/postfix/transport

# Configure master.cf for custom transport
cat > /etc/postfix/master.cf << EOF
# Postfix master process configuration
smtp      inet  n       -       y       -       -       smtpd
pickup    unix  n       -       y       60      1       pickup
cleanup   unix  n       -       y       -       0       cleanup
qmgr      unix  n       -       n       300     1       qmgr
tlsmgr    unix  -       -       y       1000?   1       tlsmgr
rewrite   unix  -       -       y       -       -       trivial-rewrite
bounce    unix  -       -       y       -       0       bounce
defer     unix  -       -       y       -       0       bounce
trace     unix  -       -       y       -       0       bounce
verify    unix  -       -       y       -       1       verify
flush     unix  n       -       y       1000?   0       flush
proxymap  unix  -       -       n       -       -       proxymap
proxywrite unix -       -       n       -       1       proxymap
smtp      unix  -       -       y       -       -       smtp
relay     unix  -       -       y       -       -       smtp
showq     unix  n       -       y       -       -       showq
error     unix  -       -       y       -       -       error
retry     unix  -       -       y       -       -       error
discard   unix  -       -       y       -       -       discard
local     unix  -       n       n       -       -       local
virtual   unix  -       n       n       -       -       virtual
lmtp      unix  -       -       y       -       -       lmtp
anvil     unix  -       -       y       -       1       anvil
scache    unix  -       -       y       -       1       scache
postlog   unix-dgram n  -       n       -       1       postlogd

# Policy SPF checker
policyd-spf  unix  -       n       n       -       0       spawn
    user=policyd-spf argv=/usr/bin/policyd-spf

# Our custom deliverability transport
deliverability   unix  -       n       n       -       10      pipe
    flags=Rq user=$APP_USER argv=/usr/bin/node $APP_DIR/src/email-parser.js \${recipient}
EOF

echo "[7/8] Configuring OpenDKIM..."
cat > /etc/opendkim.conf << EOF
Syslog yes
SyslogSuccess yes
LogWhy yes
Mode v
Canonicalization relaxed/simple
OversignHeaders From
Socket unix:/run/opendkim/opendkim.sock
PidFile /run/opendkim/opendkim.pid
UMask 007
UserID opendkim:opendkim
AlwaysAddARHeader yes
AuthservID $DOMAIN
EOF

mkdir -p /run/opendkim
chown opendkim:opendkim /run/opendkim

echo "[8/8] Configuring OpenDMARC..."
cat > /etc/opendmarc.conf << EOF
AuthservID $DOMAIN
FailureReports false
IgnoreAuthenticatedClients true
IgnoreHosts /etc/opendmarc/ignore.hosts
RejectFailures false
Socket unix:/run/opendmarc/opendmarc.sock
Syslog true
TrustedAuthservIDs $DOMAIN
UMask 007
UserID opendmarc:opendmarc
EOF

mkdir -p /run/opendmarc
mkdir -p /etc/opendmarc
echo "localhost" > /etc/opendmarc/ignore.hosts
chown -R opendmarc:opendmarc /run/opendmarc
chown -R opendmarc:opendmarc /etc/opendmarc

# Create systemd service for the app
cat > /etc/systemd/system/deliverability-checker.service << EOF
[Unit]
Description=Deliverability Checker Web App
After=network.target

[Service]
Type=simple
User=$APP_USER
WorkingDirectory=$APP_DIR
Environment=NODE_ENV=production
Environment=PORT=3000
Environment=DOMAIN=$DOMAIN
Environment=DATA_DIR=$DATA_DIR
Environment=LOG_FILE=$LOG_DIR/parser.log
ExecStart=/usr/bin/node src/server.js
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Configure nginx (HTTP only initially - certbot will add HTTPS)
cat > /etc/nginx/sites-available/deliverability-checker << EOF
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

ln -sf /etc/nginx/sites-available/deliverability-checker /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Add postfix user to opendkim and opendmarc groups for socket access
usermod -a -G opendkim postfix
usermod -a -G opendmarc postfix

# Reload and start services
echo "Reloading services..."
systemctl daemon-reload
systemctl enable opendkim opendmarc postfix nginx deliverability-checker

# Start services in order
systemctl restart opendkim
sleep 2
systemctl restart opendmarc
sleep 2
systemctl restart postfix
systemctl restart nginx
systemctl start deliverability-checker

echo ""
echo "=== Setup Complete ==="
echo ""
echo "IMPORTANT: Before this works, you need to:"
echo ""
echo "1. Point your domain's DNS to this server:"
echo "   - A record: $DOMAIN -> YOUR_SERVER_IP"
echo "   - MX record: $DOMAIN -> $DOMAIN (priority 10)"
echo ""
echo "2. Get SSL certificate (after DNS propagates):"
echo "   certbot --nginx -d $DOMAIN"
echo ""
echo "3. Open firewall ports:"
echo "   ufw allow 22    # SSH"
echo "   ufw allow 25    # SMTP"
echo "   ufw allow 80    # HTTP"
echo "   ufw allow 443   # HTTPS"
echo "   ufw enable"
echo ""
echo "4. Test the setup:"
echo "   - Visit https://$DOMAIN"
echo "   - Generate a test email address"
echo "   - Send an email to it"
echo ""
echo "Logs:"
echo "   - App: journalctl -u deliverability-checker -f"
echo "   - Mail: tail -f /var/log/mail.log"
echo "   - Parser: tail -f $LOG_DIR/parser.log"
