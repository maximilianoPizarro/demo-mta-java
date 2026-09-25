#!/bin/bash
# Run a command with JDK 8. Dev Spaces UDI defaults to a newer JDK, which
# cannot compile sun.misc.BASE64Encoder even with -source 1.8.
set -euo pipefail

java8_home() {
  if [ -d /usr/lib/jvm/java-1.8.0-openjdk ]; then
    echo /usr/lib/jvm/java-1.8.0-openjdk
  elif [ -d /usr/lib/jvm/java-1.8.0 ]; then
    echo /usr/lib/jvm/java-1.8.0
  fi
}

home="$(java8_home || true)"
if [ -z "${home}" ]; then
  echo "Installing java-1.8.0-openjdk-devel..."
  if command -v microdnf >/dev/null 2>&1; then
    sudo microdnf install -y java-1.8.0-openjdk-devel
  else
    sudo dnf install -y java-1.8.0-openjdk-devel
  fi
  home="$(java8_home)"
fi

export JAVA_HOME="${home}"
export PATH="${JAVA_HOME}/bin:${PATH}"
echo "Using ${JAVA_HOME}"
java -version
exec "$@"
