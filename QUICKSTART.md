# Quick Start Guide - Frappe/ERPNext Production Setup

This guide will help you deploy Frappe/ERPNext in **under 30 minutes**.

## 📌 Prerequisites Checklist

Before you start, make sure you have:

- ✅ Fresh Ubuntu/Debian server (20.04+ recommended)
- ✅ Minimum 4GB RAM (8GB+ for production)
- ✅ 40GB+ disk space
- ✅ Root/sudo access
- ✅ Domain name pointing to your server (for production with SSL)
- ✅ Ports 80 and 443 open in firewall

## 🚀 Installation Steps

### 1. Clone This Repository

```bash
cd /home
git clone <your-repo-url> frappe-production-setup
cd frappe-production-setup
```

### 2. Install Docker & Prerequisites

Run this **once** on a fresh server:

```bash
sudo ./scripts/install-prerequisites.sh
```

This installs:
- Docker & Docker Compose
- Git
- Required system packages

**⚠️ After installation, log out and log back in** (or run `newgrp docker`)

### 3. Configure Environment Variables

```bash
cp .env.example .env
nano .env
```

**Minimum required changes:**

```env
# Set strong database password
DB_PASSWORD=YourVeryStrongPassword123!@#

# For production with SSL:
LETSENCRYPT_EMAIL=your.email@example.com
SITES=`erp.yourdomain.com`

# For development (no SSL):
HTTP_PUBLISH_PORT=8080
```

### 4. Configure Apps (Optional)

If you want custom apps, edit `apps.json`:

```bash
nano apps.json
```

**Example with common apps:**
```json
[
  {
    "url": "https://github.com/frappe/erpnext",
    "branch": "version-15"
  },
  {
    "url": "https://github.com/frappe/hrms",
    "branch": "version-15"
  },
  {
    "url": "https://github.com/frappe/payments",
    "branch": "version-15"
  }
]
```

### 5a. Production Deployment (With SSL)

**Prerequisites:**
- Domain DNS must point to your server
- Ports 80 and 443 must be open

```bash
# If using custom apps, build image first
./scripts/build-image.sh

# Deploy production setup
./scripts/deploy-production.sh
```

### 5b. Development Deployment (No SSL)

For local testing or development:

```bash
# If using custom apps, build image first
./scripts/build-image.sh

# Deploy development setup
./scripts/deploy-development.sh
```

### 6. Wait for Services

Check if all containers are running:

```bash
docker compose ps
```

Wait until all services show as `running` or `healthy`.

### 7. Create Your First Site

```bash
./scripts/create-site.sh
```

You'll be asked:
- **Site name**: Your domain (e.g., `erp.example.com`) or `site1.localhost` for development
- **Admin password**: Set a strong password
- **Apps to install**: ERPNext (recommended), HRMS, etc.

### 8. Access Your Site

**Production (with SSL):**
```
https://erp.yourdomain.com
```

**Development (no SSL):**
```
http://localhost:8080
```

**Login credentials:**
- Username: `Administrator`
- Password: [the password you set in step 7]

---

## 🎯 That's It!

Your Frappe/ERPNext installation is ready! 🎉

---

## 📝 Common Operations

### View Logs
```bash
./scripts/logs.sh
# Or for specific service:
./scripts/logs.sh backend
```

### Stop Services
```bash
./scripts/stop.sh
```

### Start Services
```bash
./scripts/start.sh
```

### Backup Your Sites
```bash
./scripts/backup.sh
```

### Update Frappe/ERPNext
```bash
./scripts/update.sh
```

### Restore from Backup
```bash
./scripts/restore.sh
```

---

## 🐛 Troubleshooting

### Services not starting?

```bash
# Check status
docker compose ps

# Check logs
./scripts/logs.sh

# Restart
./scripts/stop.sh
./scripts/start.sh
```

### Can't access site?

1. **Check containers:**
   ```bash
   docker compose ps
   ```

2. **Check domain DNS:**
   ```bash
   nslookup erp.yourdomain.com
   ```

3. **Check firewall:**
   ```bash
   sudo ufw status
   sudo ufw allow 80,443/tcp
   ```

4. **Check site creation logs:**
   ```bash
   docker compose logs create-site
   ```

### SSL certificate not working?

1. Make sure DNS points to your server
2. Wait a few minutes for Let's Encrypt
3. Check Traefik logs: `docker compose logs frontend`

### Database connection error?

1. Verify `DB_PASSWORD` in `.env`
2. Check database logs: `./scripts/logs.sh db`
3. Restart services: `./scripts/stop.sh && ./scripts/start.sh`

---

## 📚 Next Steps

After successful installation:

1. **Configure ERPNext:**
   - Complete setup wizard
   - Configure your company
   - Set up users

2. **Set up backups:**
   - Schedule automated backups with cron
   - Test restore procedure

3. **Security hardening:**
   - Enable firewall
   - Set up fail2ban
   - Regular updates

4. **Performance tuning:**
   - Monitor resource usage
   - Adjust worker counts if needed
   - Set up log rotation

---

## 🆘 Need Help?

- [Official Frappe Docker Docs](https://github.com/frappe/frappe_docker)
- [Frappe Forum](https://discuss.frappe.io/)
- [ERPNext Documentation](https://docs.erpnext.com/)

---

**Pro Tip:** Save this setup folder! You can reuse it on any server by just copying and running through these steps again. 🚀
