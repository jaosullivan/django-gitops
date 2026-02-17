Write-Host "=== Installing Argo CD ===" -ForegroundColor Cyan

# 1. Create namespace
kubectl create namespace argocd -o yaml --dry-run=client | kubectl apply -f -

# 2. Install Argo CD components
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

Write-Host "Waiting for Argo CD pods to become ready..." -ForegroundColor Yellow

# 3. Wait for all pods to be ready
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=180s

Write-Host "Argo CD installed successfully." -ForegroundColor Green

# 4. Retrieve admin password
Write-Host "Retrieving Argo CD admin password..." -ForegroundColor Cyan

$secret = kubectl -n argocd get secret argocd-initial-admin-secret `
  -o jsonpath="{.data.password}"

$ARGOCD_PASSWORD = [System.Text.Encoding]::UTF8.GetString(
    [System.Convert]::FromBase64String($secret)
)

Write-Host "Argo CD admin password: $ARGOCD_PASSWORD" -ForegroundColor Green

# 5. Create Argo CD Application manifest dynamically
Write-Host "Creating Argo CD Application manifest..." -ForegroundColor Cyan

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
"@ | Set-Content "django-app.yaml"

# 6. Apply the Application to Argo CD
kubectl apply -f django-app.yaml

Write-Host "Argo CD Application created and synced." -ForegroundColor Green

# 7. Port-forward Argo CD UI
Write-Host "Starting Argo CD UI on https://localhost:8080 ..." -ForegroundColor Cyan
Write-Host "Use username: admin" -ForegroundColor Yellow
Write-Host "Use password: $ARGOCD_PASSWORD" -ForegroundColor Yellow

kubectl port-forward svc/argocd-server -n argocd 8080:443