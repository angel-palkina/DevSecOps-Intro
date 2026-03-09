#!/bin/bash

echo "=== ZAP Scan Comparison: Authenticated vs Unauthenticated ==="
echo ""

# Count URLs from baseline scan
if [ -f labs/lab5/zap/zap-report-noauth.json ]; then
  noauth_urls=$(jq '.site[0].alerts | length' labs/lab5/zap/zap-report-noauth.json 2>/dev/null || echo "N/A")
  echo "Unauthenticated scan alert types: $noauth_urls"
else
  echo "Unauthenticated scan results not found"
fi

# Count findings from authenticated scan  
if [ -f labs/lab5/zap/report-auth.html ]; then
  auth_high=$(grep -c 'class="risk-3"' labs/lab5/zap/report-auth.html 2>/dev/null || echo "0")
  auth_med=$(grep -c 'class="risk-2"' labs/lab5/zap/report-auth.html 2>/dev/null || echo "0")
  auth_low=$(grep -c 'class="risk-1"' labs/lab5/zap/report-auth.html 2>/dev/null || echo "0")
  
  # Divide by 2 because each alert appears twice in HTML
  auth_high=$((auth_high / 2))
  auth_med=$((auth_med / 2))
  auth_low=$((auth_low / 2))
  
  echo "Authenticated scan findings:"
  echo "  - High: $auth_high"
  echo "  - Medium: $auth_med"
  echo "  - Low: $auth_low"
  echo "  - Total: $((auth_high + auth_med + auth_low))"
else
  echo "Authenticated scan results not found (still running?)"
fi

echo ""
echo "Key authenticated endpoints discovered:"
grep -o 'http://localhost:3000/rest/admin/[^"]*' labs/lab5/zap/report-auth.html 2>/dev/null | sort -u | head -5