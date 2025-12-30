// API Configuration
const API_BASE_URL = 'http://127.0.0.1:8000/api';

// Token Management
const TokenManager = {
    getAccessToken() {
        return localStorage.getItem('access_token');
    },
    
    getRefreshToken() {
        return localStorage.getItem('refresh_token');
    },
    
    setTokens(access, refresh) {
        localStorage.setItem('access_token', access);
        localStorage.setItem('refresh_token', refresh);
    },
    
    clearTokens() {
        localStorage.removeItem('access_token');
        localStorage.removeItem('refresh_token');
        localStorage.removeItem('user');
    },
    
    getUser() {
        const user = localStorage.getItem('user');
        return user ? JSON.parse(user) : null;
    },
    
    setUser(user) {
        localStorage.setItem('user', JSON.stringify(user));
    }
};

// API Request Helper
async function apiRequest(endpoint, options = {}) {
    const url = `${API_BASE_URL}${endpoint}`;
    const token = TokenManager.getAccessToken();
    
    const headers = {
        'Content-Type': 'application/json',
        ...options.headers
    };
    
    if (token) {
        headers['Authorization'] = `Bearer ${token}`;
    }
    
    try {
        const response = await fetch(url, {
            ...options,
            headers
        });
        
        // Handle token expiration
        if (response.status === 401) {
            const refreshed = await refreshToken();
            if (refreshed) {
                // Retry the request with new token
                headers['Authorization'] = `Bearer ${TokenManager.getAccessToken()}`;
                const retryResponse = await fetch(url, { ...options, headers });
                return handleResponse(retryResponse);
            } else {
                // Redirect to login
                TokenManager.clearTokens();
                window.location.reload();
                return null;
            }
        }
        
        return handleResponse(response);
    } catch (error) {
        console.error('API Request Error:', error);
        throw error;
    }
}

async function handleResponse(response) {
    const data = await response.json().catch(() => ({}));
    
    if (!response.ok) {
        throw new Error(data.error || data.detail || 'Request failed');
    }
    
    return data;
}

async function refreshToken() {
    const refresh = TokenManager.getRefreshToken();
    if (!refresh) return false;
    
    try {
        const response = await fetch(`${API_BASE_URL}/auth/token/refresh/`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ refresh })
        });
        
        if (response.ok) {
            const data = await response.json();
            TokenManager.setTokens(data.access, TokenManager.getRefreshToken());
            return true;
        }
    } catch (error) {
        console.error('Token refresh failed:', error);
    }
    
    return false;
}

// Auth API
const AuthAPI = {
    async login(username, password) {
        try {
            const response = await fetch(`${API_BASE_URL}/auth/login/`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ username, password })
            });
            
            const data = await response.json();
            
            if (!response.ok) {
                throw new Error(data.error || data.detail || 'Login failed');
            }
            
            // Check if user is admin
            if (data.user.role !== 'admin') {
                throw new Error('Access denied. Admin only.');
            }
            
            TokenManager.setTokens(data.tokens.access, data.tokens.refresh);
            TokenManager.setUser(data.user);
            
            return data;
        } catch (error) {
            console.error('Login error:', error);
            throw error;
        }
    },
    
    async logout() {
        try {
            await apiRequest('/auth/logout/', {
                method: 'POST',
                body: JSON.stringify({ refresh: TokenManager.getRefreshToken() })
            });
        } catch (error) {
            console.error('Logout error:', error);
        }
        TokenManager.clearTokens();
    },
    
    async getProfile() {
        return apiRequest('/auth/profile/');
    }
};

// Dashboard API
const DashboardAPI = {
    async getStats() {
        return apiRequest('/reports/admin/dashboard/');
    },
    
    async getAnalytics() {
        return apiRequest('/reports/admin/analytics/');
    }
};

// Reports API
const ReportsAPI = {
    async getAll(params = {}) {
        const queryString = new URLSearchParams(params).toString();
        const url = `/reports/admin/reports/${queryString ? '?' + queryString : ''}`;
        return apiRequest(url);
    },
    
    async getById(id) {
        return apiRequest(`/reports/admin/reports/${id}/`);
    },
    
    async assignCollector(reportId, collectorId) {
        return apiRequest(`/reports/admin/reports/${reportId}/assign/`, {
            method: 'POST',
            body: JSON.stringify({ collector_id: collectorId })
        });
    },
    
    async rejectReport(reportId, note) {
        return apiRequest(`/reports/admin/reports/${reportId}/reject/`, {
            method: 'POST',
            body: JSON.stringify({ note })
        });
    },
    
    async getMapData() {
        return apiRequest('/reports/admin/map/');
    }
};

// Collectors API
const CollectorsAPI = {
    async getAll(params = {}) {
        const queryString = new URLSearchParams(params).toString();
        const url = `/auth/collectors/${queryString ? '?' + queryString : ''}`;
        return apiRequest(url);
    },
    
    async getById(id) {
        return apiRequest(`/auth/collectors/${id}/`);
    },
    
    async toggleStatus(id) {
        return apiRequest(`/auth/collectors/${id}/toggle-status/`, {
            method: 'POST'
        });
    }
};

// Export for use in app.js
window.TokenManager = TokenManager;
window.AuthAPI = AuthAPI;
window.DashboardAPI = DashboardAPI;
window.ReportsAPI = ReportsAPI;
window.CollectorsAPI = CollectorsAPI;
