#!/usr/bin/env node
const dns = require('dns').promises;
const https = require('https');

/**
 * Extract sender domain from email From header
 * @param {string} fromHeader - e.g., "John Doe <john@example.com>" or "john@example.com"
 * @returns {string|null} - Domain or null if not found
 */
function extractSenderDomain(fromHeader) {
  if (!fromHeader) return null;
  const match = fromHeader.match(/@([a-zA-Z0-9.-]+)/);
  return match ? match[1].toLowerCase() : null;
}

/**
 * Check MTA-STS DNS record
 * Record location: _mta-sts.{domain}
 * Expected format: v=STSv1; id={unique-id}
 * @param {string} domain
 * @returns {Promise<object>}
 */
async function checkMtaStsDns(domain) {
  try {
    const records = await dns.resolveTxt(`_mta-sts.${domain}`);
    const record = records.flat().join('');
    const isValid = /v=STSv1/i.test(record) && /id=/i.test(record);
    return { found: true, record, valid: isValid, error: null };
  } catch (err) {
    if (err.code === 'ENODATA' || err.code === 'ENOTFOUND' || err.code === 'ENOENT') {
      return { found: false, record: null, valid: false, error: null };
    }
    return { found: false, record: null, valid: false, error: err.message };
  }
}

/**
 * Parse MTA-STS policy text
 * Expected fields: version, mode, mx, max_age
 * @param {string} text
 * @returns {object}
 */
function parseMtaStsPolicy(text) {
  const lines = text.split(/\r?\n/);
  const policy = { version: null, mode: null, mx: [], max_age: null };
  for (const line of lines) {
    const colonIndex = line.indexOf(':');
    if (colonIndex === -1) continue;
    const key = line.substring(0, colonIndex).trim().toLowerCase();
    const value = line.substring(colonIndex + 1).trim();
    if (key === 'version') policy.version = value;
    else if (key === 'mode') policy.mode = value;
    else if (key === 'mx') policy.mx.push(value);
    else if (key === 'max_age') policy.max_age = parseInt(value, 10);
  }
  return policy;
}

/**
 * Fetch MTA-STS policy file
 * URL: https://mta-sts.{domain}/.well-known/mta-sts.txt
 * @param {string} domain
 * @returns {Promise<object>}
 */
function fetchMtaStsPolicy(domain) {
  return new Promise((resolve) => {
    const url = `https://mta-sts.${domain}/.well-known/mta-sts.txt`;
    const timeout = setTimeout(() => {
      resolve({ found: false, policy: null, raw: null, error: 'Timeout' });
    }, 5000);

    const req = https.get(url, { timeout: 5000 }, (res) => {
      clearTimeout(timeout);
      if (res.statusCode !== 200) {
        resolve({ found: false, policy: null, raw: null, error: `HTTP ${res.statusCode}` });
        return;
      }
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        const policy = parseMtaStsPolicy(data);
        resolve({ found: true, policy, raw: data, error: null });
      });
    });

    req.on('error', (err) => {
      clearTimeout(timeout);
      resolve({ found: false, policy: null, raw: null, error: err.message });
    });

    req.on('timeout', () => {
      req.destroy();
      clearTimeout(timeout);
      resolve({ found: false, policy: null, raw: null, error: 'Timeout' });
    });
  });
}

/**
 * Check TLS-RPT DNS record
 * Record location: _smtp._tls.{domain}
 * Expected format: v=TLSRPTv1; rua=mailto:...
 * @param {string} domain
 * @returns {Promise<object>}
 */
async function checkTlsRptDns(domain) {
  try {
    const records = await dns.resolveTxt(`_smtp._tls.${domain}`);
    const record = records.flat().join('');
    const isValid = /v=TLSRPTv1/i.test(record);
    const ruaMatch = record.match(/rua=([^;\s]+)/i);
    const reportingUri = ruaMatch ? ruaMatch[1].trim() : null;
    return { found: true, record, valid: isValid, reportingUri, error: null };
  } catch (err) {
    if (err.code === 'ENODATA' || err.code === 'ENOTFOUND' || err.code === 'ENOENT') {
      return { found: false, record: null, valid: false, reportingUri: null, error: null };
    }
    return { found: false, record: null, valid: false, reportingUri: null, error: err.message };
  }
}

/**
 * Perform all transport security checks for a domain
 * @param {string} domain
 * @returns {Promise<object>}
 */
async function checkTransportSecurity(domain) {
  if (!domain) {
    return {
      mtaSts: { configured: false, error: 'No domain' },
      tlsRpt: { configured: false, error: 'No domain' }
    };
  }

  // Run DNS checks in parallel
  const [mtaStsDns, tlsRpt] = await Promise.all([
    checkMtaStsDns(domain),
    checkTlsRptDns(domain)
  ]);

  // Only fetch policy if DNS record exists and is valid
  let mtaStsPolicy = null;
  if (mtaStsDns.found && mtaStsDns.valid) {
    mtaStsPolicy = await fetchMtaStsPolicy(domain);
  }

  return {
    mtaSts: {
      dns: mtaStsDns,
      policy: mtaStsPolicy,
      configured: mtaStsDns.valid && mtaStsPolicy?.found && !!mtaStsPolicy?.policy?.mode,
      mode: mtaStsPolicy?.policy?.mode || null
    },
    tlsRpt: {
      ...tlsRpt,
      configured: tlsRpt.valid && !!tlsRpt.reportingUri
    }
  };
}

module.exports = {
  extractSenderDomain,
  checkMtaStsDns,
  fetchMtaStsPolicy,
  parseMtaStsPolicy,
  checkTlsRptDns,
  checkTransportSecurity
};
