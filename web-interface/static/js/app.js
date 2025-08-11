// System Restore Toolkit Web Interface JavaScript

class ToolkitWebApp {
    constructor() {
        this.init();
    }

    init() {
        this.setupEventListeners();
        this.startStatusUpdates();
    }

    setupEventListeners() {
        // Auto-refresh buttons
        document.querySelectorAll('[data-auto-refresh]').forEach(button => {
            button.addEventListener('click', () => {
                this.refreshPage();
            });
        });

        // Form validation
        document.querySelectorAll('form').forEach(form => {
            form.addEventListener('submit', (e) => {
                this.handleFormSubmit(e, form);
            });
        });
    }

    refreshPage() {
        const button = event.target;
        const originalText = button.innerHTML;
        
        button.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Refreshing...';
        button.disabled = true;
        
        setTimeout(() => {
            location.reload();
        }, 1000);
    }

    handleFormSubmit(event, form) {
        const submitButton = form.querySelector('button[type="submit"]');
        if (submitButton) {
            const originalText = submitButton.innerHTML;
            submitButton.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Processing...';
            submitButton.disabled = true;
            
            // Re-enable after 3 seconds (in case of error)
            setTimeout(() => {
                submitButton.innerHTML = originalText;
                submitButton.disabled = false;
            }, 3000);
        }
    }

    async fetchStatus() {
        try {
            const response = await fetch('/api/status');
            return await response.json();
        } catch (error) {
            console.error('Failed to fetch status:', error);
            return null;
        }
    }

    async checkTaskStatus(taskId) {
        try {
            const response = await fetch(`/api/task/${taskId}`);
            return await response.json();
        } catch (error) {
            console.error('Failed to fetch task status:', error);
            return null;
        }
    }

    startStatusUpdates() {
        // Update status every 30 seconds
        setInterval(() => {
            this.updateSystemStatus();
        }, 30000);
    }

    async updateSystemStatus() {
        const status = await this.fetchStatus();
        if (status) {
            this.updateStatusIndicators(status);
        }
    }

    updateStatusIndicators(status) {
        // Update any status indicators on the page
        const indicators = document.querySelectorAll('[data-status-indicator]');
        indicators.forEach(indicator => {
            const type = indicator.dataset.statusIndicator;
            if (status[type]) {
                indicator.className = status[type].success ? 
                    'fas fa-check-circle status-success' : 
                    'fas fa-exclamation-circle status-danger';
            }
        });
    }

    showNotification(message, type = 'info') {
        const alertDiv = document.createElement('div');
        alertDiv.className = `alert alert-${type} alert-dismissible fade show`;
        alertDiv.innerHTML = `
            ${message}
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        `;
        
        const container = document.querySelector('.container');
        container.insertBefore(alertDiv, container.firstChild);
        
        // Auto-remove after 5 seconds
        setTimeout(() => {
            if (alertDiv.parentNode) {
                alertDiv.remove();
            }
        }, 5000);
    }
}

// Initialize the application when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    window.toolkitApp = new ToolkitWebApp();
});

// Utility functions
function formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

function formatDate(dateString) {
    const date = new Date(dateString);
    return date.toLocaleDateString() + ' ' + date.toLocaleTimeString();
}
