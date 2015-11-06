#!/bin/sh
#
# The MIT License (MIT)
#
# Copyright (c) 2015 Jeffrey Hutchins
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

# enable debug mode
if [ "$DEBUG" = "yes" ]
then
	set -x
    OUTPUT=''
else
    OUTPUT=">> /dev/null 2>&1"
fi

BASE=$PWD
PATH=$PATH:$PWD
RESULT=0
SUCCESS=0
FAILURE=0

setup_repo() {
    git clone remote $1
    cd $1
    git config --local user.email "you@example.com"
    git config --local user.name "Your Name"
    cd ..
}

setup() {
    mkdir test
    cd test

    # Create "remote"
    mkdir remote
    cd remote
    git init --bare
    cd ..

    # Create different contrib repos
    setup_repo "clone1"
    setup_repo "clone2"
}

assert_equal() {
    if [ "$1" != "$2" ]
    then
        echo "\"$1\" != \"$2\""
        return 1
    fi
}

assert_failed() {
    if [ $? -eq 0 ]
    then
        return 1
    fi
}

assert_success() {
    if [ $? -gt 0 ]
    then
        return 1
    fi
}

teardown() {
    cd $BASE
    rm -rf test
}

run_test() {
    local str="Testing $1"
    printf "$str"
    local cnt=$(expr 24 - ${#str})
    while [ $cnt -gt 0 ]; do
        printf " "
        cnt=$[cnt-1]
    done
    setup >> /dev/null 2>&1
    $1
    if [ $? != 0 ]
    then
        printf " [failure]\n"
        RESULT=1
        FAILURE=$[FAILURE + 1]
    else
        printf " [success]\n"
        SUCCESS=$[SUCCESS + 1]
    fi
    teardown >> /dev/null 2>&1
}

simple_conflict_setup() {
    cd clone1

    echo "a" >> a
    git add a
    git commit -am "Add a"
    git push

    cd ../clone2
    git pull

    echo "b" > b
    git add b
    git commit -am "Add b"
    git push

    cd ../clone1

    echo "c" > c
    git add c
    git commit -am "Add c"
    git push
}

simple_conflict() {
    simple_conflict_setup >> /dev/null 2>&1
    assert_failed || return 1
    git rebase-push >> /dev/null 2>&1
    assert_success
}

complex_conflict_setup() {
    cd clone1

    echo "a" >> a
    git add a
    git commit -am "Add a"
    git push

    cd ../clone2
    git pull

    echo "b" >> a
    git add a
    git commit -am "Modify a"
    git push

    cd ../clone1

    echo "c" >> a
    git add a
    git commit -am "Modify a"
    git push
}

complex_conflict() {
    complex_conflict_setup >> /dev/null 2>&1
    assert_failed || return 1
    git rebase-push >> /dev/null 2>&1 <<DONE
cat a | egrep -v '^(<<<|===|>>>)' > a.bak
mv a.bak a
git add a
git rebase --continue
DONE
    assert_success
}

run_test "simple_conflict"
run_test "complex_conflict"

echo
echo "Testing finished"
echo "    successes=$SUCCESS"
echo "    failures=$FAILURE"

exit $RESULT
