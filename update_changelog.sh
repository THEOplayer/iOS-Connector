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
# only when there are new changelog entries. Adds back the ## Unreleased mark.
awk -v v="$v" -v date="$date" '
/^## Unreleased$/ {
    print
    getline nextline
    if (nextline ~ /^$/) {
        buffer = ""
        while ((getline peek) > 0 && peek ~ /^$/) buffer = buffer "\n" peek
        if (peek ~ /^## \[/) {
            print ""
            print nextline buffer peek
            next
        } else {
            print ""
            print "## [" v "] - " date
            print ""
            print nextline buffer peek
            next
        }
    }
}
{ print }
' "$file_path" > "$file_path.tmp" && mv "$file_path.tmp" "$file_path"
