sudo apt-get update

sudo apt install vim
sudo apt install terminator
sudo apt install zathura

cp vimrc ~/.vimrc

mkdir ~/.config/zathura
cp zathurarc ~/.config/zathura/zathurarc

cat bashrc_tail >> ~/.bashrc

# Remove dock
sudo apt remove gnome-shell-extension-ubuntu-dock

sudo apt install gnome-tweaks

cat further_todos

