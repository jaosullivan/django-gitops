# ================================
# GitOps Repository Bootstrap Script
# Creates full Argo CD GitOps structure
# ================================

Write-Host "Bootstrapping GitOps repository structure..." -ForegroundColor Cyan

# Root folders
$folders = @(
    "clusters/production",
    "clusters/staging",
    "apps/django-app/base",
    "apps/django-app/blue",
    "apps/django-app/green",
    "argo-apps"
)

foreach ($folder in $folders) {
    New-Item -ItemType Directory -Force -Path $folder | Out-Null
}

# ================================
# Base App (shared Helm values)
# ================================
@"
resources: []
"@ | Set-Content "apps/django-app/base/kustomization.yaml"

@"
image:
  repository: ghcr.io/jaosullivan/django-app
  tag: latest
service:
  port: 8000
"@ | Set-Content "apps/django-app/base/values.yaml"

# ================================
# BLUE Overlay
# ================================
@"
resources: []
"@ | Set-Content "apps/django-app/blue/kustomization.yaml"

@"
color: blue
image:
  tag: stable
"@ | Set-Content "apps/django-app/blue/values-blue.yaml"

# ================================
# GREEN Overlay
# ================================
@"
resources: []
"@ | Set-Content "apps/django-app/green/kustomization.yaml"

@"
color: green
image:
  tag: latest
"@ | Set-Content "apps/django-app/green/values-green.yaml"

# ================================
# Production Cluster Kustomization
# ================================
@"
resources:
  - django-app.yaml
  - ingress.yaml
"@ | Set-Content "clusters/production/kustomization.yaml"

# Argo CD Application (Production)
@"
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: django-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/jaosullivan/django-gitops
    targetRevision: main
    path: clusters/production
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
"@ | Set-Content "clusters/production/django-app.yaml"

# Production Ingress (Blue/Green switchable)
@"
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: django-app
spec:
  rules:
    - host: django.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: django-blue-django-app-blue
                port:
                  number: 8000
"@ | Set-Content "clusters/production/ingress.yaml"

# ================================
# Staging Cluster Kustomization
# ================================
@"
resources:
  - django-app.yaml
  - ingress.yaml
"@ | Set-Content "clusters/staging/kustomization.yaml"

# Argo CD Application (Staging)
@"
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: django-app-staging
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/jaosullivan/django-gitops
    targetRevision: main
    path: clusters/staging
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
"@ | Set-Content "clusters/staging/django-app.yaml"

# Staging Ingress
@"
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: django-app-staging
spec:
  rules:
    - host: django-staging.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: django-green-django-app-green
                port:
                  number: 8000
"@ | Set-Content "clusters/staging/ingress.yaml"

Write-Host "GitOps repository structure created successfully!" -ForegroundColor Green