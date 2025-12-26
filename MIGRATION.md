# Migration Guide - Moving to This Setup

This guide helps you migrate from an existing Frappe/ERPNext installation to this Docker-based production setup.

## 📋 Prerequisites

Before migrating:

1. ✅ Have a complete backup of your current installation
2. ✅ Know your current Frappe/ERPNext versions
3. ✅ Have access to both old and new servers
4. ✅ Plan for downtime (typically 1-4 hours)
5. ✅ Test the migration process on a staging environment first

## 🔄 Migration Steps

### Step 1: Backup Current Installation

On your **old server**, create a complete backup:

```bash
# If using bench
cd ~/frappe-bench
bench --site your-site.com backup --with-files

# Backup location
ls ~/frappe-bench/sites/your-site.com/private/backups/
```

Download the backup files:
- `*-database.sql.gz` (database)
- `*-files.tar` (public files)
- `*-private-files.tar` (private files)

### Step 2: Set Up New Server

On your **new server**:

```bash
# Clone this repository
cd /home
git clone <your-repo-url> frappe-production-setup
cd frappe-production-setup

# Install prerequisites
sudo ./scripts/install-prerequisites.sh

# Configure environment
cp .env.example .env
nano .env
```

**Important:** Match the version in `.env` with your current installation:
```env
FRAPPE_VERSION=version-15  # Match your current version
ERPNEXT_VERSION=v15.93.0   # Match your current version
```

### Step 3: Deploy New Setup

```bash
# If you have custom apps, configure apps.json
nano apps.json

# Build custom image (if needed)
./scripts/build-image.sh

# Deploy
./scripts/deploy-production.sh
```

Wait for all services to be ready:
```bash
docker compose ps
```

### Step 4: Create New Site

Create a new site with the **same name** as your old site:

```bash
# Create site (don't install ERPNext yet if restoring)
docker compose exec backend \
  bench new-site your-site.com \
  --mariadb-root-password YOUR_DB_PASSWORD \
  --admin-password admin \
  --no-mariadb-socket
```

### Step 5: Transfer Backup Files

Copy your backup files to the new server:

```bash
# On your local machine or old server
scp *-database.sql.gz root@new-server:/home/frappe/frappe-production-setup/backups/
scp *-files.tar root@new-server:/home/frappe/frappe-production-setup/backups/
scp *-private-files.tar root@new-server:/home/frappe/frappe-production-setup/backups/
```

### Step 6: Restore Backup

On the **new server**:

```bash
cd /home/frappe/frappe-production-setup

# Create a restore directory
mkdir -p backups/your-site.com_restore
mv backups/*-database.sql.gz backups/your-site.com_restore/
mv backups/*-files.tar backups/your-site.com_restore/
mv backups/*-private-files.tar backups/your-site.com_restore/

# Use the restore script
./scripts/restore.sh
# Select the backup you just uploaded
```

Or restore manually:

```bash
# Copy backups to container
docker compose cp backups/your-site.com_restore/. \
  backend:/tmp/restore/

# Restore database
docker compose exec backend \
  bench --site your-site.com \
  --force restore \
  /tmp/restore/*-database.sql.gz \
  --mariadb-root-password YOUR_DB_PASSWORD

# Restore files
docker compose exec backend \
  bench --site your-site.com restore \
  --with-public-files /tmp/restore/*-files.tar \
  --with-private-files /tmp/restore/*-private-files.tar

# Migrate
docker compose exec backend bench --site your-site.com migrate

# Clear cache and rebuild
docker compose exec backend bench --site your-site.com clear-cache
docker compose exec backend bench --site your-site.com build
```

### Step 7: Verify Migration

1. **Check site access:**
   ```bash
   curl -I https://your-site.com
   ```

2. **Login and verify:**
   - Access your site in a browser
   - Login with your credentials
   - Verify data is intact
   - Test critical workflows

3. **Check logs:**
   ```bash
   ./scripts/logs.sh backend
   ```

### Step 8: Update DNS

Once verified, update your domain DNS to point to the new server:

1. Update A record to new server IP
2. Wait for DNS propagation (5-60 minutes)
3. Test from different locations

### Step 9: Decommission Old Server

After confirming everything works:

1. **Keep old server for 1-2 weeks** as backup
2. Monitor new server for issues
3. Once stable, decommission old server

## 🔧 Troubleshooting Migration Issues

### Version Mismatch Errors

If you get version mismatch errors:

```bash
# Check current version
docker compose exec backend bench version

# Update to match your backup
# Update ERPNEXT_VERSION in .env, then:
docker compose pull
docker compose up -d
docker compose exec backend bench --site your-site.com migrate
```

### Missing Custom Apps

If you had custom apps:

1. Add them to `apps.json`
2. Rebuild image: `./scripts/build-image.sh`
3. Update .env to use custom image
4. Redeploy: `docker compose up -d`
5. Install apps: `docker compose exec backend bench --site your-site.com install-app custom_app`

### Database Restore Fails

```bash
# Check database connection
docker compose exec backend bench --site your-site.com mariadb

# Check database logs
docker compose logs db

# Verify backup file integrity
gunzip -t your-backup-database.sql.gz
```

### File Permission Issues

```bash
# Fix ownership
docker compose exec backend \
  chown -R frappe:frappe /home/frappe/frappe-bench/sites
```

### Site Not Accessible

1. Check container status: `docker compose ps`
2. Check Nginx logs: `docker compose logs frontend`
3. Verify site in sites list:
   ```bash
   docker compose exec backend ls -la sites/
   ```

## 📊 Migration Checklist

Use this checklist to track your migration:

- [ ] Backup created on old server
- [ ] Backup files downloaded
- [ ] New server provisioned
- [ ] Docker and dependencies installed
- [ ] .env configured with correct versions
- [ ] Services deployed and running
- [ ] New site created
- [ ] Backup files transferred
- [ ] Database restored
- [ ] Files restored
- [ ] Site accessible
- [ ] Data verified
- [ ] Workflows tested
- [ ] DNS updated
- [ ] Old server kept as backup
- [ ] Monitoring set up
- [ ] Backups scheduled

## 🚨 Rollback Plan

If migration fails:

1. **Keep old server running** during migration
2. **Don't update DNS** until fully verified
3. **If issues arise:**
   - Point DNS back to old server
   - Investigate issues on new server
   - Try again when resolved

## 📝 Post-Migration Tasks

After successful migration:

1. **Set up automated backups:**
   ```bash
   # Add to crontab
   0 2 * * * cd /home/frappe/frappe-production-setup && ./scripts/backup.sh
   ```

2. **Configure monitoring:**
   - Set up uptime monitoring
   - Configure disk space alerts
   - Monitor container health

3. **Update documentation:**
   - Document new server details
   - Update team access instructions
   - Record any customizations

4. **Test disaster recovery:**
   - Verify backups work
   - Test restore procedure
   - Document recovery steps

---

## 🆘 Need Help?

If you encounter issues during migration:

1. Check logs: `./scripts/logs.sh`
2. Review [Troubleshooting Guide](README.md#-troubleshooting)
3. Search [Frappe Forum](https://discuss.frappe.io/)
4. Check [GitHub Issues](https://github.com/frappe/frappe_docker/issues)

---

**Remember:** Always test migration on a staging environment first! 🎯
