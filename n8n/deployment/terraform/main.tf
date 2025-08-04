# Terraform configuration for n8n × Claude Code Cloud Run deployment

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Variables
variable "project_id" {
  description = "Google Cloud Project ID"
  type        = string
}

variable "region" {
  description = "Google Cloud Region"
  type        = string
  default     = "asia-northeast1"
}

variable "n8n_api_key" {
  description = "n8n API Key"
  type        = string
  sensitive   = true
}

variable "claude_api_key" {
  description = "Claude API Key"
  type        = string
  sensitive   = true
}

# Provider
provider "google" {
  project = var.project_id
  region  = var.region
}

# Enable required APIs
resource "google_project_service" "apis" {
  for_each = toset([
    "cloudbuild.googleapis.com",
    "run.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudscheduler.googleapis.com"
  ])
  
  project = var.project_id
  service = each.value
  
  disable_on_destroy = false
}

# Secret Manager for API keys
resource "google_secret_manager_secret" "n8n_api_key" {
  secret_id = "n8n-api-key"
  
  replication {
    automatic = true
  }
  
  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret_version" "n8n_api_key" {
  secret      = google_secret_manager_secret.n8n_api_key.id
  secret_data = var.n8n_api_key
}

resource "google_secret_manager_secret" "claude_api_key" {
  secret_id = "claude-api-key"
  
  replication {
    automatic = true
  }
  
  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret_version" "claude_api_key" {
  secret      = google_secret_manager_secret.claude_api_key.id
  secret_data = var.claude_api_key
}

# Service account for Cloud Run
resource "google_service_account" "n8n_claude" {
  account_id   = "n8n-claude-automation"
  display_name = "n8n Claude Automation Service Account"
  description  = "Service account for n8n × Claude Code automation"
}

# IAM bindings for service account
resource "google_project_iam_member" "n8n_claude_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.n8n_claude.email}"
}

resource "google_project_iam_member" "n8n_claude_cloud_sql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.n8n_claude.email}"
}

# Cloud Run service
resource "google_cloud_run_service" "n8n_claude" {
  name     = "n8n-claude-automation"
  location = var.region
  
  template {
    metadata {
      annotations = {
        "autoscaling.knative.dev/minScale"      = "0"
        "autoscaling.knative.dev/maxScale"      = "10"
        "run.googleapis.com/cpu-throttling"     = "true"
        "run.googleapis.com/execution-environment" = "gen2"
      }
    }
    
    spec {
      container_concurrency = 100
      timeout_seconds      = 300
      service_account_name = google_service_account.n8n_claude.email
      
      containers {
        image = "gcr.io/${var.project_id}/n8n-claude-automation:latest"
        
        ports {
          name           = "http1"
          container_port = 3000
        }
        
        env {
          name  = "NODE_ENV"
          value = "production"
        }
        
        env {
          name  = "LOG_LEVEL"
          value = "info"
        }
        
        env {
          name  = "N8N_PORT"
          value = "3000"
        }
        
        env {
          name = "N8N_API_KEY"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret.n8n_api_key.secret_id
              key  = "latest"
            }
          }
        }
        
        env {
          name = "CLAUDE_API_KEY"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret.claude_api_key.secret_id
              key  = "latest"
            }
          }
        }
        
        resources {
          limits = {
            cpu    = "1000m"
            memory = "1Gi"
          }
          requests = {
            cpu    = "500m"
            memory = "512Mi"
          }
        }
        
        liveness_probe {
          http_get {
            path = "/health"
            port = 3000
          }
          initial_delay_seconds = 60
          period_seconds       = 30
          timeout_seconds      = 10
          failure_threshold    = 3
        }
        
        readiness_probe {
          http_get {
            path = "/ready"
            port = 3000
          }
          initial_delay_seconds = 30
          period_seconds       = 10
          timeout_seconds      = 5
          failure_threshold    = 3
        }
      }
    }
  }
  
  traffic {
    percent         = 100
    latest_revision = true
  }
  
  depends_on = [google_project_service.apis]
}

# IAM policy for public access
resource "google_cloud_run_service_iam_policy" "noauth" {
  location = google_cloud_run_service.n8n_claude.location
  project  = google_cloud_run_service.n8n_claude.project
  service  = google_cloud_run_service.n8n_claude.name
  
  policy_data = data.google_iam_policy.noauth.policy_data
}

data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

# Cloud Scheduler jobs for automated workflows
resource "google_cloud_scheduler_job" "daily_data_analysis" {
  name             = "daily-data-analysis"
  description      = "Daily data analysis workflow trigger"
  schedule         = "0 9 * * *"
  time_zone        = "Asia/Tokyo"
  attempt_deadline = "320s"
  
  retry_config {
    retry_count = 3
  }
  
  http_target {
    http_method = "POST"
    uri         = "${google_cloud_run_service.n8n_claude.status[0].url}/trigger/data-analysis"
    
    headers = {
      "Content-Type" = "application/json"
    }
    
    body = base64encode(jsonencode({
      workflow_type = "data-analysis"
      data_path     = "/data/daily-metrics.csv"
      notify_channel = "#data-analysis"
    }))
  }
  
  depends_on = [google_project_service.apis]
}

resource "google_cloud_scheduler_job" "weekly_report" {
  name             = "weekly-report-generation"
  description      = "Weekly report generation workflow"
  schedule         = "0 8 * * 1"
  time_zone        = "Asia/Tokyo"
  attempt_deadline = "320s"
  
  retry_config {
    retry_count = 3
  }
  
  http_target {
    http_method = "POST"
    uri         = "${google_cloud_run_service.n8n_claude.status[0].url}/trigger/report-generation"
    
    headers = {
      "Content-Type" = "application/json"
    }
    
    body = base64encode(jsonencode({
      workflow_type = "report-generation"
      report_period = "weekly"
      notify_channel = "#reports"
    }))
  }
  
  depends_on = [google_project_service.apis]
}

# Outputs
output "service_url" {
  description = "Cloud Run service URL"
  value       = google_cloud_run_service.n8n_claude.status[0].url
}

output "service_account_email" {
  description = "Service account email"
  value       = google_service_account.n8n_claude.email
}

output "project_id" {
  description = "Project ID"
  value       = var.project_id
}