# access to github repo

ssh-keygen -t ed25519 -C "robert@rbsoftware.pl" 

## Start & configure the SSH agent (macOS)

eval "$(ssh-agent -s)"     

## Edit ~/.ssh/config

Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519_github

## Add the key to the agent

ssh-add --apple-use-keychain ~/.ssh/id_ed25519_github

## Copy-paste the key to github

pbcopy < ~/.ssh/id_ed25519_github.pub

## Test the connection

ssh -T git@github.com        

# dotfiles

One-line binary and dotfiles install:
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply git@github.com:$GITHUB_USERNAME/dotfiles.git


