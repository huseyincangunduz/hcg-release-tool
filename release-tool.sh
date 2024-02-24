function join_by() {
    local d=${1-} f=${2-}
    if shift 2; then
        printf %s "$f" "${@/#/$d}"
    fi
}

TEMP_PACK_NAME_JSON=".hcgrt-temp.json"

echo "[]" >$TEMP_PACK_NAME_JSON
VERSION_CHECK=""
ITEMS_JSON="[]"

for arg in "${@}"; do
    VERSION_CHECK=$(echo $arg | grep -E ^ver | head -1 | cut -c 4-)
    if [ ! -z $VERSION_CHECK ]; then
        VERSION=$VERSION_CHECK
        notify-send $VERSION
    else
        PACKAGE_NAME=$(cat ${arg}/package.json | jq -r .name)

        # echo $(cat $TEMP_DIRECTORY_JSON | jq ".[$PACKAGE_NAME]=\"$arg\"") > $TEMP_DIRECTORY_JSON;
        echo $(cat $TEMP_PACK_NAME_JSON | jq ". += [{\"name\":\"$PACKAGE_NAME\", \"directory\":\"$arg\"}]") >$TEMP_PACK_NAME_JSON
        ITEMS_JSON=$(echo $ITEMS_JSON | jq ". += [\"$PACKAGE_NAME\"]")

    fi

done

ITEMS=$(echo $(cat $TEMP_PACK_NAME_JSON | jq ".[].name"))
ITEMS_COMMA=$(join_by , $ITEMS)
for ITEM in $ITEMS; do
    DIRECTORY=$(cat $TEMP_PACK_NAME_JSON | jq -r ".[] | select( .name==$ITEM) | .directory")

    PACKAGES_INCLUDED=$(cat ${DIRECTORY}/package.json | jq -r ".[\"peerDependencies\"] | keys  | map(select(IN($ITEMS_COMMA))) | length")
    if [ -z $PACKAGES_INCLUDED ]; then
        PACKAGES_INCLUDED=0
    fi
    echo $(cat $TEMP_PACK_NAME_JSON | jq -r "(.[] | select(.name == $ITEM) | .relativeDepencyLength) |= $PACKAGES_INCLUDED") >$TEMP_PACK_NAME_JSON
done
echo $(cat $TEMP_PACK_NAME_JSON | jq -r "sort_by(.relativeDepencyLength)") >$TEMP_PACK_NAME_JSON

ITEMS=$(echo $(cat $TEMP_PACK_NAME_JSON | jq ".[].name"))

for ITEM in $ITEMS; do
    DIRECTORY=$(cat $TEMP_PACK_NAME_JSON | jq -r ".[] | select( .name==$ITEM) | .directory")
    PKG_FILE="${DIRECTORY}/package.json"
    for ITEM_SECONDARY in $ITEMS; do
        CURRENT_VER_PEER=$(echo $(cat $PKG_FILE | jq -r "(.peerDependencies[$ITEM_SECONDARY])"))
        if [[ $CURRENT_VER_PEER != 'null' && $CURRENT_VER_PEER != 'undefined' ]]; then
            echo $(cat $PKG_FILE | jq -r "(.peerDependencies[$ITEM_SECONDARY] |= \"$VERSION\")") >$PKG_FILE
        fi
        CURRENT_VER_NORMAL=$(echo $(cat $PKG_FILE | jq -r "(.dependencies[$ITEM_SECONDARY])"))
        if [[ $CURRENT_VER_NORMAL != 'null' && $CURRENT_VER_NORMAL != 'undefined' ]]; then
            echo $(cat $PKG_FILE | jq -r "(.dependencies[$ITEM_SECONDARY] |= \"$VERSION\")") >$PKG_FILE
        fi
        CURRENT_VER_DEV=$(echo $(cat $PKG_FILE | jq -r "(.devDependencies[$ITEM_SECONDARY])"))
        if [[ $CURRENT_VER_DEV != 'null' && $CURRENT_VER_DEV != 'undefined' ]]; then
            echo $(cat $PKG_FILE | jq -r "(.devDependencies[$ITEM_SECONDARY] |= \"$VERSION\")") >$PKG_FILE
        fi
        echo $(cat $PKG_FILE | jq "(.version |= \"$VERSION\")") >$PKG_FILE
        CURRENT_DIRECTORY=$DIRECTORY
        cd $DIRECTORY
        git add .
        git commit -m "Version upgraded to $VERSION"
        git push
        npm run build-publish
        cd $CURRENT_DIRECTORY
    done

    #

done
