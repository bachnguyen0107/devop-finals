# Security & Deployment Configuration

## Section 5.1: Cloud Server Provisioning & Security

### Server Details
- **Provider**: AWS Learner Lab
- **Instance Type**: t2.micro
- **Operating System**: Ubuntu 22.04 LTS (or 24.04)
- **Region**: [INSERT YOUR REGION - e.g., us-east-1]
- **Allocation**: Elastic IP assigned for stable connectivity

### Security Group Configuration

#### Open Ports

| Port | Protocol | Service | Purpose |
|------|----------|---------|---------|
| 22 | TCP | SSH | Administrative access & deployment |
| 80 | TCP | HTTP | Web application traffic |
| 443 | TCP | HTTPS | Secure web application traffic |

#### Closed/Restricted Ports
- All other ports are closed by default (default AWS behavior)
- Outbound rules: Allow all (required for package installation and updates)

---

## SSH Access Decision & Justification

### Decision
**SSH (port 22) is open to 0.0.0.0/0 (public internet)**

### Rationale
- **Convenience**: Easy access from any location for development and debugging
- **Development Environment**: This is a learner lab for educational purposes, not production
- **No sensitive data**: Learner Lab is a sandbox environment with restricted resources

### Mitigation Strategies Implemented

#### 1. **Key-Based Authentication Only**
- ✅ SSH access restricted to key-based authentication
- ✅ No password-based login enabled
- ✅ Private key (`*.pem`) stored securely locally
- ✅ Public server cannot authenticate without the matching private key

#### 2. **Access Control**
- Only authorized team members have the private key
- Private key permissions: `600` (read/write owner only)
- Never shared via email, Git, or public channels

#### 3. **Monitoring & Logging** (Implemented in later phases)
- SSH access logs reviewed regularly
- Failed login attempts monitored
- Suspicious activity alerts configured (future enhancement)

#### 4. **IP Restriction (Alternative)**
- If needed, can be restricted to specific IP ranges
- Team IP addresses can be documented for future hardening

---

## Risk Assessment

### Risks of Public SSH Access
- **Brute force attacks**: Mitigated by key-only auth (no exploitable passwords)
- **Unauthorized access**: Mitigated by strong key-based cryptography
- **Data exposure**: Low risk - no customer data in Learner Lab environment

### Recommended Future Improvements (Production)
1. Use SSH bastion/jump host for production
2. Restrict SSH to known IP ranges
3. Disable SSH after deployment (use Systems Manager Session Manager)
4. Implement fail2ban for rate limiting
5. Enable CloudTrail for audit logging
6. Use VPC-only access with VPN

---

## Deployment Access

### Connection Method
```bash
ssh -i ~/path/to/your-key.pem ubuntu@<ELASTIC_IP>
```

### SSH Configuration (Optional)
Add to `~/.ssh/config`:
```
Host product-api-server
    HostName <ELASTIC_IP>
    User ubuntu
    IdentityFile ~/path/to/your-key.pem
    StrictHostKeyChecking accept-new
```

Then connect with:
```bash
ssh product-api-server
```

---

## Team Access

| Team Member | Has Key | Access Date |
|------------|---------|-------------|
| [Name] | ✅ | [Date] |
| [Name] | ✅ | [Date] |
| [Name] | ✅ | [Date] |

*Update this table as team members are granted access*

---

## Security Checklist

- ✅ Ubuntu server provisioned
- ✅ Only essential ports open (22, 80, 443)
- ✅ No unnecessary ports exposed
- ✅ SSH restricted to key-based authentication
- ✅ Elastic IP assigned for stable access
- ✅ SSH access verified & working
- ✅ Security decisions documented
- ✅ Mitigation strategies implemented

---

## References

- AWS Security Best Practices: https://aws.amazon.com/architecture/security-identity-compliance/
- Ubuntu SSH Hardening: https://ubuntu.com/security
- AWS Learner Lab Documentation: [Your institution's documentation]
