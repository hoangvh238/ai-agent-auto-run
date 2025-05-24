#!/bin/bash

echo "🛠️ Cài đặt SuperAGI và thiết lập backup tự động..."

# === Phần 1: Cài Docker, Git, và clone SuperAGI ===
sudo apt update -y
sudo apt install -y docker.io docker-compose git

sudo systemctl enable docker
sudo systemctl start docker

# Clone nếu chưa có
if [ ! -d "$HOME/SuperAGI" ]; then
  git clone https://github.com/TransformerOptimus/SuperAGI.git $HOME/SuperAGI
fi

cd $HOME/SuperAGI || exit 1

# === Phần 2: Cấu hình file config.yaml ===
cp -n config_template.yaml config.yaml

sed -i "s/llm_provider:.*/llm_provider: openrouter/" config.yaml
sed -i "/model_api_keys:/a \ \ openrouter: \"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\"" config.yaml
sed -i "s/default_model:.*/default_model: openrouter\/openai\/gpt-4/" config.yaml

# === Phần 3: Build và chạy SuperAGI ===
docker compose -f docker-compose.yaml up --build -d

# === Phần 4: Tạo script auto push ===
cat <<'EOF' > $HOME/auto_push.sh
#!/bin/bash
REPO_DIR="$HOME/SuperAGI"
cd "$REPO_DIR" || exit 1
BRANCH_NAME="backup-$(date +%Y-%m-%d)"

if ! git show-ref --quiet refs/heads/"$BRANCH_NAME"; then
  git checkout -b "$BRANCH_NAME"
else
  git checkout "$BRANCH_NAME"
fi

git add .
git commit -m "🕒 Auto-backup at $(date '+%Y-%m-%d %H:%M:%S')" --allow-empty
git push origin "$BRANCH_NAME"
EOF

chmod +x $HOME/auto_push.sh

# === Phần 5: Thêm cron job nếu chưa có ===
(crontab -l 2>/dev/null | grep -q 'auto_push.sh') || (
  (crontab -l 2>/dev/null; echo "*/15 * * * * /bin/bash $HOME/auto_push.sh >> $HOME/auto_push.log 2>&1") | crontab -
)

echo ""
echo "✅ SuperAGI đã được cài đặt và cron job đã thiết lập thành công!"
echo "🔁 Mỗi 15 phút sẽ tự động commit + push backup lên GitHub."
echo "🌐 Truy cập SuperAGI tại: http://localhost:3000 hoặc http://[IP_VPS]:3000"
