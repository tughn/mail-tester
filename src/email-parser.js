#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const dns = require('dns').promises;
const { simpleParser } = require('mailparser');
const { extractSenderDomain, checkTransportSecurity } = require('./dns-checker');

const DATA_DIR = process.env.DATA_DIR || '/var/lib/deliverability-checker/emails';
const LOG_FILE = process.env.LOG_FILE || '/var/log/deliverability-checker/parser.log';

// Comprehensive spam keywords from industry sources (SpamAssassin, Rspamd patterns)
const SPAM_KEYWORDS = {
  high: [
    // Pharmaceuticals/Adult
    'viagra', 'cialis', 'levitra', 'pharmacy', 'pills online', 'cheap meds',
    'erectile dysfunction', 'male enhancement', 'penis enlargement',
    // Nigerian/419 scams
    'nigerian prince', 'inheritance', 'million dollars', 'beneficiary',
    'next of kin', 'unclaimed funds', 'dormant account', 'fund transfer',
    'central bank of nigeria', 'diplomatic courier', 'barrister', 'consignment box',
    // Financial scams
    'bank transfer', 'wire transfer', 'western union', 'moneygram', 'money order',
    'lottery winner', 'won the lottery', 'prize notification', 'claim your winnings',
    'winning ticket', 'lucky winner', 'cash prize', 'jackpot winner',
    // Cryptocurrency scams
    'cryptocurrency giveaway', 'bitcoin giveaway', 'eth giveaway', 'crypto airdrop',
    'nft giveaway', 'crypto doubler', 'double your bitcoin', 'blockchain wallet',
    'free crypto', 'mining opportunity', 'guaranteed returns', 'investment opportunity',
    // Credential harvesting/Phishing
    'verify your account', 'confirm your identity', 'suspended account',
    'unusual activity', 'password expired', 'account will be closed',
    'verify your email', 'confirm your password', 'security alert',
    'unauthorized access', 'login attempt', 'update your information',
    'verify your identity', 'account verification required', 'confirm your details',
    'your account has been limited', 'restore your account', 'reactivate your account',
    // Fake invoices/Payments
    'invoice attached', 'payment declined', 'overdue payment', 'payment required',
    'outstanding balance', 'collection agency', 'final demand', 'legal action',
    'debt collector', 'payment failure', 'billing error', 'refund pending',
    // BEC/CEO fraud
    'urgent wire', 'gift cards', 'confidential request', 'send itunes',
    'send amazon', 'wire immediately', 'from ceo', 'urgent task',
    'need your help', 'keep this confidential', 'wire funds', 'purchase gift cards',
    'apple gift card', 'google play card', 'steam card',
    // Malware delivery
    'open attachment', 'see attached', 'attached invoice', 'attached document',
    'enable macros', 'enable content', 'enable editing',
    // Romance scams
    'lonely hearts', 'looking for love', 'single and searching', 'dating site',
    // Weight loss scams
    'lose weight fast', 'miracle diet', 'fat burner', 'weight loss pill',
    // Work from home scams
    'work from home', 'easy money', 'earn thousands', 'get rich quick',
    'make money online', 'passive income', 'financial freedom'
  ],
  medium: [
    // Urgency/Pressure tactics
    'act now', 'limited time', 'expires today', 'urgent action', 'hurry',
    'immediate response', 'click here now', 'order now', 'buy now',
    'don\'t delay', 'time sensitive', 'deadline approaching', 'last chance',
    'final notice', 'act immediately', 'respond immediately', 'urgent reply',
    'within 24 hours', 'within 48 hours', 'before deadline', 'action required',
    'response needed', 'reply urgently', 'immediate action required',
    // Free/No cost offers
    'free gift', 'free money', 'no cost', 'no obligation', 'no credit check',
    'no questions asked', 'no purchase necessary', 'absolutely free', 'free access',
    'free membership', 'free trial', 'risk free', 'zero risk',
    // Too good to be true
    'congratulations', 'you have been selected', 'you\'ve been chosen',
    'special promotion', 'exclusive deal', 'once in a lifetime', 'limited offer',
    'incredible opportunity', 'amazing offer', 'unbelievable deal',
    'you won', 'claim your prize', 'selected winner', 'award notification',
    'compensation funds', 'unclaimed funds', 'guaranteed winner',
    // Social engineering phrases
    'kindly revert', 'do the needful', 'revert back', 'at your earliest',
    'please find attached', 'as discussed earlier', 'per our conversation',
    'as per our', 'further to our', 'following our conversation',
    // Authority impersonation
    'official notice', 'official notification', 'legal notice', 'court order',
    'government grant', 'tax refund', 'irs notification', 'hmrc notification',
    // Trust building
    '100% guaranteed', 'satisfaction guaranteed', 'money back guarantee',
    'trusted partner', 'verified seller', 'certified', 'legitimate',
    // FOMO
    'selling out fast', 'only a few left', 'limited availability', 'exclusive access',
    'vip access', 'members only', 'invitation only', 'by invitation',
    // Personal info requests
    'send your details', 'provide your information', 'update your records',
    'confirm your address', 'verify your phone', 'social security'
  ],
  low: [
    // Marketing language
    'unsubscribe', 'opt-out', 'click here', 'learn more', 'act fast',
    'don\'t miss', 'limited offer', 'special offer', 'best price',
    'lowest price', 'discount', 'save big', 'free trial', 'best deal',
    'great savings', 'huge discount', 'massive sale', 'clearance sale',
    // Generic greetings
    'dear valued customer', 'dear user', 'dear member', 'dear friend',
    'dear sir/madam', 'dear account holder', 'dear customer', 'dear client',
    'dear subscriber', 'dear recipient', 'hello friend', 'greetings',
    // Suspicious closings
    'god bless', 'remain blessed', 'yours in service', 'best regards',
    'kind regards', 'warm regards', 'sincerely yours',
    // Vague sender references
    'customer service team', 'support team', 'accounts department',
    'billing department', 'security team', 'admin team',
    // Impersonal references
    'dear webmail user', 'email user', 'account holder',
    // Foreign language spam indicators
    'por favor', 'sehr geehrte', 'cher ami', 'caro cliente'
  ]
};

// Suspicious file extensions (often used in malware)
const SUSPICIOUS_EXTENSIONS = [
  '.exe', '.scr', '.zip', '.rar', '.7z', '.js', '.vbs', '.bat', '.cmd',
  '.ps1', '.iso', '.img', '.dmg', '.docm', '.xlsm', '.pptm', '.jar'
];

// Homograph attack patterns (lookalike domains)
const HOMOGRAPH_PATTERNS = [
  /paypa[l1]\.com/i, /app[l1]e\.com/i, /g00g[l1]e\.com/i,
  /amaz[o0]n\.com/i, /micr[o0]s[o0]ft\.com/i, /netf[l1]ix\.com/i,
  /faceb[o0][o0]k\.com/i, /1nstagram\.com/i, /twitt[e3]r\.com/i
];

// URL shorteners often used in spam
const URL_SHORTENERS = ['bit.ly', 'tinyurl', 'goo.gl', 't.co', 'ow.ly', 'is.gd', 'buff.ly', 'adf.ly', 'j.mp', 'tr.im', 'shorte.st', 'cutt.ly', 'rb.gy', 'tny.im', 'short.io'];

// Known phishing/spam TLDs (higher risk)
const SUSPICIOUS_TLDS = ['.xyz', '.top', '.click', '.link', '.work', '.date', '.review', '.country', '.stream', '.download', '.racing', '.win', '.bid', '.trade', '.webcam', '.party', '.science', '.gq', '.cf', '.ga', '.ml', '.tk'];

function log(msg) {
  const line = `[${new Date().toISOString()}] ${msg}\n`;
  try {
    fs.appendFileSync(LOG_FILE, line);
  } catch (e) {}
}

/**
 * Extract URLs from email content
 */
function extractUrls(text, html) {
  const urls = new Set();
  const urlPattern = /https?:\/\/[^\s<>"')\]]+/gi;

  // Extract from text
  const textMatches = (text || '').match(urlPattern) || [];
  textMatches.forEach(u => urls.add(u));

  // Extract from HTML href attributes
  const hrefPattern = /href=["']?(https?:\/\/[^"'\s>]+)/gi;
  let match;
  while ((match = hrefPattern.exec(html || '')) !== null) {
    urls.add(match[1]);
  }

  return Array.from(urls);
}

/**
 * Extract domain from URL for SURBL lookup
 */
function extractDomainFromUrl(url) {
  try {
    const parsed = new URL(url);
    let domain = parsed.hostname.toLowerCase();
    // Remove www prefix
    if (domain.startsWith('www.')) {
      domain = domain.substring(4);
    }
    return domain;
  } catch (e) {
    return null;
  }
}

/**
 * Check domain against SURBL (Spam URI Realtime Blocklists)
 * Returns true if domain is blacklisted
 */
async function checkSurbl(domain) {
  if (!domain) return { listed: false };

  try {
    // Query SURBL multi list
    const query = `${domain}.multi.surbl.org`;
    const addresses = await dns.resolve4(query);

    // If we get a response, domain is listed
    // Different return codes indicate different lists
    const code = addresses[0] || '';
    const lists = [];

    // Parse SURBL response codes (bitmask)
    const lastOctet = parseInt(code.split('.').pop(), 10);
    if (lastOctet & 8) lists.push('phishing');
    if (lastOctet & 16) lists.push('malware');
    if (lastOctet & 64) lists.push('spam');
    if (lastOctet & 128) lists.push('cracked');

    return { listed: true, lists, code };
  } catch (err) {
    // NXDOMAIN means not listed (good)
    if (err.code === 'ENOTFOUND' || err.code === 'ENODATA') {
      return { listed: false };
    }
    // Other errors - assume not listed
    return { listed: false, error: err.message };
  }
}

/**
 * Check URLs against multiple reputation services
 */
async function checkUrlReputation(urls) {
  const results = {
    checked: 0,
    blacklisted: [],
    suspiciousTlds: [],
    shorteners: []
  };

  // Limit checks to avoid timeouts
  const uniqueDomains = new Set();
  const domainsToCheck = [];

  for (const url of urls.slice(0, 20)) { // Max 20 URLs
    const domain = extractDomainFromUrl(url);
    if (!domain || uniqueDomains.has(domain)) continue;
    uniqueDomains.add(domain);

    // Check for URL shorteners
    for (const shortener of URL_SHORTENERS) {
      if (domain.includes(shortener)) {
        results.shorteners.push({ url, domain });
        break;
      }
    }

    // Check for suspicious TLDs
    for (const tld of SUSPICIOUS_TLDS) {
      if (domain.endsWith(tld)) {
        results.suspiciousTlds.push({ url, domain, tld });
        break;
      }
    }

    domainsToCheck.push({ url, domain });
  }

  // Check domains against SURBL (in parallel, max 10)
  const surblChecks = domainsToCheck.slice(0, 10).map(async ({ url, domain }) => {
    const surbl = await checkSurbl(domain);
    results.checked++;
    if (surbl.listed) {
      results.blacklisted.push({ url, domain, lists: surbl.lists });
    }
    return surbl;
  });

  await Promise.all(surblChecks);

  return results;
}

function parseAuthResults(headers) {
  const results = { spf: null, dkim: null, dmarc: null };
  const authResults = headers['authentication-results'] || '';
  const lines = Array.isArray(authResults) ? authResults.join(' ') : authResults;

  const spfMatch = lines.match(/spf=(\w+)/i);
  const dkimMatch = lines.match(/dkim=(\w+)/i);
  const dmarcMatch = lines.match(/dmarc=(\w+)/i);

  if (spfMatch) results.spf = { result: spfMatch[1].toLowerCase() };
  if (dkimMatch) results.dkim = { result: dkimMatch[1].toLowerCase() };
  if (dmarcMatch) results.dmarc = { result: dmarcMatch[1].toLowerCase() };

  const receivedSpf = headers['received-spf'] || '';
  if (!results.spf && receivedSpf) {
    const match = receivedSpf.match(/^(\w+)/);
    if (match) results.spf = { result: match[1].toLowerCase() };
  }

  return results;
}

/**
 * Analyze email content for spam indicators
 * @param {string} subject
 * @param {string} textBody
 * @param {string} htmlBody
 * @param {object} urlReputation - Results from URL reputation check
 */
function analyzeContent(subject, textBody, htmlBody, urlReputation = null) {
  const analysis = {
    score: 100, // Start with perfect score, deduct for issues
    issues: [],
    details: {
      spamKeywords: [],
      urlShorteners: [],
      suspiciousPatterns: [],
      urlReputation: urlReputation
    }
  };

  const text = `${subject || ''} ${textBody || ''}`.toLowerCase();
  const html = (htmlBody || '').toLowerCase();
  const combined = `${text} ${html}`;

  // Check for spam keywords
  let keywordPenalty = 0;
  for (const keyword of SPAM_KEYWORDS.high) {
    if (combined.includes(keyword)) {
      analysis.details.spamKeywords.push({ word: keyword, severity: 'high' });
      keywordPenalty += 15;
    }
  }
  for (const keyword of SPAM_KEYWORDS.medium) {
    if (combined.includes(keyword)) {
      analysis.details.spamKeywords.push({ word: keyword, severity: 'medium' });
      keywordPenalty += 5;
    }
  }
  for (const keyword of SPAM_KEYWORDS.low) {
    if (combined.includes(keyword)) {
      analysis.details.spamKeywords.push({ word: keyword, severity: 'low' });
      keywordPenalty += 2;
    }
  }
  if (keywordPenalty > 0) {
    analysis.score -= Math.min(keywordPenalty, 40); // Cap at 40 point deduction
    if (keywordPenalty >= 15) {
      analysis.issues.push('Contains high-risk spam keywords');
    } else if (keywordPenalty >= 5) {
      analysis.issues.push('Contains suspicious marketing language');
    }
  }

  // Check for URL shorteners (basic text check)
  for (const shortener of URL_SHORTENERS) {
    if (combined.includes(shortener)) {
      analysis.details.urlShorteners.push(shortener);
    }
  }
  if (analysis.details.urlShorteners.length > 0) {
    analysis.score -= 10;
    analysis.issues.push('Contains URL shorteners (often used in phishing)');
  }

  // URL Reputation results (if provided)
  if (urlReputation) {
    // Blacklisted URLs - severe penalty
    if (urlReputation.blacklisted && urlReputation.blacklisted.length > 0) {
      analysis.score -= 30;
      const domains = urlReputation.blacklisted.map(b => b.domain).join(', ');
      analysis.issues.push(`Contains blacklisted URLs: ${domains}`);
      analysis.details.suspiciousPatterns.push('blacklisted_urls');
    }

    // Suspicious TLDs - moderate penalty
    if (urlReputation.suspiciousTlds && urlReputation.suspiciousTlds.length > 0) {
      analysis.score -= 10;
      analysis.issues.push('Contains links with suspicious TLDs');
      analysis.details.suspiciousPatterns.push('suspicious_tlds');
    }

    // Additional shorteners found by URL parsing
    if (urlReputation.shorteners && urlReputation.shorteners.length > 0) {
      // Already penalized above, but add to details
      analysis.details.urlShorteners = [
        ...new Set([...analysis.details.urlShorteners, ...urlReputation.shorteners.map(s => s.domain)])
      ];
    }
  }

  // Check for excessive caps in subject
  if (subject) {
    const capsRatio = (subject.match(/[A-Z]/g) || []).length / subject.length;
    if (capsRatio > 0.6 && subject.length > 10) {
      analysis.score -= 10;
      analysis.issues.push('Subject line has excessive CAPS');
      analysis.details.suspiciousPatterns.push('excessive_caps');
    }
  }

  // Check for excessive exclamation marks
  const exclamationCount = (combined.match(/!/g) || []).length;
  if (exclamationCount > 5) {
    analysis.score -= 5;
    analysis.issues.push('Excessive exclamation marks');
    analysis.details.suspiciousPatterns.push('excessive_exclamation');
  }

  // Check for money symbols and amounts (potential scam indicator)
  const moneyPattern = /\$[\d,]+(?:\.\d{2})?|\d+(?:,\d{3})*(?:\.\d{2})?\s*(?:dollars?|usd|euros?|pounds?)/gi;
  const moneyMatches = combined.match(moneyPattern) || [];
  if (moneyMatches.length > 3) {
    analysis.score -= 10;
    analysis.issues.push('Multiple monetary amounts mentioned');
    analysis.details.suspiciousPatterns.push('multiple_money_refs');
  }

  // Check for urgency patterns
  const urgencyPatterns = /(?:act|respond|reply|call)\s+(?:now|immediately|today|asap)|(?:expires?|ending)\s+(?:soon|today|tonight)|last\s+chance|final\s+notice/gi;
  if (urgencyPatterns.test(combined)) {
    analysis.score -= 10;
    analysis.issues.push('Contains urgency/pressure tactics');
    analysis.details.suspiciousPatterns.push('urgency_tactics');
  }

  // Check for suspicious sender patterns in from address
  // (This would be checked against the 'from' field separately)

  // Count links in HTML
  const linkCount = (html.match(/<a\s+[^>]*href/gi) || []).length;
  if (linkCount > 10) {
    analysis.score -= 5;
    analysis.issues.push('Excessive number of links');
    analysis.details.suspiciousPatterns.push('excessive_links');
  }

  // Check image-to-text ratio (spam often uses images to avoid text filters)
  const imageCount = (html.match(/<img/gi) || []).length;
  const textLength = text.length;
  if (imageCount > 0 && textLength < 100) {
    analysis.score -= 10;
    analysis.issues.push('Low text content with images (possible image-based spam)');
    analysis.details.suspiciousPatterns.push('image_heavy');
  }

  // Check for suspicious file extensions mentioned in content
  const extensionMatches = [];
  for (const ext of SUSPICIOUS_EXTENSIONS) {
    const pattern = new RegExp(ext.replace('.', '\\.'), 'gi');
    if (pattern.test(combined)) {
      extensionMatches.push(ext);
    }
  }
  if (extensionMatches.length > 0) {
    analysis.score -= 15;
    analysis.issues.push('References potentially dangerous file types');
    analysis.details.suspiciousPatterns.push('dangerous_attachments');
    analysis.details.suspiciousExtensions = extensionMatches;
  }

  // Check for homograph attacks (lookalike domains)
  for (const pattern of HOMOGRAPH_PATTERNS) {
    if (pattern.test(combined)) {
      analysis.score -= 20;
      analysis.issues.push('Possible domain spoofing detected');
      analysis.details.suspiciousPatterns.push('homograph_attack');
      break;
    }
  }

  // Check for hidden text (common spam technique)
  const hiddenTextPattern = /color:\s*(?:white|#fff|#ffffff|transparent)|font-size:\s*0|display:\s*none/gi;
  if (hiddenTextPattern.test(html)) {
    analysis.score -= 15;
    analysis.issues.push('Hidden text detected');
    analysis.details.suspiciousPatterns.push('hidden_text');
  }

  // Check for base64 encoded content in text (often used to hide spam)
  const base64Pattern = /[A-Za-z0-9+/]{50,}={0,2}/g;
  const base64Matches = text.match(base64Pattern) || [];
  if (base64Matches.length > 2) {
    analysis.score -= 10;
    analysis.issues.push('Excessive encoded content');
    analysis.details.suspiciousPatterns.push('encoded_content');
  }

  // Ensure score doesn't go below 0
  analysis.score = Math.max(0, analysis.score);

  // Determine overall content rating
  if (analysis.score >= 90) {
    analysis.rating = 'clean';
  } else if (analysis.score >= 70) {
    analysis.rating = 'suspicious';
  } else if (analysis.score >= 40) {
    analysis.rating = 'likely_spam';
  } else {
    analysis.rating = 'spam';
  }

  return analysis;
}

async function main() {
  const recipient = process.argv[2];
  if (!recipient) { log('No recipient'); process.exit(0); }

  const match = recipient.match(/^test-([a-f0-9]+)@/i);
  if (!match) { log(`Invalid recipient: ${recipient}`); process.exit(0); }

  const testId = match[1];
  log(`Processing email for test ID: ${testId}`);

  let rawEmail = '';
  process.stdin.setEncoding('utf8');
  for await (const chunk of process.stdin) { rawEmail += chunk; }

  try {
    const parsed = await simpleParser(rawEmail);
    const hdrs = {};
    parsed.headers.forEach((v, k) => { hdrs[k] = v; });

    const auth = parseAuthResults(hdrs);

    // Extract sender domain and check transport security
    const fromHeader = parsed.from?.text || '';
    const senderDomain = extractSenderDomain(fromHeader);
    let transportSecurity = null;

    if (senderDomain) {
      try {
        transportSecurity = await checkTransportSecurity(senderDomain);
        log(`Transport security for ${senderDomain}: MTA-STS=${transportSecurity.mtaSts.configured}, TLS-RPT=${transportSecurity.tlsRpt.configured}`);
      } catch (err) {
        log(`Transport security check failed: ${err.message}`);
        transportSecurity = {
          mtaSts: { configured: false, error: err.message },
          tlsRpt: { configured: false, error: err.message }
        };
      }
    }

    // Extract and check URLs for reputation
    let urlReputation = null;
    try {
      const urls = extractUrls(parsed.text, parsed.html);
      if (urls.length > 0) {
        urlReputation = await checkUrlReputation(urls);
        log(`URL reputation check: ${urls.length} URLs, ${urlReputation.blacklisted.length} blacklisted, ${urlReputation.suspiciousTlds.length} suspicious TLDs`);
      }
    } catch (err) {
      log(`URL reputation check failed: ${err.message}`);
    }

    // Analyze content for spam indicators
    const contentAnalysis = analyzeContent(
      parsed.subject,
      parsed.text,
      parsed.html,
      urlReputation
    );

    // Extract raw headers from the original email (everything before the first blank line)
    // This preserves the original formatting including continuation lines
    const headerEndIndex = rawEmail.indexOf('\r\n\r\n');
    const headerEndIndexAlt = rawEmail.indexOf('\n\n');
    let rawHeadersSection = '';
    if (headerEndIndex !== -1) {
      rawHeadersSection = rawEmail.substring(0, headerEndIndex);
    } else if (headerEndIndexAlt !== -1) {
      rawHeadersSection = rawEmail.substring(0, headerEndIndexAlt);
    } else {
      // Fallback to parsed headers if we can't find the boundary
      rawHeadersSection = parsed.headerLines?.map(h => `${h.key}: ${h.line}`).join('\n') || '';
    }
    // Normalize line endings for consistent display
    rawHeadersSection = rawHeadersSection.replace(/\r\n/g, '\n').trim();

    const data = {
      id: testId,
      received: true,
      receivedAt: new Date().toISOString(),
      from: fromHeader,
      senderDomain: senderDomain,
      subject: parsed.subject || '',
      spf: auth.spf,
      dkim: auth.dkim,
      dmarc: auth.dmarc,
      mtaSts: transportSecurity?.mtaSts || null,
      tlsRpt: transportSecurity?.tlsRpt || null,
      urlReputation: urlReputation,
      content: contentAnalysis,
      headers: hdrs,
      rawHeaders: rawHeadersSection
    };

    fs.writeFileSync(path.join(DATA_DIR, `${testId}.json`), JSON.stringify(data, null, 2));
    log(`Saved results for ${testId} - Content score: ${contentAnalysis.score}, Rating: ${contentAnalysis.rating}, MTA-STS: ${transportSecurity?.mtaSts?.configured || false}, TLS-RPT: ${transportSecurity?.tlsRpt?.configured || false}`);
  } catch (e) {
    log(`Error: ${e.message}`);
  }
}

main().catch(e => { log(`Fatal: ${e.message}`); process.exit(0); });
