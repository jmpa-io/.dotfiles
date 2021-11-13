<p align="center">
  <img src="./img/logo.png">
</p>

# .dotfiles

```diff
+ Here are my dotfiles.
```

## New PC?

1. Using a terminal, run:
```sh
mkdir -p $HOME/.local/bin
```

2. Copy the following to `$HOME/.local/bin/git-credential-manager`:
```awk
#!/usr/bin/awk -f

BEGIN {
	if (ARGV[1] != "get") {
		exit 0
	}
	ARGC--
	FS="="
}

$1 == "host"     { host = $2 }
$1 == "protocol" { proto = $2 }

END {
	if ( host != "github.com" || proto != "https" ) {
		printf "invalid params: host=%s protocol=%s\n", host, proto
		exit 0
	}
	getToken = "aws ssm get-parameter --name /tokens/github --with-decryption | jq -r '.Parameter.Value'"
	getToken | getline token
	close(getToken)
	curl = "curl -s -H 'Authorization: token #' -H 'Accept: application/vnd.github.v3+json' https://api.github.com/user | jq -r '.login'"
	gsub(/#/, token, curl)
	curl | getline username
	close(curl)

	printf "username=%s\npassword=%s\n", username, token
	exit 0
}
```

3. Using a terminal, run:
```sh
chmod +x "$HOME/.local/bin/git-credential-manager"
```

4. Auth to your AWS account.

5. Clone this repo.

6. Using a terminal, run:
```sh
cd /path/to/cloned/repo
./setup.sh
```

7. You should be good to go! 🎉