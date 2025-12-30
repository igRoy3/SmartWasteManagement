// DOM Elements
const loginPage = document.getElementById('login-page');
const dashboard = document.getElementById('dashboard');
const loginForm = document.getElementById('login-form');
const loginError = document.getElementById('login-error');
const logoutBtn = document.getElementById('logout-btn');
const sidebarToggle = document.getElementById('sidebar-toggle');
const sidebar = document.querySelector('.sidebar');
const mainContent = document.querySelector('.main-content');
const pageTitle = document.getElementById('page-title');
const userName = document.getElementById('user-name');

// State
let currentPage = 'overview';
let reportsData = [];
let collectorsData = [];
let map = null;
let markers = [];

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    console.log('Admin Dashboard: Initializing...');
    checkAuth();
    setupEventListeners();
    console.log('Admin Dashboard: Initialized successfully');
});

// Check Authentication
function checkAuth() {
    const token = TokenManager.getAccessToken();
    const user = TokenManager.getUser();
    
    if (token && user && user.role === 'admin') {
        showDashboard();
        userName.textContent = user.first_name || user.username;
        loadDashboardData();
    } else {
        showLogin();
    }
}

// Show/Hide Pages
function showLogin() {
    loginPage.style.display = 'flex';
    dashboard.style.display = 'none';
}

function showDashboard() {
    loginPage.style.display = 'none';
    dashboard.style.display = 'flex';
}

// Setup Event Listeners
function setupEventListeners() {
    // Login Form
    const loginFormElement = document.getElementById('login-form');
    if (loginFormElement) {
        loginFormElement.addEventListener('submit', handleLogin);
        console.log('Login form listener attached');
    } else {
        console.error('Login form not found!');
    }
    
    // Logout
    if (logoutBtn) {
        logoutBtn.addEventListener('click', handleLogout);
    }
    
    // Sidebar Toggle
    sidebarToggle.addEventListener('click', () => {
        sidebar.classList.toggle('open');
    });
    
    // Navigation
    document.querySelectorAll('.nav-item').forEach(item => {
        item.addEventListener('click', (e) => {
            e.preventDefault();
            const page = item.dataset.page;
            navigateTo(page);
        });
    });
    
    // View All links
    document.querySelectorAll('.view-all').forEach(link => {
        link.addEventListener('click', (e) => {
            e.preventDefault();
            const page = link.dataset.page;
            navigateTo(page);
        });
    });
    
    // Filters
    document.getElementById('filter-status')?.addEventListener('change', loadReports);
    document.getElementById('filter-waste-type')?.addEventListener('change', loadReports);
    document.getElementById('filter-search')?.addEventListener('input', debounce(loadReports, 500));
    document.getElementById('collector-search')?.addEventListener('input', debounce(loadCollectors, 500));
    
    // Modal Close
    document.querySelectorAll('.modal-close').forEach(btn => {
        btn.addEventListener('click', closeAllModals);
    });
    
    // Assign Form
    document.getElementById('assign-form')?.addEventListener('submit', handleAssignCollector);
    
    // Click outside modal to close
    document.querySelectorAll('.modal').forEach(modal => {
        modal.addEventListener('click', (e) => {
            if (e.target === modal) closeAllModals();
        });
    });
}

// Handle Login
async function handleLogin(e) {
    console.log('handleLogin called');
    e.preventDefault();
    e.stopPropagation();
    
    const username = document.getElementById('username').value.trim();
    const password = document.getElementById('password').value;
    
    console.log('Attempting login for username:', username);
    
    if (!username || !password) {
        loginError.textContent = 'Please enter username and password';
        loginError.style.display = 'block';
        console.error('Missing username or password');
        return false;
    }
    
    try {
        loginError.textContent = '';
        loginError.style.display = 'none';
        console.log('Calling AuthAPI.login...');
        const data = await AuthAPI.login(username, password);
        console.log('Login successful:', data);
        userName.textContent = data.user.first_name || data.user.username;
        showDashboard();
        loadDashboardData();
    } catch (error) {
        console.error('Login failed:', error);
        loginError.textContent = error.message || 'Login failed. Please check console for details.';
        loginError.style.display = 'block';
    }
    
    return false;
}

// Handle Logout
async function handleLogout() {
    await AuthAPI.logout();
    showLogin();
    loginForm.reset();
}

// Navigation
function navigateTo(page) {
    currentPage = page;
    
    // Update active nav item
    document.querySelectorAll('.nav-item').forEach(item => {
        item.classList.remove('active');
        if (item.dataset.page === page) {
            item.classList.add('active');
        }
    });
    
    // Show active page
    document.querySelectorAll('.page').forEach(p => {
        p.classList.remove('active');
    });
    document.getElementById(`${page}-page`)?.classList.add('active');
    
    // Update title
    const titles = {
        overview: 'Dashboard Overview',
        reports: 'Reports Management',
        collectors: 'Collector Management',
        map: 'Map View',
        analytics: 'Analytics'
    };
    pageTitle.textContent = titles[page] || 'Dashboard';
    
    // Load page data
    loadPageData(page);
    
    // Close sidebar on mobile
    sidebar.classList.remove('open');
}

// Load Page Data
function loadPageData(page) {
    switch (page) {
        case 'overview':
            loadDashboardData();
            break;
        case 'reports':
            loadReports();
            break;
        case 'collectors':
            loadCollectors();
            break;
        case 'map':
            loadMap();
            break;
        case 'analytics':
            loadAnalytics();
            break;
    }
}

// Load Dashboard Data
async function loadDashboardData() {
    try {
        const stats = await DashboardAPI.getStats();
        
        // Update stats
        document.getElementById('stat-total').textContent = stats.reports.total;
        document.getElementById('stat-pending').textContent = stats.reports.pending;
        document.getElementById('stat-inprogress').textContent = 
            stats.reports.assigned + stats.reports.in_progress;
        document.getElementById('stat-completed').textContent = stats.reports.completed;
        document.getElementById('stat-collectors').textContent = stats.users.active_collectors;
        document.getElementById('stat-citizens').textContent = stats.users.citizens;
        
        // Load recent reports
        loadRecentReports();
    } catch (error) {
        console.error('Failed to load dashboard:', error);
    }
}

// Load Recent Reports
async function loadRecentReports() {
    const tbody = document.getElementById('recent-reports');
    
    try {
        const data = await ReportsAPI.getAll({ page: 1 });
        const reports = data.results || data;
        
        if (reports.length === 0) {
            tbody.innerHTML = '<tr><td colspan="6" class="loading">No reports found</td></tr>';
            return;
        }
        
        tbody.innerHTML = reports.slice(0, 5).map(report => `
            <tr>
                <td>#${report.id}</td>
                <td>${escapeHtml(report.title)}</td>
                <td><span class="waste-badge ${report.waste_type}">${report.waste_type}</span></td>
                <td><span class="status-badge ${report.status}">${formatStatus(report.status)}</span></td>
                <td>${formatDate(report.created_at)}</td>
                <td>
                    <button class="btn btn-primary btn-small" onclick="viewReport(${report.id})">
                        <i class="fas fa-eye"></i>
                    </button>
                </td>
            </tr>
        `).join('');
    } catch (error) {
        tbody.innerHTML = '<tr><td colspan="6" class="loading">Failed to load reports</td></tr>';
    }
}

// Load Reports
async function loadReports() {
    const tbody = document.getElementById('reports-table');
    tbody.innerHTML = '<tr><td colspan="8" class="loading">Loading...</td></tr>';
    
    const params = {};
    const status = document.getElementById('filter-status')?.value;
    const wasteType = document.getElementById('filter-waste-type')?.value;
    const search = document.getElementById('filter-search')?.value;
    
    if (status) params.status = status;
    if (wasteType) params.waste_type = wasteType;
    if (search) params.search = search;
    
    try {
        const data = await ReportsAPI.getAll(params);
        reportsData = data.results || data;
        
        if (reportsData.length === 0) {
            tbody.innerHTML = '<tr><td colspan="8" class="loading">No reports found</td></tr>';
            return;
        }
        
        tbody.innerHTML = reportsData.map(report => `
            <tr>
                <td>#${report.id}</td>
                <td>${escapeHtml(report.title)}</td>
                <td><span class="waste-badge ${report.waste_type}">${report.waste_type}</span></td>
                <td><span class="status-badge ${report.status}">${formatStatus(report.status)}</span></td>
                <td>${report.reported_by?.username || 'N/A'}</td>
                <td>${report.assigned_to?.username || '-'}</td>
                <td>${formatDate(report.created_at)}</td>
                <td>
                    <button class="btn btn-primary btn-small" onclick="viewReport(${report.id})" title="View">
                        <i class="fas fa-eye"></i>
                    </button>
                    ${report.status === 'pending' ? `
                        <button class="btn btn-secondary btn-small" onclick="openAssignModal(${report.id})" title="Assign">
                            <i class="fas fa-user-plus"></i>
                        </button>
                        <button class="btn btn-danger btn-small" onclick="rejectReport(${report.id})" title="Reject">
                            <i class="fas fa-times"></i>
                        </button>
                    ` : ''}
                </td>
            </tr>
        `).join('');
        
        // Setup pagination if available
        if (data.count) {
            setupPagination(data.count, data.next, data.previous);
        }
    } catch (error) {
        tbody.innerHTML = '<tr><td colspan="8" class="loading">Failed to load reports</td></tr>';
    }
}

// View Report Detail
async function viewReport(id) {
    const modal = document.getElementById('report-modal');
    const content = document.getElementById('report-detail-content');
    
    content.innerHTML = '<div class="loading">Loading...</div>';
    modal.classList.add('active');
    
    try {
        const report = await ReportsAPI.getById(id);
        
        content.innerHTML = `
            ${report.image ? `<img src="${report.image}" alt="Report Image" class="report-detail-image">` : ''}
            <div class="report-detail-info">
                <div class="detail-item">
                    <label>Title</label>
                    <p>${escapeHtml(report.title)}</p>
                </div>
                <div class="detail-item">
                    <label>Status</label>
                    <p><span class="status-badge ${report.status}">${formatStatus(report.status)}</span></p>
                </div>
                <div class="detail-item">
                    <label>Waste Type</label>
                    <p><span class="waste-badge ${report.waste_type}">${report.waste_type}</span></p>
                </div>
                <div class="detail-item">
                    <label>Reported By</label>
                    <p>${report.reported_by?.username || 'N/A'}</p>
                </div>
                <div class="detail-item">
                    <label>Assigned To</label>
                    <p>${report.assigned_to?.username || 'Not assigned'}</p>
                </div>
                <div class="detail-item">
                    <label>Date Reported</label>
                    <p>${formatDate(report.created_at)}</p>
                </div>
                <div class="detail-item" style="grid-column: span 2;">
                    <label>Address</label>
                    <p>${escapeHtml(report.address)}</p>
                </div>
                <div class="detail-item" style="grid-column: span 2;">
                    <label>Description</label>
                    <p>${escapeHtml(report.description)}</p>
                </div>
            </div>
            ${report.updates && report.updates.length > 0 ? `
                <div class="report-updates">
                    <h3>Status History</h3>
                    ${report.updates.map(update => `
                        <div class="update-item">
                            <div class="update-icon">
                                <i class="fas fa-history"></i>
                            </div>
                            <div class="update-content">
                                <p class="status">${formatStatus(update.status)}</p>
                                ${update.note ? `<p class="note">${escapeHtml(update.note)}</p>` : ''}
                                <p class="meta">By ${update.updated_by?.username} • ${formatDate(update.created_at)}</p>
                            </div>
                        </div>
                    `).join('')}
                </div>
            ` : ''}
        `;
    } catch (error) {
        content.innerHTML = '<div class="loading">Failed to load report details</div>';
    }
}

// Open Assign Modal
async function openAssignModal(reportId) {
    const modal = document.getElementById('assign-modal');
    const select = document.getElementById('collector-select');
    document.getElementById('assign-report-id').value = reportId;
    
    select.innerHTML = '<option value="">Loading collectors...</option>';
    modal.classList.add('active');
    
    try {
        const data = await CollectorsAPI.getAll();
        const collectors = data.results || data;
        
        select.innerHTML = '<option value="">Choose a collector...</option>' +
            collectors.filter(c => c.is_active).map(collector => `
                <option value="${collector.id}">
                    ${collector.first_name} ${collector.last_name} (@${collector.username})
                    - ${collector.pending_tasks || 0} pending tasks
                </option>
            `).join('');
    } catch (error) {
        select.innerHTML = '<option value="">Failed to load collectors</option>';
    }
}

// Handle Assign Collector
async function handleAssignCollector(e) {
    e.preventDefault();
    
    const reportId = document.getElementById('assign-report-id').value;
    const collectorId = document.getElementById('collector-select').value;
    
    if (!collectorId) {
        alert('Please select a collector');
        return;
    }
    
    try {
        await ReportsAPI.assignCollector(reportId, parseInt(collectorId));
        closeAllModals();
        loadReports();
        loadDashboardData();
        alert('Collector assigned successfully!');
    } catch (error) {
        alert('Failed to assign collector: ' + error.message);
    }
}

// Reject Report
async function rejectReport(id) {
    const note = prompt('Enter rejection reason:');
    if (note === null) return;
    
    try {
        await ReportsAPI.rejectReport(id, note);
        loadReports();
        loadDashboardData();
        alert('Report rejected successfully!');
    } catch (error) {
        alert('Failed to reject report: ' + error.message);
    }
}

// Load Collectors
async function loadCollectors() {
    const grid = document.getElementById('collectors-grid');
    grid.innerHTML = '<div class="loading">Loading collectors...</div>';
    
    const search = document.getElementById('collector-search')?.value;
    const params = search ? { search } : {};
    
    try {
        const data = await CollectorsAPI.getAll(params);
        collectorsData = data.results || data;
        
        if (collectorsData.length === 0) {
            grid.innerHTML = '<div class="loading">No collectors found</div>';
            return;
        }
        
        grid.innerHTML = collectorsData.map(collector => `
            <div class="collector-card">
                <div class="collector-header">
                    <div class="collector-avatar">
                        <i class="fas fa-user"></i>
                    </div>
                    <div class="collector-name">
                        <h3>${collector.first_name} ${collector.last_name}</h3>
                        <p>@${collector.username}</p>
                    </div>
                    <span class="collector-status ${collector.is_active ? 'active' : 'inactive'}">
                        ${collector.is_active ? 'Active' : 'Inactive'}
                    </span>
                </div>
                <div class="collector-stats">
                    <div class="collector-stat">
                        <h4>${collector.total_tasks || 0}</h4>
                        <p>Total Tasks</p>
                    </div>
                    <div class="collector-stat">
                        <h4>${collector.completed_tasks || 0}</h4>
                        <p>Completed</p>
                    </div>
                    <div class="collector-stat">
                        <h4>${collector.pending_tasks || 0}</h4>
                        <p>Pending</p>
                    </div>
                </div>
                <div class="collector-actions">
                    <button class="btn ${collector.is_active ? 'btn-danger' : 'btn-primary'} btn-small" 
                            onclick="toggleCollectorStatus(${collector.id})">
                        <i class="fas fa-${collector.is_active ? 'ban' : 'check'}"></i>
                        ${collector.is_active ? 'Disable' : 'Enable'}
                    </button>
                </div>
            </div>
        `).join('');
    } catch (error) {
        grid.innerHTML = '<div class="loading">Failed to load collectors</div>';
    }
}

// Toggle Collector Status
async function toggleCollectorStatus(id) {
    if (!confirm('Are you sure you want to change this collector\'s status?')) return;
    
    try {
        await CollectorsAPI.toggleStatus(id);
        loadCollectors();
        loadDashboardData();
    } catch (error) {
        alert('Failed to update status: ' + error.message);
    }
}

// Load Map
async function loadMap() {
    const mapContainer = document.getElementById('reports-map');
    
    // Initialize map if not exists
    if (!map) {
        map = L.map('reports-map').setView([20.5937, 78.9629], 5); // India center
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '© OpenStreetMap contributors'
        }).addTo(map);
    }
    
    // Clear existing markers
    markers.forEach(m => map.removeLayer(m));
    markers = [];
    
    try {
        const data = await ReportsAPI.getMapData();
        
        if (data.length === 0) {
            return;
        }
        
        const bounds = [];
        
        data.forEach(report => {
            const lat = parseFloat(report.latitude);
            const lng = parseFloat(report.longitude);
            
            if (isNaN(lat) || isNaN(lng)) return;
            
            const color = getStatusColor(report.status);
            const marker = L.circleMarker([lat, lng], {
                radius: 10,
                fillColor: color,
                color: '#fff',
                weight: 2,
                opacity: 1,
                fillOpacity: 0.8
            }).addTo(map);
            
            marker.bindPopup(`
                <strong>${escapeHtml(report.title)}</strong><br>
                Status: ${formatStatus(report.status)}<br>
                Type: ${report.waste_type}<br>
                <a href="#" onclick="viewReport(${report.id}); return false;">View Details</a>
            `);
            
            markers.push(marker);
            bounds.push([lat, lng]);
        });
        
        if (bounds.length > 0) {
            map.fitBounds(bounds, { padding: [50, 50] });
        }
    } catch (error) {
        console.error('Failed to load map data:', error);
    }
    
    // Trigger map resize
    setTimeout(() => {
        map.invalidateSize();
    }, 100);
}

// Chart instances for cleanup
let analyticsCharts = [];

// Load Analytics
async function loadAnalytics() {
    // Destroy existing charts to prevent memory leaks
    analyticsCharts.forEach(chart => chart.destroy());
    analyticsCharts = [];
    
    try {
        const data = await DashboardAPI.getAnalytics();
        
        // Update trend cards
        if (data.trends) {
            document.getElementById('trend-reports-current').textContent = data.trends.reports.current;
            const reportsChange = document.getElementById('trend-reports-change');
            reportsChange.textContent = `${data.trends.reports.percent_change >= 0 ? '+' : ''}${data.trends.reports.percent_change}%`;
            reportsChange.className = `trend-change ${data.trends.reports.percent_change >= 0 ? 'positive' : 'negative'}`;
            
            document.getElementById('trend-completions-current').textContent = data.trends.completions.current;
            const completionsChange = document.getElementById('trend-completions-change');
            completionsChange.textContent = `${data.trends.completions.percent_change >= 0 ? '+' : ''}${data.trends.completions.percent_change}%`;
            completionsChange.className = `trend-change ${data.trends.completions.percent_change >= 0 ? 'positive' : 'negative'}`;
        }
        
        if (data.avg_resolution_hours !== null) {
            document.getElementById('avg-resolution-time').textContent = data.avg_resolution_hours;
        }
        
        // Status Chart
        const statusCtx = document.getElementById('status-chart').getContext('2d');
        analyticsCharts.push(new Chart(statusCtx, {
            type: 'doughnut',
            data: {
                labels: data.by_status.map(s => formatStatus(s.status)),
                datasets: [{
                    data: data.by_status.map(s => s.count),
                    backgroundColor: [
                        '#f39c12', '#3498db', '#9b59b6', '#27ae60', '#e74c3c'
                    ]
                }]
            },
            options: {
                responsive: true,
                plugins: {
                    legend: {
                        position: 'bottom'
                    }
                }
            }
        }));
        
        // Waste Type Chart
        const wasteCtx = document.getElementById('waste-type-chart').getContext('2d');
        analyticsCharts.push(new Chart(wasteCtx, {
            type: 'pie',
            data: {
                labels: data.by_waste_type.map(w => capitalizeFirst(w.waste_type)),
                datasets: [{
                    data: data.by_waste_type.map(w => w.count),
                    backgroundColor: [
                        '#27ae60', '#3498db', '#e74c3c', '#f39c12', '#95a5a6'
                    ]
                }]
            },
            options: {
                responsive: true,
                plugins: {
                    legend: {
                        position: 'bottom'
                    }
                }
            }
        }));
        
        // Timeline Chart
        const timelineCtx = document.getElementById('timeline-chart').getContext('2d');
        analyticsCharts.push(new Chart(timelineCtx, {
            type: 'line',
            data: {
                labels: data.daily_reports.map(d => formatDateShort(d.date)),
                datasets: [{
                    label: 'Reports',
                    data: data.daily_reports.map(d => d.count),
                    borderColor: '#2ecc71',
                    backgroundColor: 'rgba(46, 204, 113, 0.1)',
                    fill: true,
                    tension: 0.4
                }]
            },
            options: {
                responsive: true,
                scales: {
                    y: {
                        beginAtZero: true
                    }
                }
            }
        }));
        
        // Hourly Distribution Chart
        const hourlyCtx = document.getElementById('hourly-chart').getContext('2d');
        const hours = Array.from({length: 24}, (_, i) => i);
        const hourlyData = hours.map(h => {
            const found = data.hourly_distribution.find(d => d.hour === h);
            return found ? found.count : 0;
        });
        analyticsCharts.push(new Chart(hourlyCtx, {
            type: 'bar',
            data: {
                labels: hours.map(h => `${h}:00`),
                datasets: [{
                    label: 'Reports',
                    data: hourlyData,
                    backgroundColor: 'rgba(52, 152, 219, 0.7)',
                    borderColor: '#3498db',
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                scales: {
                    y: {
                        beginAtZero: true
                    }
                },
                plugins: {
                    legend: {
                        display: false
                    }
                }
            }
        }));
        
        // Weekly Distribution Chart
        const weeklyCtx = document.getElementById('weekly-chart').getContext('2d');
        const dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
        const weeklyData = [1, 2, 3, 4, 5, 6, 7].map(d => {
            const found = data.weekly_distribution.find(w => w.weekday === d);
            return found ? found.count : 0;
        });
        analyticsCharts.push(new Chart(weeklyCtx, {
            type: 'bar',
            data: {
                labels: dayNames,
                datasets: [{
                    label: 'Reports',
                    data: weeklyData,
                    backgroundColor: 'rgba(155, 89, 182, 0.7)',
                    borderColor: '#9b59b6',
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                scales: {
                    y: {
                        beginAtZero: true
                    }
                },
                plugins: {
                    legend: {
                        display: false
                    }
                }
            }
        }));
        
        // Completion Rate Trend Chart
        const completionTrendCtx = document.getElementById('completion-trend-chart').getContext('2d');
        analyticsCharts.push(new Chart(completionTrendCtx, {
            type: 'line',
            data: {
                labels: data.completion_trend.map(d => formatDateShort(d.date)),
                datasets: [{
                    label: 'Completion Rate (%)',
                    data: data.completion_trend.map(d => d.rate),
                    borderColor: '#27ae60',
                    backgroundColor: 'rgba(39, 174, 96, 0.1)',
                    fill: true,
                    tension: 0.4
                }]
            },
            options: {
                responsive: true,
                scales: {
                    y: {
                        beginAtZero: true,
                        max: 100,
                        ticks: {
                            callback: value => value + '%'
                        }
                    }
                }
            }
        }));
        
        // Collector Performance Chart
        if (data.collector_performance && data.collector_performance.length > 0) {
            const collectorCtx = document.getElementById('collector-performance-chart').getContext('2d');
            analyticsCharts.push(new Chart(collectorCtx, {
                type: 'bar',
                data: {
                    labels: data.collector_performance.map(c => `${c.first_name || ''} ${c.last_name || ''}`.trim() || c.username),
                    datasets: [
                        {
                            label: 'Completed',
                            data: data.collector_performance.map(c => c.completed_tasks),
                            backgroundColor: 'rgba(39, 174, 96, 0.8)'
                        },
                        {
                            label: 'Pending',
                            data: data.collector_performance.map(c => c.pending_tasks),
                            backgroundColor: 'rgba(243, 156, 18, 0.8)'
                        }
                    ]
                },
                options: {
                    responsive: true,
                    indexAxis: 'y',
                    scales: {
                        x: {
                            stacked: true,
                            beginAtZero: true
                        },
                        y: {
                            stacked: true
                        }
                    }
                }
            }));
        }
        
        // Top Collectors
        const topCollectorsList = document.getElementById('top-collectors');
        topCollectorsList.innerHTML = data.top_collectors.map((collector, index) => `
            <div class="top-collector-item">
                <span class="rank">${index + 1}</span>
                <span class="name">${((collector.first_name || '') + ' ' + (collector.last_name || '')).trim() || collector.username}</span>
                <span class="completed">${collector.completed} completed</span>
            </div>
        `).join('') || '<p class="loading">No data available</p>';
        
    } catch (error) {
        console.error('Failed to load analytics:', error);
    }
}

function capitalizeFirst(str) {
    if (!str) return '';
    return str.charAt(0).toUpperCase() + str.slice(1);
}

// Utility Functions
function closeAllModals() {
    document.querySelectorAll('.modal').forEach(modal => {
        modal.classList.remove('active');
    });
}

function formatStatus(status) {
    const statusMap = {
        'pending': 'Pending',
        'assigned': 'Assigned',
        'in_progress': 'In Progress',
        'completed': 'Completed',
        'rejected': 'Rejected'
    };
    return statusMap[status] || status;
}

function formatDate(dateString) {
    if (!dateString) return 'N/A';
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    });
}

function formatDateShort(dateString) {
    if (!dateString) return '';
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', {
        month: 'short',
        day: 'numeric'
    });
}

function getStatusColor(status) {
    const colors = {
        'pending': '#f39c12',
        'assigned': '#3498db',
        'in_progress': '#9b59b6',
        'completed': '#27ae60',
        'rejected': '#e74c3c'
    };
    return colors[status] || '#95a5a6';
}

function escapeHtml(text) {
    if (!text) return '';
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

function setupPagination(total, next, prev) {
    // Simple pagination - can be enhanced
    const pagination = document.getElementById('pagination');
    if (!pagination) return;
    
    const pageSize = 20;
    const totalPages = Math.ceil(total / pageSize);
    
    if (totalPages <= 1) {
        pagination.innerHTML = '';
        return;
    }
    
    // For now, just show prev/next
    pagination.innerHTML = `
        <button ${!prev ? 'disabled' : ''} onclick="loadReportsPage('${prev}')">
            <i class="fas fa-chevron-left"></i> Previous
        </button>
        <span style="padding: 0 10px;">Page 1 of ${totalPages}</span>
        <button ${!next ? 'disabled' : ''} onclick="loadReportsPage('${next}')">
            Next <i class="fas fa-chevron-right"></i>
        </button>
    `;
}

// Make functions globally accessible
window.viewReport = viewReport;
window.openAssignModal = openAssignModal;
window.rejectReport = rejectReport;
window.toggleCollectorStatus = toggleCollectorStatus;
