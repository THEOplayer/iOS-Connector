while getopts "v:" opt
do
   case "$opt" in
      v ) version="$OPTARG" ;;
   esac
done
if [ -z "$version" ]
then
   echo "Missing argument: 'version'. Usage: \$sh update_version_json.sh -v 1.0.0"
fi

v=$version
major_minor=${v%.*}
patch=$((${v##*.}))
echo $(cat version.json \
	| jq --arg major_minor "$major_minor" '.major_minor=$major_minor' \
	| jq --arg patch "$patch" '.patch=$patch') \
	> version.json
