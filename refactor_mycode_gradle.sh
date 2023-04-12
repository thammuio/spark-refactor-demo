#!/bin/bash


prompt () {
  if [ -z "$NO_PROMPT" ]; then
    echo $'\n\n\n'
    read -p "$1. Press enter to continue:"
  fi
}


gradle clean

########################################################################
# Define variables
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

gradle clean test jar


echo "=================================================="
echo "Adding the scalafix dependency to the project"
echo "=================================================="


cp build.gradle build.gradle.bak

cp gradle.properties gradle.properties.bak

cp settings.gradle settings.gradle.bak

cat build.gradle.bak | \
    python update_gradle_build.py  > build.gradle


#Copy scalafix
cp .scalafix.conf.sample .scalafix.conf

echo "=================================================="

prompt "Setup for scalafix complete"

echo "=================================================="
echo "Now we'll try and run the scalafix rules in your project!"
echo "This might FAIL if you have interesting build targets."
echo "=================================================="

gradle scalafix #|| (echo "Linter warnings were found"; prompt)

cp .scalafix-warn.conf.sample .scalafix.conf

gradle scalafix ||     (echo "Linter warnings were found"; prompt)

echo "=================================================="
echo "ScalaFix is COMPLETED, Review the Changes now (e.g. git diff)"
echo "=================================================="

prompt "Scalafix run complete"

echo "=================================================="
echo "You will also need to update dependency versions now (e.g. Spark to 3.3 and libs)"
echo "Please address those and then press ENTER to build new $TARGET_VERSION version"
echo "=================================================="

prompt "Build file setup done. Next, we will build a jar"

gradle jar

prompt "Jar has been built. Check build/libs for the jar"
