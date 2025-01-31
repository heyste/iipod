#!/usr/bin/env sh
set -x

# Caclulate vars needod for REPO and ORGFILE
REPO_DIR=$(basename $GIT_REPO | sed 's:.git$::')
GIT_REPO_SSH=$(echo $GIT_REPO | sed 'sXhttps://Xgit@X' | sed 'sX/X:X')
ORGFILE=$(basename "$ORGFILE_URL")

echo "Starting TMUX session: $SPACE_NAME:iipod"
tmux new -d -s $SPACENAME -n "iipod"
tmux send-keys -t "$SPACENAME:iipod" "
git clone $GIT_REPO
cd $REPO_DIR
wget $ORGFILE_URL
# ensure we can git push via ssh
mkdir -p ~/.ssh
ssh-keyscan -H github.com >>~/.ssh/known_hosts
git remote add ssh $GIT_REPO_SSH
"

echo "Starting TMUX session: $SPACE_NAME:emacs"
tmux new-window -d -t $SPACENAME -n "emacs"
tmux send-keys -t "$SPACENAME:emacs" "
sleep 15
cd $REPO_DIR
emacsclient -nw $ORGFILE
"

echo "Starting TMUX session: servers:ii"
tmux new -d -s "servers" -n ii
tmux send-keys -t "servers:ii" "
echo These windows contain the services supporting your iipod
"

echo "Starting TMUX session: servers:ttyd"
tmux new-window -d -t "servers" -n "ttyd"
tmux send-keys -t "servers:ttyd" "
ttyd --writable tmux at -t $SPACENAME
"

echo "Starting TMUX session: servers:web-server"
tmux new-window -d -t "servers" -n "web-server"
tmux send-keys -t "servers:web-server" "
python3 -m http.server
"

echo "Starting TMUX session: servers:code-server"
tmux new-window -d -t "servers" -n "code-server"
tmux send-keys -t "servers:code-server" "
code-server --auth none --port 13337
"

echo "Starting TMUX session: servers:broadwayd"
tmux new-window -d -t "servers" -n "broadwayd"
tmux send-keys -t "servers:broadwayd" "
broadwayd :5
"

echo "Starting TMUX session: servers:emacs-pgtk"
tmux new-window -d -t "servers" -n "emacs-pgtk"
tmux send-keys -t "servers:emacs-pgtk" "
export GDK_BACKEND=broadway
export BROADWAY_DISPLAY=:5
emacs $ORGFILE
"

echo "Starting TMUX session: servers:novnc"
tmux new-window -d -t "servers" -n "novnc"
tmux send-keys -t "servers:novnc" "
# We use a branch of novnc that supports OSC52 in Chrome and partially in Firefox
cp -a /usr/share/novnc ~/novnc
cp ~/novnc/vnc.html ~/novnc/index.html
websockify --web=/home/ii/novnc 6080 localhost:5901
"

echo "Starting TMUX session: servers:tigervnc"
tmux new-window -d -t "servers" -n "tigervnc"
tmux send-keys -t "tigervnc" "
unset GDK_BACKEND # must not be set when using X
export PATH=/usr/local/stow/emacs-x/bin:$PATH
tigervncserver :1 -desktop $SESSION_NAME -SecurityTypes None -xstartup startplasma-x11
export DISPLAY=:1
setterm blank 0
setterm powerdown 0
kwriteconfig5 --file ~/.config/kscreenlockerrc --group Daemon --key Autolock false
xset s 0 0
sudo passwd ii -q <<EOF
ii
ii
EOF
kitty -T KITTY --detach --hold --start-as=maximized bash -c 'tmux at'
"
