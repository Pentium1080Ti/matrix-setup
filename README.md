# matrix-setup
A guide to setting up matrix for Ubuntu (18.04 x64)

## Cron
`crontab -e`

`0 */12 * * * certbot renew --renew-hook "systemctl reload nginx" >/dev/null 2>&1`

This script runs every 12 hours to check if the cert needs updating and will renew it when it gets close to expiring, nginx is restarted to apply changes
