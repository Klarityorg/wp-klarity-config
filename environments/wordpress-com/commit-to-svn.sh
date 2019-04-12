#! /bin/bash
# See https://github.com/GaryJones/wordpress-plugin-svn-deploy for instructions and credits.
#
# Steps to deploying:
#
#  1. Check local plugin directory exists.
#  2. Check main plugin file exists.
#  3. Check readme.txt version matches main plugin file version.
#  4. Ask if input is correct, and give chance to abort.
#  5. Check if Git tag exists for version number (must match exactly).
#  6. Checkout SVN repo.
#  7. Set to SVN ignore some GitHub-related files.
#  8. Export HEAD of master from git to the trunk of SVN.
#  9. Build plugin in the trunk of SVN (so that it contains dist files)
# 10. Initialise and update and git submodules.
# 11. Move /trunk/assets up to /assets.
# 12. Move into /trunk, and SVN commit.
# 13. Move into /assets, and SVN commit.
# 14. Copy /trunk into /tags/{version}, and SVN commit.
# 15. Delete temporary local SVN checkout.

set -e

PLUGINSLUG=$1

if [[ -z "$PLUGINSLUG" ]]; then
    echo "Please specify the slug of the plugin to commit. Usage: $0 <plugin_slug>"
    exit 1
fi

echo
echo "WordPress Plugin SVN Deploy v3.0.0"
echo

SVNURL="https://plugins.svn.wordpress.org/$PLUGINSLUG"
SVNUSER="klarityorg"
MAINFILE="plugin.php"

PLUGINROOTDIR=/tmp
PLUGINDIRNAME=`echo ${PLUGINSLUG} | sed 's/klarity-/wp-plugin-/'`
PLUGINDIRNAME_SVN=`echo ${PLUGINSLUG} | sed 's/klarity-/wp-plugin-/'`-svn
PLUGINDIR=${PLUGINROOTDIR}/${PLUGINDIRNAME}
PLUGINDIR_SVN=${PLUGINROOTDIR}/${PLUGINDIRNAME_SVN}

rm -rf ${PLUGINDIR_SVN} ${PLUGINDIR}
cd ${PLUGINROOTDIR}
git clone https://github.com/Klarityorg/${PLUGINDIRNAME}

# Check main plugin file exists.
if [ ! -f "$PLUGINDIR/$MAINFILE" ]; then
  echo "Plugin file $PLUGINDIR/$MAINFILE not found. Aborting."
  exit 1;
fi

echo "Checking version in main plugin file matches version in readme.txt file..."
echo

# Check version in readme.txt is the same as plugin file after translating both to Unix line breaks to work around grep's failure to identify Mac line breaks
PLUGINVERSION=$(grep -i "Version:" ${PLUGINDIR}/${MAINFILE} | awk -F' ' '{print $NF}' | tr -d '\r')
echo "$MAINFILE version: $PLUGINVERSION"
READMEVERSION=$(grep -i "Stable tag:" ${PLUGINDIR}/readme.txt | awk -F' ' '{print $NF}' | tr -d '\r')
echo "readme.txt version: $READMEVERSION"

if [ "$READMEVERSION" = "trunk" ]; then
	echo "Version in readme.txt & $MAINFILE don't match, but Stable tag is trunk. Let's continue..."
elif [ "$PLUGINVERSION" != "$READMEVERSION" ]; then
	echo "Version in readme.txt & $MAINFILE don't match. Exiting...."
	exit 1;
elif [ "$PLUGINVERSION" = "$READMEVERSION" ]; then
	echo "Versions match in readme.txt and $MAINFILE. Let's continue..."
fi

echo "That's all of the data collected."
echo
echo "Slug: $PLUGINSLUG"
echo "Main file: $MAINFILE"
echo "Remote SVN repo: $SVNURL"
echo "SVN username: $SVNUSER"
echo

printf "OK to proceed (Y|n)? "
read -e input
PROCEED="${input:-y}"
echo

# Allow user cancellation
if [ $(echo "$PROCEED" |tr [:upper:] [:lower:]) != "y" ]; then echo "Aborting..."; exit 1; fi

# Let's begin...
echo ".........................................."
echo
echo "Preparing to deploy WordPress plugin"
echo
echo ".........................................."
echo

echo "Changing to $PLUGINDIR"
cd ${PLUGINDIR}

if git show-ref --tags --quiet --verify -- "refs/tags/$PLUGINVERSION"
	then
		echo "Git tag $PLUGINVERSION does exist. Let's continue..."
	else
		echo "$PLUGINVERSION does not exist as a git tag (make sure that you pushed this tag to the Github repository). Aborting.";
		exit 1;
fi

echo

echo "Creating local copy of SVN repo trunk..."
svn checkout ${SVNURL} ${PLUGINDIR_SVN} --depth immediates
svn update --quiet ${PLUGINDIR_SVN}/trunk --set-depth infinity

echo "Ignoring GitHub specific files"
svn propset svn:ignore "README.md
Thumbs.db
.github/*
.git
.gitattributes
.gitignore" "$PLUGINDIR_SVN/trunk/"

echo "Exporting the HEAD of master from git to the trunk of SVN"
git checkout-index -a -f --prefix=${PLUGINDIR_SVN}/trunk/

#Build if package.json exists
if [ -f ${PLUGINDIR_SVN}/trunk/package.json ]; then
  echo "Building plugin..."
  (cd ${PLUGINDIR_SVN}/trunk && npm install && npm run build && rm -rf node_modules)
fi

# Support for the /assets folder on the .org repo.
echo "Moving assets."
# Make the directory if it doesn't already exist
mkdir -p ${PLUGINDIR_SVN}/assets/
mv ${PLUGINDIR_SVN}/trunk/assets/* ${PLUGINDIR_SVN}/assets/
svn add --force ${PLUGINDIR_SVN}/assets/
svn delete --force ${PLUGINDIR_SVN}/trunk/assets

echo

echo "Changing directory to SVN and committing to trunk."
cd ${PLUGINDIR_SVN}/trunk/
# Delete all files that should not now be added.
svn status | grep -v "^.[ \t]*\..*" | grep "^\!" | awk '{print $2"@"}' | \
    xargs --no-run-if-empty svn del
# Add all new files that are not set to be ignored
svn status | grep -v "^.[ \t]*\..*" | grep "^?" | awk '{print $2"@"}' | \
    xargs --no-run-if-empty svn add
svn commit --username=${SVNUSER} -m "Preparing for $PLUGINVERSION release"

echo

echo "Updating WordPress plugin repo assets and committing."
cd ${PLUGINDIR_SVN}/assets/
# Delete all new files that are not set to be ignored
svn status | grep -v "^.[ \t]*\..*" | grep "^\!" | awk '{print $2"@"}' | \
    xargs --no-run-if-empty svn del
# Add all new files that are not set to be ignored
svn status | grep -v "^.[ \t]*\..*" | grep "^?" | awk '{print $2"@"}' | \
    xargs --no-run-if-empty svn add
svn update --quiet --accept working ${PLUGINDIR_SVN}/assets/*
svn resolve --accept working ${PLUGINDIR_SVN}/assets/*
svn commit --username=${SVNUSER} -m "Updating assets"

echo

echo "Creating new SVN tag and committing it."
cd ${PLUGINDIR_SVN}
svn copy --quiet trunk/ tags/${PLUGINVERSION}/
# Remove assets and trunk directories from tag directory
if [ -d "${PLUGINDIR_SVN}/tags/${PLUGINVERSION}/assets" ]; then
    svn delete --force --quiet ${PLUGINDIR_SVN}/tags/${PLUGINVERSION}/assets
fi
if [ -d "${PLUGINDIR_SVN}/tags/${PLUGINVERSION}/trunk" ]; then
    svn delete --force --quiet ${PLUGINDIR_SVN}/tags/${PLUGINVERSION}/trunk
fi
svn update --quiet --accept working ${PLUGINDIR_SVN}/tags/${PLUGINVERSION}
cd ${PLUGINDIR_SVN}/tags/${PLUGINVERSION}
svn commit --username=${SVNUSER} -m "Tagging version $PLUGINVERSION"

echo

echo "Removing temporary directory $PLUGINDIR_SVN."
cd ${PLUGINDIR_SVN}
cd ..
rm -rf ${PLUGINDIR_SVN}/

echo "*** DONE ***"
