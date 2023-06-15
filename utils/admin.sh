

read -r -p "Enter node moniker: " PASS
RUN printf "${PASS}\n${PASS}\n" | adduser admin
su - admin
ssh-keygen -t rsa -b 4096 -f $HOME/.ssh/id_rsa -N "$PASS"
