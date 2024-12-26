# Certbot Home

**Certbot Home** helps you bring Let's Encrypt certificates to your home servers.
The home domain is hosted at Hetzner DNS.
It is not required to create any DNS records there; it will only be used to handle the ACME DNS challenges for Certbot.
Your home dns zone is still managed internal.
This setup can also be used for air-gapped installations where Let's Encrypt cannot check directly.

## Requirements

- Public domain used in your home environment
- Hetzner DNS used for the home domain
- On your machines that use Certbot to request certificates, you need `auth.sh`, `cleanup.sh`, and the modified `cli.ini`
- Additionally, `curl` and `jq` must be installed on your system

## Implementation

1. Create a Hetzner DNS account, create your `home.example.com` domain there, and request a token.

2. Install Certbot, `curl`, and `jq` on your Linux system:

   ```bash
   apt install python3-certbot curl jq
   ```

3. Install the certbot_home scripts:

```bash
cd /tmp 
git clone https://github.com/lanbugs/certbot_home.git
cd certbot_home
mkdir /opt/certbot_home
cp *.sh /opt/certbot_home
chmod +x /opt/certbot_home/*.sh
```

4. Modify `auth.sh` and `cleanup.sh` - Set the token:
Set the created token in both scripts.

5. Modify `/etc/letsencrypt/cli.ini`:

```ini
agree-tos = True
email = mail@example.com
non-interactive = True
manual = True
preferred-challenges = dns
manual-auth-hook = /opt/certbot_home/auth.sh
manual-cleanup-hook = /opt/certbot_home/cleanup.sh
manual-public-ip-logging-ok = True
```

6. Try to acquire a certificate from Let's Encrypt:

```
certbot certonly -d test.home.example.com

Saving debug log to /var/log/letsencrypt/letsencrypt.log
Requesting a certificate for test.home.example.com

Successfully received certificate.
Certificate is saved at: /etc/letsencrypt/live/test.home.example.com/fullchain.pem
Key is saved at:         /etc/letsencrypt/live/test.home.example.com/privkey.pem
This certificate expires on 2025-03-26.
These files will be updated when the certificate renews.
Certbot has set up a scheduled task to automatically renew this certificate in the background.
```


