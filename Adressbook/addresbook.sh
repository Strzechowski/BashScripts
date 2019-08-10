#!/usr/bin/env bash

#global variables
addressesFile="Adresses"
parameterArray=("Name" "Surname" "Number" "Email")

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
  lettersOnly='^[A-Za-z]+$'
  numbersOnly='^[1-9]+$'
  lettersNumbersDots='[1-9A-Za-z.]+'
  emailPattern="^${lettersNumbersDots}@${lettersNumbersDots}$"

  name=$(readFromUser "Name" "$lettersOnly")

  surname=$(readFromUser "Surname" "$lettersOnly")

  number=$(readFromUser "Number" "$numbersOnly")

  email=$(readFromUser "Email" "$emailPattern")

  echo "$name $surname $number $email" >> "${addressesFile}"
}

search() {
  echo >&2
  echo -n "Provide Name and Surname of a Person you are looking for: " >&2
  read who
  
  list=$(awk '{print $1,$2}' "$addressesFile" | grep -n "$who")
  numOfLineInFile=$(echo "$list" | cut -f1 -d':')
  hits=$(echo "$list" | wc -l)
 
  if [ -z "$list" ] ; then 
    echo "### Haven't found anyone. Try Again. ###" >&2
    search
  elif [ $hits -gt 1 ] ; then
    echo "### Found more than one person: ###" >&2
    echo "$list" | cut -f2 -d':' >&2
    echo "### TRY AGAIN ###." >&2 
    search
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
  display $lineToRemove
  echo -n "Are you sure you want to remove this person? [Y/y]: " >&2
  answer=N
  read answer
  if [ "$answer" = "Y" ] || [ "$answer" = "y" ]; then
    sed -i "${lineToRemove}d" "${addressesFile}" 
    echo "Removed" >&2
  fi
}

edit() {
  display $1
  edit=($(display $1))
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
  
  sed -i "${1}i ${edit[*]}" "${addressesFile}" 
  remove $(($1+1))
}

searchAndEdit() {
  lineToEdit=$(search)
  edit $lineToEdit 
}

searchAndRemove() {
  lineToRemove=$(search)
  remove $lineToRemove
}

searchAndDisplay() {
  lineToDisplay=$(search)
  echo
  echo "Found: "
  display $lineToDisplay
}

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
