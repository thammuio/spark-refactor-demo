#!/bin/bash


prompt () {
  if [ -z "$NO_PROMPT" ]; then
    read -p "Press enter to continue:"
  fi
}

########################################################################
# Setting variables for your Upgrade
########################################################################

INITIAL_VERSION=${INITIAL_VERSION:-2.4.8}
TARGET_VERSION=${TARGET_VERSION:-3.3.1}
SCALAFIX_RULES_VERSION=${SCALAFIX_RULES_VERSION:-0.1.9}



########################################################################
# Run scalafix
########################################################################
echo "========================="
echo "Building current project"
echo "========================="

sbt clean compile test package


echo "=================================================="
echo "Adding the scalafix dependency to the project"
echo "=================================================="

cp -af build.sbt build.sbt.bak

cat >> build.sbt <<- EOM
scalafixDependencies in ThisBuild +=
  "com.holdenkarau" %% "spark-scalafix-rules-${INITIAL_VERSION}" % "${SCALAFIX_RULES_VERSION}"
semanticdbEnabled in ThisBuild := true
EOM

mkdir -p project

cat >> project/plugins.sbt <<- EOM
addSbtPlugin("ch.epfl.scala" % "sbt-scalafix" % "0.10.4")
EOM

cp .scalafix.conf.sample .scalafix.conf

echo "=================================================="

prompt

echo "=================================================="
echo "Now we'll try and run the scalafix rules in your project!"
echo "This might FAIL if you have interesting build targets."
echo "=================================================="

sbt scalafix

echo "=================================================="
echo "Now we'll be running the scalafix warning check..."
echo "=================================================="

cp .scalafix-warn.conf.sample .scalafix.conf

sbt scalafix ||     (echo "Linter warnings were found"; prompt)

echo "=================================================="
echo "ScalaFix is COMPLETED, Review the Changes now (e.g. git diff)"
echo "=================================================="

prompt

# We don't run compile test because some changes are not back compat (see value/key change).
# sbt clean compile test package

cp -af build.sbt build.sbt.bak.pre3

cat build.sbt.bak.pre3 | \
  python -c "import re,sys;print(sys.stdin.read().replace(\"${INITIAL_VERSION}\", \"${TARGET_VERSION}\"))" > build.sbt

echo "=================================================="
echo "You will also need to update dependency versions now (e.g. Spark to 3.3 and libs)"
echo "Please address those and then press ENTER to build new $TARGET_VERSION version"
echo "=================================================="

prompt

sbt clean compile test package


