./binarycreator --offline-only -c config/config.xml -p packages GUIInstaller

echo "taskset -cp 0,1 \`pgrep -f GUIInstaller\`"
