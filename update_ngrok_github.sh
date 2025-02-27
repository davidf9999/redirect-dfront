#!/bin/bash
#set -x
# ====================== CONFIG ======================
LOCAL_REPO_PATH="$HOME/code/redirect-dfront"  # Path to your local repo
PORT=8501                                # Local app port (Streamlit default)
GITHUB_USERNAME="davidf9999"
REPO_NAME="redirect-dfront"
COMMIT_MESSAGE="Update NGROK URL"
NGROK_REGION="eu"                        # Change if needed (us, eu, ap, etc.)
# ===================================================

echo "Starting NGROK on port $PORT..."
# Kill existing NGROK instances (optional, prevents duplicates)
pkill -f "ngrok http" || echo "No previous NGROK process found"

# Run NGROK in the background
nohup ngrok http $PORT --region=$NGROK_REGION > /dev/null 2>&1 &

# Wait a few seconds to ensure NGROK starts
sleep 5

# Get the NGROK URL
NGROK_URL=$(curl -s http://127.0.0.1:4040/api/tunnels | jq -r '.tunnels[0].public_url')

if [[ -z "$NGROK_URL" ]]; then
    echo "Error: NGROK URL not found. Is NGROK running?"
    exit 1
fi

echo "NGROK URL: $NGROK_URL"

# Update index.html with a JavaScript redirect that preserves the query string
cd "$LOCAL_REPO_PATH" || { echo "Repo path not found"; exit 1; }

cat <<EOF > index.html
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Redirecting...</title>
  <script>
    // Grab the current URL's query string (e.g. ?code=...&state=...)
    const queryString = window.location.search;
    // Build the new URL by appending the query to your ephemeral ngrok domain
    const newUrl = "$NGROK_URL" + queryString;
    // Perform the redirect
    window.location.replace(newUrl);
  </script>
</head>
<body>
  <p>Redirecting...</p>
</body>
</html>
EOF

echo "index.html updated with $NGROK_URL (JavaScript redirect preserving query params)"

# Commit and push changes
git add index.html
git commit -m "$COMMIT_MESSAGE"
git push origin main
echo "Changes pushed to GitHub: $GITHUB_USERNAME/$REPO_NAME"

# Done
echo "Visit: https://$GITHUB_USERNAME.github.io/$REPO_NAME"
