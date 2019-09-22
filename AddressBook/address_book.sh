#!/usr/bin/env bash

#global variables
addressesFile="Addresses"
parameterArray=("Name" "Surname" "Number" "Email")
cliVersion="false"

readFromUser() {
  # $1 --- what user is prompted to type
  # $2 --- pattern that should be matched by user
  echo -n "Please provide $1: " >&2
  read input
  if [ -z "${input}" ] ; then
    echo "$1 can not be empty." >&2
    readFromUser $1 $2
  fi

  if ! [[ $input =~ $2  ]] ; then
    echo "Wrong $1 pattern. Try again." >&2
    readFromUser $1 $2
  else
    echo "$input"
  fi
}

add() {
  #patterns for user input checking
  lettersOnly='[A-Za-z]+'
  numbersOnly='[1-9]+'
  lettersNumbersDots='[1-9A-Za-z.]+'
  emailPattern="${lettersNumbersDots}@${lettersNumbersDots}"

  if [ "$cliVersion" == "false" ] ; then
    name=$(readFromUser "Name" "^$lettersOnly$")
    surname=$(readFromUser "Surname" "^$lettersOnly$")
    number=$(readFromUser "Number" "^$numbersOnly$")
    email=$(readFromUser "Email" "^$emailPattern$")

    echo "$name $surname $number $email" >> "${addressesFile}"
  else
    person="$1"
    personPattern="^${lettersOnly} ${lettersOnly} ${numbersOnly} ${emailPattern}$"

    if [[ $person =~ $personPattern ]] ; then
      echo "$person" >> "${addressesFile}"
    else
      echo "Person you want to add does not match a pattern." >&2
      echo "Pattern is: \"Name Surname Phone Email\"" >&2
      echo "Closing the program" >&2
      exit 1
    fi
  fi
}

search() {
  if [ -z "$1" ] ; then
    echo >&2
    echo -n "Provide Name and Surname of a Person you are looking for: " >&2
    read who
  else
    who="$1"
  fi

  list=$(awk '{print $1,$2}' "$addressesFile" | grep -n "$who")
  numOfLineInFile=$(echo "$list" | cut -f1 -d':')
  hits=$(echo "$list" | wc -l)

  if [ -z "$list" ] ; then
    echo "### Haven't found anyone. Try Again. ###" >&2

    if [ "$cliVersion" == "false" ] ; then
      search
    else
      exit 1
    fi
  elif [ $hits -gt 1 ] ; then
    echo "### Found more than one person: ###" >&2
    echo "$list" | cut -f2 -d':' >&2
    echo "### TRY AGAIN ###." >&2

    if [ "$cliVersion" == "false" ] ; then
      search
    else
      exit 1
    fi
  else
    echo "$numOfLineInFile"
  fi
}

display() {
  lineToDisplay=${1}
  sed -n ${lineToDisplay}p "${addressesFile}"
}

remove() {
  lineToRemove=${1}

  sed -i "${lineToRemove}d" "${addressesFile}"
}

removeAndPrompt() {
  lineToRemove=${1}
  display $lineToRemove

  echo -n "Are you sure you want to remove this person? [Y/y to accept]: " >&2
  answer=N
  read answer
  answer="Y"
  if [ "$answer" = "Y" ] || [ "$answer" = "y" ]; then
    remove $lineToRemove
  fi
}


edit() {
  echo -n "Person you will be editing: "
  display $1
  personToBeEdited=$(display $1)
  edit=($personToBeEdited)
  for (( i = 0; i < ${#edit[@]}; i++)) ; do
    echo "${parameterArray[i]}: ${edit[i]}"
    echo -n "Do you want to change this parameter? [ N/n to pass ]: "
    answer=Y
    read answer

    if [ "$answer" != "N" ] && [ "$answer" != "n" ] ; then
      new=$(readFromUser ${parameterArray[i]})
      edit[i]=$new
    fi
  done

  echo
  echo "Do you want to overwrite this person: $personToBeEdited"
  echo "With: ${edit[*]}"
  echo "[ N/n to pass ]:"
  answer=Y
  read answer

  if [ "$answer" != "N" ] && [ "$answer" != "n" ] ; then
    sed -i "${1}i ${edit[*]}" "${addressesFile}"
    remove $(($1+1))
  fi
}

searchAndEdit() {
  lineToEdit=$(search)
  edit $lineToEdit
}

searchAndRemove() {
  lineToRemove=$(search "$1")

  if [ -z "$lineToRemove" ] ; then
    exit 1
  else
    if [ "$cliVersion" == "false" ] ; then
      echo
      echo "Found: "
      removeAndPrompt $lineToRemove
    else
      remove $lineToRemove
    fi
  fi
}

searchAndDisplay() {
  lineToDisplay=$(search $1)

  if [ -z "$lineToDisplay" ] ; then
    exit 1
  else
    echo
    echo "Found: "
    display $lineToDisplay
  fi
}

interface() {
check="false"
while [ "$check" == "false" ]; do
  echo
  echo "What do you select?"
  select answer in "Add" "Search" "Edit" "Remove" "Exit"
  do
    case $answer in
      "Add") add; break ;;
      "Search") searchAndDisplay; break ;;
      "Edit") searchAndEdit; break ;;
      "Remove") searchAndRemove; break ;;
      "Exit") check="true"; break ;;
    esac
  done
done
}

usage() {
echo -e "
Usage: ./test -i
              -a \"Name Surname Phone Email\"
              -r \"Name Surname\"
              -s \"Name Surname\"
              -h

    no arguments --- turns on user interface
              -i --- turns on user interface
              -a --- add a person
              -r --- remove a person by his/her name and surname
              -s --- search a person by his/her name and surname
              -h --- display this help window

There is no edit option in CLI Version, because it would become to meesy.
Just combine remove and add options.
" >&2
}


if [ -z $1 ] ;then
  interface
else
  cliVersion="true"
fi

while getopts 'a:r:s:hi' OPTION; do
  case "$OPTION" in
    a)
      add "$OPTARG"
      ;;
    r)
      searchAndRemove "$OPTARG"
      ;;
    s)
      searchAndDisplay "$OPTARG"
      ;;
    h)
      usage
      ;;
    i)
      interface
      ;;
    ?)
      usage
      exit 1
      ;;
  esac
done
shift "$(($OPTIND -1))"
