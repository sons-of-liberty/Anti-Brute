#!/bin/bash
read -p "Enter a new SSH port number: " new_port
if [[ "$new_port" =~ ^[0-9]+$ ]]; then
    # Update the SSH configuration file
    sed -i "s/^#*Port .*/Port $new_port/" /etc/ssh/sshd_config
    sed -i 's/^#*PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
    systemctl restart ssh
    echo "SSH port has been updated to $new_port."
else
    echo "Invalid input. Please enter a positive integer."
fi
# Configure iptables to limit SSH login attempts
echo "Configuring iptables rules..."
iptables -N SSH_WHITELIST
iptables -A INPUT -p tcp --dport $new_port -m state --state NEW -m recent --set --name SSH -j ACCEPT
iptables -A INPUT -p tcp --dport $new_port -m recent --update --seconds 60 --hitcount 2 --rttl --name SSH -j LOG --log-prefix "SSH_brute_force"
iptables -A INPUT -p tcp --dport $new_port -m recent --update --seconds 60 --hitcount 2 --rttl --name SSH -j DROP

# Install and enable Fail2ban
echo "Installing Fail2ban..."
apt install fail2ban
systemctl enable --now fail2ban
exit
