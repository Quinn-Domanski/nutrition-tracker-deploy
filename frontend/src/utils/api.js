// This helper centralizes all API calls and handles the URL automatically
const API_URL = import.meta.env.VITE_API_URL || '/api';

export async function apiCall(endpoint, options = {}) {
    const url = `${API_URL}${endpoint}`;

    return fetch(url, {
        ...options,
        credentials: 'include', // Always include credentials for cookies
        headers: {
            'Content-Type': 'application/json',
            ...options.headers,
        },
    });
}

// Convenience methods
export const api = {
    get: (endpoint) => apiCall(endpoint, { method: 'GET' }),
    post: (endpoint, body) => apiCall(endpoint, { method: 'POST', body: JSON.stringify(body) }),
    put: (endpoint, body) => apiCall(endpoint, { method: 'PUT', body: JSON.stringify(body) }),
    delete: (endpoint) => apiCall(endpoint, { method: 'DELETE' }),
};