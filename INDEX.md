# 🚀 Frappe/ERPNext Production Docker Setup

> **A complete, reusable, production-ready Docker setup for Frappe/ERPNext that you can deploy anywhere in minutes.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue.svg)](https://www.docker.com/)
[![ERPNext](https://img.shields.io/badge/ERPNext-v15-green.svg)](https://erpnext.com/)

---

## ⚡ Quick Start (3 Commands!)

```bash
# 1. Clone this repo
git clone <your-repo-url> && cd frappe-production-setup

# 2. Run setup wizard (interactive)
./setup-wizard.sh

# 3. Create your site
./scripts/create-site.sh
```

**That's it! Your production Frappe/ERPNext is ready! 🎉**

---

## 🎯 What Makes This Special?

✅ **Official frappe_docker** - Based on Frappe team's official repository  
✅ **Production-ready** - SSL, backups, monitoring included  
✅ **Easy to explain** - Simple structure, clear documentation  
✅ **Fully reusable** - Copy to any server and deploy  
✅ **Automated scripts** - One command for everything  
✅ **Well documented** - Step-by-step guides included  

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| **[QUICKSTART.md](QUICKSTART.md)** | 5-minute quick start guide |
| **[README.md](README.md)** | Complete documentation |
| **[MIGRATION.md](MIGRATION.md)** | Migrate from existing setup |

---

## 🎬 Getting Started

### Option 1: Interactive Setup (Recommended)

```bash
./setup-wizard.sh
```

The wizard will:
- Check prerequisites
- Guide you through configuration
- Build custom image (if needed)
- Deploy services
- Help you create your first site

### Option 2: Manual Setup

See [QUICKSTART.md](QUICKSTART.md) for detailed manual setup instructions.

---

## 📁 Repository Structure

```
frappe-production-setup/
├── README.md                     # Complete documentation
├── QUICKSTART.md                 # Quick start guide
├── MIGRATION.md                  # Migration guide
├── setup-wizard.sh               # Interactive setup wizard
├── .env.example                  # Environment template
├── apps.json                     # Apps to install
├── configs/                      # Configuration templates
│   ├── .env.production          # Production config
│   └── .env.development         # Development config
└── scripts/                      # Automation scripts
    ├── install-prerequisites.sh # Install Docker, etc.
    ├── build-image.sh           # Build custom image
    ├── deploy-production.sh     # Deploy with SSL
    ├── deploy-development.sh    # Deploy without SSL
    ├── create-site.sh           # Create new site
    ├── backup.sh                # Backup all sites
    ├── restore.sh               # Restore from backup
    ├── update.sh                # Update Frappe/ERPNext
    ├── start.sh                 # Start services
    ├── stop.sh                  # Stop services
    └── logs.sh                  # View logs
```

---

## 🔧 Common Operations

### Create a Site
```bash
./scripts/create-site.sh
```

### Backup Everything
```bash
./scripts/backup.sh
```

### Update Frappe/ERPNext
```bash
./scripts/update.sh
```

### View Logs
```bash
./scripts/logs.sh
```

### Start/Stop Services
```bash
./scripts/start.sh
./scripts/stop.sh
```

---

## 🌟 Key Features

### 🔒 Production Ready
- **SSL/TLS** - Automatic Let's Encrypt certificates
- **Security** - Best practices configuration
- **Backups** - Automated backup scripts
- **Monitoring** - Health checks and logging

### 🎨 Customizable
- **Custom apps** - Easy `apps.json` configuration
- **Flexible** - Environment-based settings
- **Extensible** - Add your own scripts

### 📖 Well Documented
- **Step-by-step guides** - For every operation
- **Troubleshooting** - Common issues covered
- **Examples** - Real-world configurations

### 🔄 Easy Maintenance
- **One-command updates** - Simple update process
- **Backup/restore** - Built-in backup management
- **Automated** - Scripts for routine tasks

---

## 💻 System Requirements

### Minimum (Development/Testing)
- **CPU:** 2 cores
- **RAM:** 4GB
- **Disk:** 40GB
- **OS:** Ubuntu 20.04+ or Debian 11+

### Recommended (Production)
- **CPU:** 4+ cores
- **RAM:** 8GB+
- **Disk:** 100GB+ SSD
- **OS:** Ubuntu 22.04 LTS

---

## 🚀 Deployment Scenarios

### Scenario 1: New Production Server
```bash
git clone <repo> && cd frappe-production-setup
./setup-wizard.sh
# Select: Production with SSL
# Follow prompts
```

### Scenario 2: Local Development
```bash
git clone <repo> && cd frappe-production-setup
./setup-wizard.sh
# Select: Development (no SSL)
# Access: http://localhost:8080
```

### Scenario 3: Migrate Existing Setup
See [MIGRATION.md](MIGRATION.md) for detailed migration guide.

---

## 🛠️ Troubleshooting

### Services won't start?
```bash
docker compose ps  # Check status
./scripts/logs.sh  # Check logs
```

### Can't access site?
```bash
# Check containers
docker compose ps

# Check DNS
nslookup your-domain.com

# Check firewall
sudo ufw status
```

### Database issues?
```bash
# Check database logs
./scripts/logs.sh db

# Restart services
./scripts/stop.sh && ./scripts/start.sh
```

**More:** See [README.md](README.md#-troubleshooting) for complete troubleshooting guide.

---

## 📦 What's Included?

- ✅ **Frappe Framework** - Latest version
- ✅ **ERPNext** - Complete ERP system
- ✅ **HRMS** - Human resource management
- ✅ **MariaDB** - Database server
- ✅ **Redis** - Cache and queue
- ✅ **Nginx** - Web server
- ✅ **SSL/TLS** - Let's Encrypt integration

---

## 🔐 Security Best Practices

1. ✅ Use strong passwords for `DB_PASSWORD`
2. ✅ Enable firewall: `ufw allow 80,443/tcp`
3. ✅ Keep system updated: `apt update && apt upgrade`
4. ✅ Regular backups: Schedule with cron
5. ✅ Monitor logs regularly
6. ✅ Use fail2ban for SSH protection

---

## 🤝 Contributing

This is a template repository. Feel free to:
- Fork and customize
- Submit improvements
- Share with others
- Create issues for bugs

---

## 📄 License

MIT License - Use freely for personal and commercial projects.

---

## 🙏 Acknowledgments

- [Frappe Framework](https://frappeframework.com/) - Amazing framework
- [ERPNext](https://erpnext.com/) - Open source ERP
- [frappe_docker](https://github.com/frappe/frappe_docker) - Official Docker setup

---

## 📞 Support

- 📚 [Official Docs](https://github.com/frappe/frappe_docker)
- 💬 [Frappe Forum](https://discuss.frappe.io/)
- 🐛 [GitHub Issues](https://github.com/frappe/frappe_docker/issues)
- 📖 [ERPNext Docs](https://docs.erpnext.com/)

---

## 🎯 Next Steps After Installation

1. **Configure your ERPNext:**
   - Complete the setup wizard
   - Configure your company details
   - Set up users and permissions

2. **Set up backups:**
   ```bash
   # Add to crontab for daily backups
   crontab -e
   # Add: 0 2 * * * cd /home/frappe/frappe-production-setup && ./scripts/backup.sh
   ```

3. **Monitor your system:**
   - Check logs regularly
   - Monitor disk space
   - Set up uptime monitoring

4. **Customize as needed:**
   - Install additional apps
   - Configure custom settings
   - Add your branding

---

<div align="center">

**Made with ❤️ for the Frappe/ERPNext community**

⭐ Star this repo if you find it useful!

</div>
