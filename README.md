# GGET

## Description

A rust utility to clone a repo partially, choosing which subfolder and/or file to download.

## Run from source

To run GGET from source follow this simple steps

**First clone the repo on your local machine**

```bash
$ git clone https://github.com/jacopo-degattis/gget
```

**_Then give gget.rb executable permission_**

```bash
cd gget
chmod +x gget.rb
```

**_Finally, run the script_**

```bash
./gget.rb <repo_uri>

If you want to get a private repo just use '-a' option and provide github username and token.
```

## How to get your Github token

- First go to github.com and login into you account
- Then click on your profile pic -> settings -> developer settings -> personal access tokens
- Now generate a new token and give for simplicity all permissions. It's better to give token just the
  nedded permissions.

## LICENSE

[MIT](LICENSE)

## Author

Jacopo De Gattis
