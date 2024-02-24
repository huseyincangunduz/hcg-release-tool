# Release Tool

The release tool for releasing UBS MONA (or the npm projects in future of UBS or other things) libraries.

This script orders by length of the related dependencies and then runs build-publish command on npm

## Usage

./release-tool.sh verX.X.X directories...

```bash
./release-tool.sh ver1.1.2 ../umona-parted/users-mona-roles ../umona-parted/users-common ../umona-parted/nest-microservice-setup-util ../umona-parted/users-mona-microservice-helper
```
