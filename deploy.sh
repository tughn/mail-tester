#!/bin/bash
# Run on server: bash deploy.sh
cat > /opt/deliverability-checker/public/index.html << 'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Email Deliverability Checker - Test SPF, DKIM & DMARC</title>
  <meta name="description" content="Free email deliverability testing tool. Check your SPF, DKIM, and DMARC authentication records to improve email deliverability and prevent spoofing.">
  <meta name="keywords" content="email deliverability, SPF checker, DKIM validator, DMARC test, email authentication, email security, spam prevention">
  <meta name="author" content="Deliverability Analyzer">
  <meta name="robots" content="index, follow">
  <link rel="canonical" href="https://deliverabilityanalyzer.xyz">

  <!-- Open Graph / Facebook -->
  <meta property="og:type" content="website">
  <meta property="og:url" content="https://deliverabilityanalyzer.xyz">
  <meta property="og:title" content="Email Deliverability Checker - Test SPF, DKIM & DMARC">
  <meta property="og:description" content="Free email deliverability testing tool. Check your SPF, DKIM, and DMARC authentication to improve deliverability.">
  <meta property="og:image" content="https://deliverabilityanalyzer.xyz/og-image.png">

  <!-- Twitter -->
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:url" content="https://deliverabilityanalyzer.xyz">
  <meta name="twitter:title" content="Email Deliverability Checker - Test SPF, DKIM & DMARC">
  <meta name="twitter:description" content="Free email deliverability testing tool. Check your SPF, DKIM, and DMARC authentication.">

  <!-- Favicon -->
  <link rel="icon" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='%236366f1' stroke-width='2'><path d='M22 6c0-1.1-.9-2-2-2H4c-1.1 0-2 .9-2 2'/><path d='M22 6l-10 7L2 6'/><path d='M22 6v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6'/></svg>">
  <link rel="apple-touch-icon" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='%236366f1'><path d='M22 6c0-1.1-.9-2-2-2H4c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V6zm-2 0l-8 5-8-5h16zm0 12H4V8l8 5 8-5v10z'/></svg>">

  <!-- Structured Data -->
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebApplication",
    "name": "Email Deliverability Checker",
    "description": "Free email deliverability testing tool for SPF, DKIM, and DMARC authentication",
    "url": "https://deliverabilityanalyzer.xyz",
    "applicationCategory": "UtilityApplication",
    "operatingSystem": "Web Browser",
    "offers": {
      "@type": "Offer",
      "price": "0",
      "priceCurrency": "USD"
    }
  }
  </script>

  <style>
    :root {
      --bg-primary: #09090b;
      --bg-secondary: #18181b;
      --bg-tertiary: #27272a;
      --border: #3f3f46;
      --text-primary: #fafafa;
      --text-secondary: #a1a1aa;
      --text-muted: #71717a;
      --accent: #6366f1;
      --accent-hover: #4f46e5;
      --success: #22c55e;
      --success-bg: rgba(34, 197, 94, 0.1);
      --error: #ef4444;
      --error-bg: rgba(239, 68, 68, 0.1);
      --warning: #f59e0b;
      --warning-bg: rgba(245, 158, 11, 0.1);
      --neutral: #71717a;
      --neutral-bg: rgba(113, 113, 122, 0.1);
      --radius: 8px;
      --transition: 150ms ease;
    }

    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }

    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', sans-serif;
      background: var(--bg-primary);
      color: var(--text-primary);
      min-height: 100vh;
      line-height: 1.5;
      -webkit-font-smoothing: antialiased;
    }

    .container {
      max-width: 640px;
      margin: 0 auto;
      padding: 48px 20px;
    }

    /* Header */
    .header {
      text-align: center;
      margin-bottom: 40px;
    }

    .logo {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      width: 48px;
      height: 48px;
      background: linear-gradient(135deg, var(--accent) 0%, #8b5cf6 100%);
      border-radius: 12px;
      margin-bottom: 20px;
    }

    .logo svg {
      width: 24px;
      height: 24px;
      stroke: white;
      stroke-width: 2;
      fill: none;
    }

    h1 {
      font-size: 1.5rem;
      font-weight: 600;
      margin-bottom: 8px;
      letter-spacing: -0.025em;
    }

    .subtitle {
      color: var(--text-secondary);
      font-size: 0.938rem;
    }

    /* Card */
    .card {
      background: var(--bg-secondary);
      border: 1px solid var(--border);
      border-radius: var(--radius);
      padding: 24px;
      transition: border-color var(--transition);
    }

    .card:hover {
      border-color: #52525b;
    }

    /* Generate Section */
    .generate-section p {
      color: var(--text-secondary);
      font-size: 0.875rem;
      margin-bottom: 20px;
    }

    .btn {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
      background: var(--accent);
      color: white;
      border: none;
      padding: 12px 20px;
      border-radius: var(--radius);
      font-size: 0.875rem;
      font-weight: 500;
      cursor: pointer;
      width: 100%;
      transition: background var(--transition), transform var(--transition);
    }

    .btn:hover {
      background: var(--accent-hover);
    }

    .btn:active {
      transform: scale(0.98);
    }

    .btn:disabled {
      background: var(--bg-tertiary);
      color: var(--text-muted);
      cursor: not-allowed;
      transform: none;
    }

    .btn svg {
      width: 16px;
      height: 16px;
      stroke: currentColor;
      stroke-width: 2;
      fill: none;
    }

    /* Email Display */
    .email-box {
      background: var(--bg-primary);
      border: 1px solid var(--border);
      border-radius: var(--radius);
      padding: 16px;
      margin: 16px 0;
    }

    .email-label {
      font-size: 0.75rem;
      color: var(--text-muted);
      text-transform: uppercase;
      letter-spacing: 0.05em;
      margin-bottom: 8px;
    }

    .email-value {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 12px;
    }

    .email-value code {
      font-family: 'SF Mono', Monaco, 'Cascadia Code', monospace;
      font-size: 0.875rem;
      color: var(--accent);
      word-break: break-all;
    }

    .copy-btn {
      display: flex;
      align-items: center;
      justify-content: center;
      background: var(--bg-tertiary);
      border: none;
      padding: 8px;
      border-radius: 6px;
      cursor: pointer;
      transition: background var(--transition);
      flex-shrink: 0;
    }

    .copy-btn:hover {
      background: #3f3f46;
    }

    .copy-btn svg {
      width: 16px;
      height: 16px;
      stroke: var(--text-secondary);
      stroke-width: 2;
      fill: none;
    }

    .copy-btn.copied svg {
      stroke: var(--success);
    }

    /* Status */
    .status {
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 10px;
      padding: 16px;
      color: var(--text-secondary);
      font-size: 0.875rem;
    }

    .spinner {
      width: 16px;
      height: 16px;
      border: 2px solid var(--bg-tertiary);
      border-top-color: var(--accent);
      border-radius: 50%;
      animation: spin 0.8s linear infinite;
    }

    @keyframes spin {
      to { transform: rotate(360deg); }
    }

    /* Results */
    .results-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 20px;
    }

    .results-header h2 {
      font-size: 1rem;
      font-weight: 600;
    }

    .results-time {
      font-size: 0.75rem;
      color: var(--text-muted);
    }

    .results-grid {
      display: flex;
      flex-direction: column;
      gap: 12px;
    }

    .result-card {
      display: flex;
      align-items: center;
      gap: 16px;
      padding: 16px;
      background: var(--bg-primary);
      border: 1px solid var(--border);
      border-radius: var(--radius);
      transition: border-color var(--transition), background var(--transition);
    }

    .result-card:hover {
      border-color: #52525b;
    }

    .result-icon {
      display: flex;
      align-items: center;
      justify-content: center;
      width: 40px;
      height: 40px;
      border-radius: 8px;
      flex-shrink: 0;
    }

    .result-icon svg {
      width: 20px;
      height: 20px;
      stroke-width: 2;
      fill: none;
    }

    .result-icon.pass {
      background: var(--success-bg);
    }

    .result-icon.pass svg {
      stroke: var(--success);
    }

    .result-icon.fail, .result-icon.softfail {
      background: var(--error-bg);
    }

    .result-icon.fail svg, .result-icon.softfail svg {
      stroke: var(--error);
    }

    .result-icon.warning {
      background: var(--warning-bg);
    }

    .result-icon.warning svg {
      stroke: var(--warning);
    }

    .result-icon.none, .result-icon.neutral {
      background: var(--neutral-bg);
    }

    .result-icon.none svg, .result-icon.neutral svg {
      stroke: var(--neutral);
    }

    .result-content {
      flex: 1;
      min-width: 0;
    }

    .result-title {
      font-size: 0.875rem;
      font-weight: 500;
      margin-bottom: 2px;
    }

    .result-desc {
      font-size: 0.75rem;
      color: var(--text-muted);
    }

    .result-badge {
      font-family: 'SF Mono', Monaco, monospace;
      font-size: 0.75rem;
      font-weight: 500;
      padding: 4px 10px;
      border-radius: 4px;
      text-transform: uppercase;
      letter-spacing: 0.025em;
      flex-shrink: 0;
    }

    .result-badge.pass {
      background: var(--success-bg);
      color: var(--success);
    }

    .result-badge.fail {
      background: var(--error-bg);
      color: var(--error);
    }

    .result-badge.softfail {
      background: var(--warning-bg);
      color: var(--warning);
    }

    .result-badge.none, .result-badge.neutral {
      background: var(--neutral-bg);
      color: var(--neutral);
    }

    /* Details Section */
    .details-section {
      margin-top: 20px;
      padding-top: 20px;
      border-top: 1px solid var(--border);
    }

    .details-grid {
      display: grid;
      gap: 12px;
    }

    .detail-row {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      gap: 16px;
      font-size: 0.813rem;
    }

    .detail-label {
      color: var(--text-muted);
      flex-shrink: 0;
    }

    .detail-value {
      color: var(--text-primary);
      font-family: 'SF Mono', Monaco, monospace;
      font-size: 0.75rem;
      text-align: right;
      word-break: break-all;
    }

    /* Expandable Raw Headers */
    .expandable {
      margin-top: 20px;
    }

    .expandable-trigger {
      display: flex;
      align-items: center;
      gap: 8px;
      width: 100%;
      padding: 12px;
      background: var(--bg-primary);
      border: 1px solid var(--border);
      border-radius: var(--radius);
      color: var(--text-secondary);
      font-size: 0.813rem;
      cursor: pointer;
      transition: background var(--transition), border-color var(--transition);
    }

    .expandable-trigger:hover {
      background: var(--bg-tertiary);
      border-color: #52525b;
    }

    .expandable-trigger svg {
      width: 16px;
      height: 16px;
      stroke: currentColor;
      stroke-width: 2;
      fill: none;
      transition: transform var(--transition);
    }

    .expandable-trigger.open svg {
      transform: rotate(180deg);
    }

    .expandable-content {
      display: none;
      margin-top: 8px;
      padding: 16px;
      background: var(--bg-primary);
      border: 1px solid var(--border);
      border-radius: var(--radius);
    }

    .expandable-content.open {
      display: block;
    }

    .expandable-content pre {
      font-family: 'SF Mono', Monaco, monospace;
      font-size: 0.688rem;
      color: var(--text-secondary);
      white-space: pre-wrap;
      word-break: break-all;
      line-height: 1.6;
    }

    /* Actions */
    .actions {
      display: flex;
      gap: 12px;
      margin-top: 24px;
    }

    .btn-secondary {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
      background: transparent;
      color: var(--text-secondary);
      border: 1px solid var(--border);
      padding: 10px 16px;
      border-radius: var(--radius);
      font-size: 0.813rem;
      font-weight: 500;
      cursor: pointer;
      flex: 1;
      transition: background var(--transition), border-color var(--transition), color var(--transition);
    }

    .btn-secondary:hover {
      background: var(--bg-tertiary);
      border-color: #52525b;
      color: var(--text-primary);
    }

    .btn-secondary svg {
      width: 16px;
      height: 16px;
      stroke: currentColor;
      stroke-width: 2;
      fill: none;
    }

    /* Modal */
    .modal-overlay {
      position: fixed;
      inset: 0;
      background: rgba(0, 0, 0, 0.8);
      backdrop-filter: blur(4px);
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 20px;
      z-index: 100;
      opacity: 0;
      visibility: hidden;
      transition: opacity 200ms ease, visibility 200ms ease;
    }

    .modal-overlay.open {
      opacity: 1;
      visibility: visible;
    }

    .modal {
      background: var(--bg-secondary);
      border: 1px solid var(--border);
      border-radius: 12px;
      padding: 24px;
      max-width: 400px;
      width: 100%;
      transform: scale(0.95);
      transition: transform 200ms ease;
    }

    .modal-overlay.open .modal {
      transform: scale(1);
    }

    .modal-icon {
      display: flex;
      align-items: center;
      justify-content: center;
      width: 48px;
      height: 48px;
      background: var(--warning-bg);
      border-radius: 12px;
      margin-bottom: 16px;
    }

    .modal-icon svg {
      width: 24px;
      height: 24px;
      stroke: var(--warning);
      stroke-width: 2;
      fill: none;
    }

    .modal h3 {
      font-size: 1.125rem;
      font-weight: 600;
      margin-bottom: 8px;
    }

    .modal p {
      font-size: 0.875rem;
      color: var(--text-secondary);
      margin-bottom: 20px;
      line-height: 1.6;
    }

    .modal-actions {
      display: flex;
      gap: 12px;
    }

    .modal-actions .btn {
      flex: 1;
      padding: 10px 16px;
    }

    .modal-actions .btn-secondary {
      background: var(--bg-tertiary);
      border: none;
    }

    /* Score Card */
    .score-card {
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 20px;
      padding: 24px;
      background: linear-gradient(135deg, var(--bg-tertiary) 0%, var(--bg-secondary) 100%);
      border: 1px solid var(--border);
      border-radius: var(--radius);
      margin-bottom: 20px;
    }

    .score-ring {
      position: relative;
      width: 80px;
      height: 80px;
      flex-shrink: 0;
    }

    .score-ring svg {
      transform: rotate(-90deg);
    }

    .score-ring circle {
      fill: none;
      stroke-width: 6;
    }

    .score-ring .bg {
      stroke: var(--bg-primary);
    }

    .score-ring .progress {
      stroke: var(--accent);
      stroke-linecap: round;
      transition: stroke-dashoffset 1s ease, stroke 0.3s ease;
    }

    .score-ring.excellent .progress { stroke: var(--success); }
    .score-ring.good .progress { stroke: #84cc16; }
    .score-ring.fair .progress { stroke: var(--warning); }
    .score-ring.poor .progress { stroke: var(--error); }

    .score-value {
      position: absolute;
      inset: 0;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 1.5rem;
      font-weight: 700;
      color: var(--text-primary);
    }

    .score-info {
      flex: 1;
    }

    .score-label {
      font-size: 0.75rem;
      color: var(--text-muted);
      text-transform: uppercase;
      letter-spacing: 0.05em;
      margin-bottom: 4px;
    }

    .score-status {
      font-size: 1.125rem;
      font-weight: 600;
      margin-bottom: 4px;
    }

    .score-status.excellent { color: var(--success); }
    .score-status.good { color: #84cc16; }
    .score-status.fair { color: var(--warning); }
    .score-status.poor { color: var(--error); }

    .score-hint {
      font-size: 0.813rem;
      color: var(--text-secondary);
    }

    /* Footer */
    .footer {
      text-align: center;
      padding: 32px 20px;
      color: var(--text-muted);
      font-size: 0.75rem;
    }

    .footer a {
      color: var(--text-secondary);
      text-decoration: none;
      transition: color var(--transition);
    }

    .footer a:hover {
      color: var(--accent);
    }

    /* Success Animation */
    @keyframes pulse {
      0%, 100% { transform: scale(1); }
      50% { transform: scale(1.05); }
    }

    .score-ring.animate {
      animation: pulse 0.5s ease;
    }

    /* Utility */
    .hidden {
      display: none !important;
    }

    /* Responsive */
    @media (max-width: 640px) {
      .container {
        padding: 24px 16px;
      }

      h1 {
        font-size: 1.25rem;
      }

      .subtitle {
        font-size: 0.875rem;
      }

      .logo {
        width: 40px;
        height: 40px;
        border-radius: 10px;
        margin-bottom: 16px;
      }

      .logo svg {
        width: 20px;
        height: 20px;
      }

      .card {
        padding: 20px;
      }

      .email-value code {
        font-size: 0.75rem;
      }

      .result-card {
        padding: 14px;
        gap: 12px;
      }

      .result-icon {
        width: 36px;
        height: 36px;
      }

      .result-icon svg {
        width: 18px;
        height: 18px;
      }

      .result-title {
        font-size: 0.813rem;
      }

      .result-desc {
        font-size: 0.688rem;
      }

      .result-badge {
        font-size: 0.688rem;
        padding: 3px 8px;
      }

      .detail-row {
        flex-direction: column;
        gap: 4px;
      }

      .detail-value {
        text-align: left;
      }

      .modal {
        padding: 20px;
        margin: 16px;
      }

      .modal h3 {
        font-size: 1rem;
      }

      .modal p {
        font-size: 0.813rem;
      }

      .modal-actions {
        flex-direction: column;
      }

      .modal-actions .btn,
      .modal-actions .btn-secondary {
        width: 100%;
      }

      .score-card {
        padding: 20px;
        gap: 16px;
      }

      .score-ring {
        width: 70px;
        height: 70px;
      }

      .score-value {
        font-size: 1.25rem;
      }

      .score-status {
        font-size: 1rem;
      }

      .footer {
        padding: 24px 16px;
      }
    }

    @media (max-width: 380px) {
      .email-value {
        flex-direction: column;
        align-items: flex-start;
        gap: 10px;
      }

      .copy-btn {
        align-self: flex-end;
      }

      .result-card {
        flex-wrap: wrap;
      }

      .result-content {
        flex: 1 1 calc(100% - 52px);
      }

      .result-badge {
        margin-left: 48px;
        margin-top: 8px;
      }
    }
  </style>
</head>
<body>
  <div class="container">
    <header class="header">
      <div class="logo">
        <svg viewBox="0 0 24 24"><path d="M22 6c0-1.1-.9-2-2-2H4c-1.1 0-2 .9-2 2"/><path d="M22 6l-10 7L2 6"/><path d="M22 6v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6"/></svg>
      </div>
      <h1>Email Deliverability Checker</h1>
      <p class="subtitle">Test SPF, DKIM, and DMARC authentication</p>
    </header>

    <!-- Generate Section -->
    <div id="generate-section" class="card generate-section">
      <p>Generate a unique test address to analyze your email authentication headers and verify deliverability.</p>
      <button class="btn" id="generate-btn">
        <svg viewBox="0 0 24 24"><path d="M5 12h14"/><path d="M12 5v14"/></svg>
        Generate Test Address
      </button>
    </div>

    <!-- Waiting Section -->
    <div id="waiting-section" class="card hidden">
      <div class="email-box">
        <div class="email-label">Send a test email to</div>
        <div class="email-value">
          <code id="test-email"></code>
          <button class="copy-btn" id="copy-btn" title="Copy to clipboard">
            <svg viewBox="0 0 24 24"><rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 01-2-2V4a2 2 0 012-2h9a2 2 0 012 2v1"/></svg>
          </button>
        </div>
      </div>
      <div class="status">
        <div class="spinner"></div>
        <span>Waiting for email...</span>
      </div>
    </div>

    <!-- Results Section -->
    <div id="results-section" class="card hidden">
      <!-- Score Card -->
      <div class="score-card" id="score-card">
        <div class="score-ring" id="score-ring">
          <svg viewBox="0 0 80 80" width="80" height="80">
            <circle class="bg" cx="40" cy="40" r="34"/>
            <circle class="progress" id="score-progress" cx="40" cy="40" r="34" stroke-dasharray="213.6" stroke-dashoffset="213.6"/>
          </svg>
          <div class="score-value" id="score-value">0</div>
        </div>
        <div class="score-info">
          <div class="score-label">Deliverability Score</div>
          <div class="score-status" id="score-status">Analyzing...</div>
          <div class="score-hint" id="score-hint">Based on SPF, DKIM, and DMARC results</div>
        </div>
      </div>

      <div class="results-header">
        <h2>Authentication Results</h2>
        <span class="results-time" id="results-time"></span>
      </div>

      <div class="results-grid">
        <div class="result-card" id="spf-card">
          <div class="result-icon" id="spf-icon">
            <svg viewBox="0 0 24 24" id="spf-svg"><path d="M20 6L9 17l-5-5"/></svg>
          </div>
          <div class="result-content">
            <div class="result-title">SPF</div>
            <div class="result-desc" id="spf-desc">Sender Policy Framework</div>
          </div>
          <span class="result-badge" id="spf-badge">-</span>
        </div>

        <div class="result-card" id="dkim-card">
          <div class="result-icon" id="dkim-icon">
            <svg viewBox="0 0 24 24" id="dkim-svg"><path d="M20 6L9 17l-5-5"/></svg>
          </div>
          <div class="result-content">
            <div class="result-title">DKIM</div>
            <div class="result-desc" id="dkim-desc">DomainKeys Identified Mail</div>
          </div>
          <span class="result-badge" id="dkim-badge">-</span>
        </div>

        <div class="result-card" id="dmarc-card">
          <div class="result-icon" id="dmarc-icon">
            <svg viewBox="0 0 24 24" id="dmarc-svg"><path d="M20 6L9 17l-5-5"/></svg>
          </div>
          <div class="result-content">
            <div class="result-title">DMARC</div>
            <div class="result-desc" id="dmarc-desc">Domain-based Message Authentication</div>
          </div>
          <span class="result-badge" id="dmarc-badge">-</span>
        </div>
      </div>

      <div class="details-section">
        <div class="details-grid" id="details-grid"></div>
      </div>

      <div class="expandable">
        <button class="expandable-trigger" id="headers-trigger">
          <svg viewBox="0 0 24 24"><path d="M6 9l6 6 6-6"/></svg>
          <span>Raw Headers</span>
        </button>
        <div class="expandable-content" id="headers-content">
          <pre id="raw-headers"></pre>
        </div>
      </div>

      <div class="actions">
        <button class="btn-secondary" id="new-test-btn">
          <svg viewBox="0 0 24 24"><path d="M3 12a9 9 0 109-9 9.75 9.75 0 00-6.74 2.74L3 8"/><path d="M3 3v5h5"/></svg>
          New Test
        </button>
      </div>
    </div>
  </div>

  <!-- Footer -->
  <footer class="footer">
    <p>&copy; 2026 <a href="https://deliverabilityanalyzer.xyz">Deliverability Analyzer</a>. All rights reserved.</p>
  </footer>

  <!-- Warning Modal -->
  <div class="modal-overlay" id="modal">
    <div class="modal">
      <div class="modal-icon">
        <svg viewBox="0 0 24 24"><path d="M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>
      </div>
      <h3>Authentication Issues Detected</h3>
      <p id="modal-message">Your email failed one or more authentication checks. This can impact deliverability and allow spoofing of your domain.</p>
      <div class="modal-actions">
        <button class="btn-secondary" id="modal-close">Dismiss</button>
        <a href="https://sendmarc.com" target="_blank" rel="noopener" class="btn">Get Help</a>
      </div>
    </div>
  </div>

  <script>
    const $ = id => document.getElementById(id);
    let testId = null;
    let pollTimer = null;
    let audioCtx = null;

    // Sound effect using Web Audio API
    function playSuccessSound() {
      try {
        if (!audioCtx) audioCtx = new (window.AudioContext || window.webkitAudioContext)();
        const osc = audioCtx.createOscillator();
        const gain = audioCtx.createGain();
        osc.connect(gain);
        gain.connect(audioCtx.destination);
        osc.frequency.setValueAtTime(587.33, audioCtx.currentTime); // D5
        osc.frequency.setValueAtTime(880, audioCtx.currentTime + 0.1); // A5
        gain.gain.setValueAtTime(0.3, audioCtx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + 0.3);
        osc.start(audioCtx.currentTime);
        osc.stop(audioCtx.currentTime + 0.3);
      } catch (e) {}
    }

    // Score calculation
    function calculateScore(spf, dkim, dmarc) {
      let score = 0;
      const weights = { spf: 30, dkim: 40, dmarc: 30 };

      [{ name: 'spf', result: spf }, { name: 'dkim', result: dkim }, { name: 'dmarc', result: dmarc }].forEach(item => {
        const r = item.result?.toLowerCase() || 'none';
        if (r === 'pass') score += weights[item.name];
        else if (r === 'softfail' || r === 'neutral') score += weights[item.name] * 0.3;
      });

      return Math.round(score);
    }

    function getScoreStatus(score) {
      if (score >= 90) return { status: 'Excellent', hint: 'Your email authentication is fully configured', class: 'excellent' };
      if (score >= 70) return { status: 'Good', hint: 'Minor improvements recommended', class: 'good' };
      if (score >= 40) return { status: 'Fair', hint: 'Some authentication methods need attention', class: 'fair' };
      return { status: 'Poor', hint: 'Critical authentication issues detected', class: 'poor' };
    }

    function updateScoreDisplay(score) {
      const circumference = 2 * Math.PI * 34; // 213.6
      const offset = circumference - (score / 100) * circumference;
      const status = getScoreStatus(score);

      const ring = $('score-ring');
      const progress = $('score-progress');

      // Reset and animate
      ring.className = 'score-ring';
      progress.style.strokeDashoffset = circumference;

      requestAnimationFrame(() => {
        ring.classList.add(status.class, 'animate');
        $('score-status').className = 'score-status ' + status.class;
        $('score-status').textContent = status.status;
        $('score-hint').textContent = status.hint;

        // Animate score number
        let current = 0;
        const increment = score / 30;
        const timer = setInterval(() => {
          current += increment;
          if (current >= score) {
            current = score;
            clearInterval(timer);
          }
          $('score-value').textContent = Math.round(current);
        }, 20);

        // Animate ring
        setTimeout(() => {
          progress.style.strokeDashoffset = offset;
        }, 50);
      });
    }

    // Icons
    const icons = {
      check: '<path d="M20 6L9 17l-5-5"/>',
      x: '<line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>',
      minus: '<line x1="5" y1="12" x2="19" y2="12"/>',
      alert: '<circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/>'
    };

    // Generate
    $('generate-btn').onclick = async () => {
      const btn = $('generate-btn');
      btn.disabled = true;
      btn.innerHTML = '<div class="spinner"></div> Generating...';

      try {
        const res = await fetch('/api/generate');
        const data = await res.json();
        testId = data.id;
        $('test-email').textContent = data.email;

        $('generate-section').classList.add('hidden');
        $('waiting-section').classList.remove('hidden');
        $('results-section').classList.add('hidden');

        startPolling();
      } catch (e) {
        btn.disabled = false;
        btn.innerHTML = '<svg viewBox="0 0 24 24"><path d="M5 12h14"/><path d="M12 5v14"/></svg> Generate Test Address';
      }
    };

    // Copy
    $('copy-btn').onclick = () => {
      navigator.clipboard.writeText($('test-email').textContent);
      $('copy-btn').classList.add('copied');
      setTimeout(() => $('copy-btn').classList.remove('copied'), 1500);
    };

    // Poll
    function startPolling() {
      if (pollTimer) clearInterval(pollTimer);
      pollTimer = setInterval(checkResult, 2500);
    }

    async function checkResult() {
      if (!testId) return;
      try {
        const res = await fetch(`/api/check/${testId}`);
        const data = await res.json();
        if (data.received) {
          clearInterval(pollTimer);
          showResults(data);
        }
      } catch (e) {}
    }

    // Results
    function showResults(r) {
      $('waiting-section').classList.add('hidden');
      $('results-section').classList.remove('hidden');

      // Play sound
      playSuccessSound();

      let hasFailure = false;

      // Calculate and display score
      const spfResult = r.spf?.result || 'none';
      const dkimResult = r.dkim?.result || 'none';
      const dmarcResult = r.dmarc?.result || 'none';
      const score = calculateScore(spfResult, dkimResult, dmarcResult);
      updateScoreDisplay(score);

      // Update each result
      ['spf', 'dkim', 'dmarc'].forEach(type => {
        const result = r[type]?.result || 'none';
        const isPass = result === 'pass';
        const isFail = result === 'fail' || result === 'softfail';
        const isNone = result === 'none' || result === 'neutral';

        if (isFail) hasFailure = true;

        // Icon
        const iconEl = $(type + '-icon');
        const svgEl = $(type + '-svg');
        iconEl.className = 'result-icon ' + (isPass ? 'pass' : isFail ? 'fail' : 'none');
        svgEl.innerHTML = isPass ? icons.check : isFail ? icons.x : icons.minus;

        // Badge
        const badge = $(type + '-badge');
        badge.textContent = result.toUpperCase();
        badge.className = 'result-badge ' + result;

        // Description
        const desc = $(type + '-desc');
        desc.textContent = type === 'spf' ? 'Sender Policy Framework' :
           type === 'dkim' ? 'DomainKeys Identified Mail' :
           'Domain-based Message Authentication';
      });

      // Details
      const detailsHtml = [
        { label: 'From', value: r.from },
        { label: 'Return-Path', value: r.headers?.['return-path']?.text },
        { label: 'Subject', value: r.subject },
        { label: 'Received', value: r.receivedAt ? new Date(r.receivedAt).toLocaleString() : null }
      ].filter(d => d.value).map(d =>
        `<div class="detail-row"><span class="detail-label">${d.label}</span><span class="detail-value">${escapeHtml(d.value)}</span></div>`
      ).join('');
      $('details-grid').innerHTML = detailsHtml;

      // Time
      $('results-time').textContent = r.receivedAt ? new Date(r.receivedAt).toLocaleTimeString() : '';

      // Raw headers
      $('raw-headers').textContent = r.rawHeaders || 'No authentication headers found';

      // Show warning modal if failures
      if (hasFailure) {
        setTimeout(() => $('modal').classList.add('open'), 500);
      }
    }

    // Helpers
    function escapeHtml(t) {
      const d = document.createElement('div');
      d.textContent = t;
      return d.innerHTML;
    }

    // Expandable
    $('headers-trigger').onclick = () => {
      $('headers-trigger').classList.toggle('open');
      $('headers-content').classList.toggle('open');
    };

    // New test
    $('new-test-btn').onclick = () => {
      testId = null;
      if (pollTimer) clearInterval(pollTimer);
      $('generate-section').classList.remove('hidden');
      $('waiting-section').classList.add('hidden');
      $('results-section').classList.add('hidden');
      const btn = $('generate-btn');
      btn.disabled = false;
      btn.innerHTML = '<svg viewBox="0 0 24 24"><path d="M5 12h14"/><path d="M12 5v14"/></svg> Generate Test Address';
    };

    // Modal
    $('modal-close').onclick = () => $('modal').classList.remove('open');
    $('modal').onclick = e => { if (e.target === $('modal')) $('modal').classList.remove('open'); };

    // Auto-generate on page load
    document.addEventListener('DOMContentLoaded', () => {
      $('generate-btn').click();
    });
  </script>
</body>
</html>
HTMLEOF

systemctl restart deliverability-checker
echo "Deployed successfully!"
