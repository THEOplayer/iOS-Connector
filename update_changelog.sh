while getopts "v:" opt
do
   case "$opt" in
      v ) version="$OPTARG" ;;
   esac
done
if [ -z "$version" ]
then
   echo "Missing argument: 'version'. Usage: \$sh update_changelog.sh -v 1.0.0"
fi

v=$version
file_path="./CHANGELOG.md"
date=$(date +"%Y-%m-%d")

# Replace the line containing "## Unreleased" with new version and date
sed -i '' -e "s/^## Unreleased$/## [$v] - $date/" "$file_path"
