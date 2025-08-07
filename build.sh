#!/bin/bash

set -ex

dart run flutter_launcher_icons
flutter build apk --release
flutter install --release -d WKPRHMCY49SKIRHA