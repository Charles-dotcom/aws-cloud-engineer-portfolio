# Setting up OIDC between GitHub Actions and AWS (Recommended)

Using OIDC eliminates the need to store long-lived AWS access keys as GitHub secrets. This is a **security best practice** in 2025+.

## Step-by-step

### 1. Create an IAM Identity Provider in AWS

Go to IAM → Identity providers → Add provider

- **Provider type**: OpenID Connect
- **Provider URL**: `https://token.actions.githubusercontent.com`
- **Audience**: `sts.amazonaws.com`

### 2. Create an IAM Role for GitHub Actions

1. IAM → Roles → Create role
2. **Trusted entity type**: Web identity
3. Select the OIDC provider you just created
4. **Audience**: `sts.amazonaws.com`
5. Add condition (recommended for security):

```json
{
  "StringEquals": {
    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
  },
  "StringLike": {
    "token.actions.githubusercontent.com:sub": "repo:yourusername/cloud-engineer-portfolio:*"
  }
}
```

6. Attach permissions policies (least privilege):
   - For the static website example: `AmazonS3FullAccess` + `CloudFrontFullAccess` (or tighter custom policy)
   - For real projects: Create specific policies per environment/repo

7. Name the role: `github-actions-oidc-role`

### 3. Update the Workflows

In `.github/workflows/*.yml`, replace:

```yaml
role-to-assume: arn:aws:iam::YOUR_ACCOUNT_ID:role/github-actions-oidc-role
```

Replace `YOUR_ACCOUNT_ID` with your actual AWS account ID.

### 4. (Optional but recommended) Use different roles per environment

- `github-actions-oidc-role-dev`
- `github-actions-oidc-role-prod`

Then use GitHub environments + required reviewers for production applies.

## Why this matters

- No AWS keys in GitHub
- Short-lived credentials (15 minutes default)
- auditable via CloudTrail
- Follows zero-trust principles

This pattern is used in all mature cloud teams.
