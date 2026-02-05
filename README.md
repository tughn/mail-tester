# Mail Tester

A self-hosted email header validation tool that analyzes SPF, DKIM, DMARC, MTA-STS, and TLS-RPT authentication for incoming emails.

## Overview

Mail Tester simplifies email authentication testing by providing a unique test address. Users send an email to this address, and the tool extracts and displays the raw headers along with authentication results. This is particularly useful for users who need to verify their email configuration but do not know how to extract raw headers themselves.

### Features

- **SPF Validation** - Sender Policy Framework verification
- **DKIM Validation** - DomainKeys Identified Mail signature verification
- **DMARC Validation** - Domain-based Message Authentication verification
- **MTA-STS Check** - Mail Transfer Agent Strict Transport Security
- **TLS-RPT Check** - TLS Reporting policy verification
- **Content Analysis** - Spam keyword detection and URL reputation checking
- **Raw Headers** - Full email headers displayed for manual inspection

## Architecture

```
                    +------------------+
                    |   User Email     |
                    |     Client       |
                    +--------+---------+
                             |
                             | SMTP (port 25)
                             v
+-----------------------------------------------------------+
|                      VPS Server                            |
|  +------------------+    +-----------------------------+  |
|  |     Postfix      |--->|    email-parser.js          |  |
|  |  (catch-all MTA) |    | - Parses raw email          |  |
|  +------------------+    | - Extracts headers          |  |
|                          | - Checks SPF/DKIM/DMARC     |  |
|                          | - DNS lookups for MTA-STS   |  |
|                          | - Saves results to JSON     |  |
|                          +-------------+---------------+  |
|                                        |                  |
|                                        v                  |
|                          +-------------+---------------+  |
|                          |     /var/lib/mail-tester/   |  |
|                          |         emails/             |  |
|                          |    {test-id}.json files     |  |
|                          +-------------+---------------+  |
|                                        ^                  |
|                                        |                  |
|  +------------------+    +-------------+---------------+  |
|  |      Nginx       |--->|        server.js            |  |
|  |  (reverse proxy) |    | - Express.js API            |  |
|  +------------------+    | - Serves static frontend    |  |
|                          +-----------------------------+  |
+-----------------------------------------------------------+
                             ^
                             | HTTPS (port 443)
                             |
                    +--------+---------+
                    |   User Browser   |
                    +------------------+
```

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/generate` | GET | Generate a new test email address |
| `/api/check/:id` | GET | Retrieve results for a test ID |
| `/api/health` | GET | Health check endpoint |

## External Services

### DNS Lookups (No API Key Required)

- **SPF/DKIM/DMARC** - Parsed from Authentication-Results header (added by Postfix/OpenDKIM/OpenDMARC)
- **MTA-STS** - DNS TXT lookup at `_mta-sts.{domain}` + HTTPS fetch of policy file
- **TLS-RPT** - DNS TXT lookup at `_smtp._tls.{domain}`
- **SURBL** - URL reputation check via DNS (`{domain}.multi.surbl.org`)

### Rate Limits

- **SURBL** - Free tier allows approximately 10 queries/second (limited to 10 URLs per email)
- **DNS** - Standard DNS resolver limits apply

## Deployment

### Requirements

- Ubuntu 22.04 or 24.04
- Node.js 18+
- Domain with DNS control
- VPS with port 25 open (for receiving email)

### Quick Start

1. **DNS Configuration** (at your domain registrar)

   ```
   A Record:     @  ->  YOUR_SERVER_IP
   MX Record:    @  ->  yourdomain.com (priority 10)
   ```

2. **Server Setup**

   ```bash
   ssh root@YOUR_SERVER_IP

   git clone https://github.com/tughn/mail-tester.git /opt/mail-tester
   cd /opt/mail-tester

   chmod +x server-setup/install.sh
   ./server-setup/install.sh yourdomain.com
   ```

3. **SSL Certificate**

   ```bash
   certbot --nginx -d yourdomain.com
   ```

4. **Verify Installation**

   ```bash
   systemctl status mail-tester
   systemctl status postfix
   ```

### Firewall Configuration

```bash
ufw allow 22    # SSH
ufw allow 25    # SMTP (incoming mail)
ufw allow 80    # HTTP
ufw allow 443   # HTTPS
ufw --force enable
```

## Server Migration

To migrate to a new server (e.g., DigitalOcean):

1. **On the new server:**
   ```bash
   git clone https://github.com/tughn/mail-tester.git /opt/mail-tester
   cd /opt/mail-tester
   ./server-setup/install.sh yourdomain.com
   ```

2. **Update DNS:**
   - Change A record to point to new server IP
   - Wait for propagation (5-30 minutes)

3. **Get SSL certificate:**
   ```bash
   certbot --nginx -d yourdomain.com
   ```

4. **Verify:**
   ```bash
   echo "Test" | mail -s "Test" test-abc123@yourdomain.com
   tail -f /var/log/mail.log
   ```

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| Port 25 blocked | Check cloud provider settings (some block SMTP by default) |
| Email not received | Check `tail -f /var/log/mail.log` for Postfix errors |
| Parser not running | Check `journalctl -u mail-tester -f` |
| DNS not resolving | Wait for propagation, verify with `dig yourdomain.com MX` |

### Useful Commands

```bash
# Check service status
systemctl status mail-tester postfix opendkim opendmarc nginx

# View logs
tail -f /var/log/mail.log                # Postfix
journalctl -u mail-tester -f             # Node.js app
tail -f /var/log/mail-tester/parser.log  # Email parser

# Test email locally
echo "Test body" | mail -s "Test" test-abc123@yourdomain.com

# Check port 25
nc -zv yourdomain.com 25
```

## File Structure

```
mail-tester/
├── public/
│   └── index.html          # Frontend (single HTML file)
├── src/
│   ├── server.js           # Express.js API server
│   ├── email-parser.js     # Postfix pipe script (parses incoming mail)
│   └── dns-checker.js      # MTA-STS and TLS-RPT DNS lookups
├── server-setup/
│   └── install.sh          # Automated server setup script
├── .env.example            # Environment variables template
├── .gitignore
├── package.json
└── README.md
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `3000` | HTTP server port |
| `DOMAIN` | `deliverabilityanalyzer.xyz` | Domain for test email addresses |
| `DATA_DIR` | `/var/lib/mail-tester/emails` | Directory for storing test results |
| `LOG_FILE` | `/var/log/mail-tester/parser.log` | Parser log file location |

## License

MIT
