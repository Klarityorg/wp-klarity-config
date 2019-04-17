# jesuisanas-wp

## Setup

Spin up Wordpress and a DB locally by running:
```bash
docker-compose -f environments/local/docker-compose-dev.yml up -d
```

Wordpress plugins are built automatically when containers created from `environments/local/docker-compose-dev.yml` are (re)started.

## Deploying to production

```bash
cp environments/production/.env.dist environments/production/.env 
```

Fill the missing values in `environments/production/.env`.

```bash
./environments/production/deploy-jesuisanas.sh
```

## Publishing plugin updates

Each plugin is located in a Git submodule in `wp/wp-content/plugins`.
When you want to publish an update for a plugin :
- Update the plugin's version in : 
  * `package.json`
  * `package-lock.json`
  * `plugin.php`
  * `readme.txt`
- Commit : 
```(cd wp/wp-content/plugins/<plugin-name> && git add . && git commit -m "Bump version")```
- Create a tag for the plugin's new version : 
```(cd wp/wp-content/plugins/<plugin-name> && git tag <newversion>)```
- Push the plugin's code to GitHub along with the new tag :
```(cd wp/wp-content/plugins/<plugin-name> && git push && git push --tags)```
- Run the `commit-to-svn.sh` script with the plugin's directory name in argument :
```./environments/wordpress-com/commit-to-svn.sh <plugin-name>```


## Notes for WP-Konsulterna - Deployment of theme to (jesuisanas) Production on Seravo ##

- Update environments/production/.env.dist with the required SSH information.
- Update submodules:
```(git submodule update --init --recursive --remote)```
- Go to the klarity directory:
```(cd wp/wp-content/themes/klarity)```
- Git pull to latest repo version
```(git pull)```
- Return to root folder:
```(cd ../../../../)```
- Run following script:
```( ./environments/production/deploy-jesuisanas.sh)```
