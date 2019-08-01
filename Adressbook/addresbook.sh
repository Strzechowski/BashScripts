#!/bin/bash

addressesFile="Adresses"
parameterArray=("Name" "Surname" "Phone" "Email")

readFromUser() {
  echo "Please provide $1" >&2
  read input
  if [ -z "${input}" ] ; then 
    echo "$1 can not be empty." >&2
    readFromUser $1
  fi
  echo "$input"
}

add() {
  name=$(readFromUser Name)
  surname=$(readFromUser Surname)
  number=$(readFromUser Number)
  email=$(readFromUser Email)

  echo "$name $surname $number $email" >> "${addressesFile}"
}

search() {
  #There is a bug 
  #You are searching not only name and surname but all line
  echo "Provide Name and Surname of a Person you are looking for:" >&2
  read who
  
  list=$(grep -n "$who" "$addressesFile") 
  numOfLineInFile=$(echo "$list" | cut -f1 -d':')
  hits=$(echo "$list" | wc -l)
 
  if [ -z "$list" ] ; then 
    echo "Haven't found anyone. Try Again." >&2
    search
  elif [ $hits -gt 1 ] ; then
    echo "Found more than one person. Try Again." >&2
    echo "$list" | cut -f2 -d':' | cut -f1,2 -d' ' >&2
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
  sed -i "${lineToRemove}d" "${addressesFile}" 
}

edit() {
  display $1
  edit=($(display $1))
  for (( i = 0; i < ${#edit[@]}; i++)) ; do
    echo "${parameterArray[i]}: ${edit[i]}"
    echo "Do you want to change this parameter? [ N/n to pass ]" 
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

editWithSearch() {
  lineToEdit=$(search)
  edit $lineToEdit 
}

removeWithSearch() {
  lineToRemove=$(search)
  remove $lineToRemove
}

searchAndDisplay() {
  lineToDisplay=$(search)
  display $lineToDisplay
}

check="false"
while [ "$check" == "false" ]; do
  echo 
  echo "Co wybierasz?"
  select answer in "Dodawanie" "Wyszukiwanie" "Edytowanie" "Usuwanie" "Wyjscie"
  do
    case $answer in
      "Dodawanie") add; break ;;
      "Wyszukiwanie") searchAndDisplay; break ;;   
      "Edytowanie") editWithSearch; break ;;
      "Usuwanie") removeWithSearch; break ;;
      "Wyjscie") check="true"
    esac
  done
done
