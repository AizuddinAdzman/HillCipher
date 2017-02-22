#!/bin/bash 

# arrayText[] = array of the inserted string
# arrayKey[] = array of the inserted key


# Handle input, ensure if a letter is inserted, it change into numerical.
# Check the inserted key, validation.
checkInput(){
	if ! [[ "$1" =~ ^[0-9]+$  ]]; then
		text=`echo $1 | tr '[:lower:]' '[:upper:]'`
		num=$((`echo  ${text} | od -t d1 | awk '{printf "%s",$2}';` -65))
		return $num
	fi
}

# Convert character into integer; A-0, B-1, C-2....Z-25
charToInt(){
	Cap=`echo $1 | tr '[:lower:]' '[:upper:]'`
	int=$((`echo $Cap | od -t d1 | awk '{printf "%s",$2}';` -65))
	return $int
}

# Perform mod 26 because total character accepted is 26
mod26(){
	int=$1
	# modulo negative integer
	if [[ $int -lt 0 ]]; then
		while [[ $int -lt 0 ]]; do
			let int=$int+26
		done
	# mod 26 positive integer
	elif [[ $int -gt 25 ]]; then
		let int=$int%26
	fi
	return $int
}

# Find the inverse of determinant dor decryption. inverseDeterminant = 1/(ad-bc)
inverseDeterminant(){
	int=$1
	counter=0
	# multiplicative inverse
	mulInverse=$int*$counter
	# inverse determinant
	inDet=$mulInverse%26

	while [[ $inDet -ne 1 ]]; do
		((counter++))
		mulInverse=$int*$counter
		inDet=$mulInverse%26
	done

	return $counter
}

# To print matrix special-design for key.
DisplayMatrix(){
	a=("$@")
	echo "[ " ${a[0]} "  " ${a[1]} " ]"
	echo "[ " ${a[2]} "  " ${a[3]} " ]"
}

# Print normal matrix; for the text, ciphertext, decrypted text.
DisplayTextMatrix(){
	a=("$@")
	text=${#a[@]}

	space(){
		count=$1
		if [[ count -gt 9 ]]; then
			echo -n "   "
		elif [[ count -gt 99 ]]; then
			echo -n " "
		elif [[ count -gt -1 ]]; then
			echo -n "    "
		fi
	}

	if ! [[ "${a[@]}" =~ ^[0-9]+$  ]]; then
		echo -n "[  " 
		for (( i = 0; i < $text; i++ )); do
			echo -n ${a[$i]} "  "
			((i++))
		done
		echo "]"
		echo -n "[  " 
		for (( i = 1; i <= $text; i++ )); do
			echo -n ${a[$i]} "  "
			((i++))
		done
		echo "]"
	else
		echo -n "[  " 
		for (( i = 0; i < $text; i++ )); do
			echo -n ${a[$i]} 
			space ${a[$i]} 
			((i++))
		done
		echo "]"
		echo -n "[  " 
		for (( i = 1; i <= $text; i++ )); do
			echo -n ${a[$i]}
			space ${a[$i]} 
			((i++))
		done
		echo "]"
	fi
}

MultiplyMatrix(){
	key=("$@")

	let m=${key[0]}*$5
	let n=${key[1]}*$6
	let k=$m+$n

	let p=${key[2]}*$5
	let q=${key[3]}*$6
	let l=$p+$q

	temp=($k $l)
}

Start_hill_cipher(){
	clear
	echo "--------------------- Hill Cipher ------------------------"
	echo 

	echo "Input key as in [a, b, c, d] in numerical: [ a  b ]"
	echo "                                           [ c  d ]" 

	for (( i = 0; i < 4; i++ )); do
		l=`printf "\x$(printf %x $(($i+65)))"`
		j=`echo $l | tr '[:upper:]' '[:lower:]'`
		echo -n $j": "

		read input
		if ! [[ "$input" =~ ^[0-9]+$  ]]; then
			checkInput $input
			mapped=$?
			input=$mapped
		fi
		arrayKey[$i]=$input
	done

	# Print all arrayKey[] element
	echo "Key entered: "
	DisplayMatrix ${arrayKey[*]}

	echo 
	echo "Press 'h' to perform full hill cipher."
	echo "Press 'e' for encryption only."
	echo "Press 'd' for decryption only."
	
	Process=0
	while [[ Process -eq 0 ]]; do
		echo -n "Select: "
		read functionPerform
		if [[ $functionPerform == "h" || $functionPerform == "e" || $functionPerform == "d" ]]; then
			((Process++))
		else
			echo "That's not in the option!"
		fi
	done
	echo 

	# ---------- Choose to read message from a text file or enter the text ------
	echo "Do you want to read from a file or enter the text (f/t): "
	read choice
	choice=`echo $choice | tr '[:upper:]' '[:lower:]'`

	while [[ $choice != "t" && $choice != "f" ]]; do
		echo -n "Please re-enter your choice: "
		read choice
		choice=`echo $choice | tr '[:upper:]' '[:lower:]'`
	done

	if [[ $choice == "f" ]]; then
		echo -n "Please enter you filename. Format: /home/<username>/...": 
		IFS=' '
		read filename
		while [[ ! -f "$filename" ]]; do
			echo "File not found. Please re-enter your file's path: (Format: /home/<username>/...): "
			read filename
		done
		string=`cat $filename`
	elif [[ $choice == "t" ]]; then
		echo -n "Input string: "
		read string
	fi

	#Standardize the text: Uppercase all letters, delete all special characters and remove white spaces
	TEXT=`echo $string | tr '[:lower:]' '[:upper:]' | tr -d [:punct:] | tr -d [:blank:]`
	totalText=${#TEXT}

	#Assign the Text into the array, arrayText[]
	for (( i = 0; i < ${#TEXT}; i++ )); do
		arrayText[$i]="${TEXT:$i:1}";
	done
	
	# if the text is not even number, line below will add extra character: "Q"
	if [[ $totalText%2 -eq 1 ]]; then
		let arrayText[${#TEXT}]="Q"
	fi

	# Print the original text.
	echo "Matrix: "
	DisplayTextMatrix ${arrayText[@]}
	echo

	#Translate the Text into numerical and swap the value into the array
	for (( i = 0; i < ${#arrayText[@]}; i++ )); do
		charToInt ${arrayText[$i]}
		mapped=$?
		arrayText[$i]=$mapped
	done

	if [[ $functionPerform == "h" ]]; then
		echo 
		echo " Encryption start: --------------------------------"
		echo " Step 1: Multiplying matrices."
		echo

		echo "Cipher text = Key * Plaintext: "
		echo "Key: "
		DisplayMatrix ${arrayKey[*]}

		echo "Text (integer) matrix: "
		DisplayTextMatrix ${arrayText[@]} 
	
				# Multiply key * matrices.
		for (( i = 0; i < ${#arrayText[@]}; i++ )); do
			MultiplyMatrix ${arrayKey[@]} ${arrayText[$i]} ${arrayText[$(($i+1))]}
			arrayCipher[$i]=${temp[0]}
			((i++))
			arrayCipher[$i]=${temp[1]}
		done

		# Print all the cipher text (number); the array; arrayCipher[]
		# The result after multiplying
		echo "----------------------------"
		DisplayTextMatrix ${arrayCipher[@]}
		echo "----------------------------"
		echo

		echo " Step 2: [Matrix] Mod 26 ---------"

		# Perform mod 26 to all the number in the array.
		for (( i = 0; i < ${#arrayCipher[@]}; i++ )); do
		 	mod26 ${arrayCipher[$i]}
		 	mapped=$?
		 	arrayCipher[$i]=$mapped
		done 

		# Print the array of the cipher (number) after mod 26.
		echo "Array of ciphered-text (after mod26): "
		DisplayTextMatrix ${arrayCipher[@]} 
		echo

		echo " Step 3: Convert int->char: "
		# Translate the number into alphabet.
		for (( i = 0; i < ${#arrayCipher[@]}; i++ )); do
			p=${arrayCipher[$i]}
			l=`printf "\x$(printf %x $(($p+65)))"`
			arrayCipher[$i]=$l
		done

		# Print the array of cipher text (letter); after translated into alphabet.
		echo "Array of ciphered-text (translated): "
		DisplayTextMatrix ${arrayCipher[@]}
		echo
		echo -n "Cipher text: "
		for (( i = 0; i < ${#arrayCipher[@]}; i++ )); do
		 	echo -n "${arrayCipher[$i]}, "
		done 
		echo
 
		echo 
		echo " Decryption start:   --------------------------------"
	
		# inverse key -------------------------------|
		let x=${arrayKey[0]}*${arrayKey[3]}
		let y=${arrayKey[1]}*${arrayKey[2]}
		let a=$x-$y

		if [[ $a -lt 0 || $a -gt 26 ]]; then
			mod26 $a
			mapped=$?
			a=$mapped
		fi

		# Refer at crypto.interactive-maths.com
		# To find the inverse determinant
		inverseDeterminant $a
		mapped=$?
		A=$mapped

		let arrayInverseKey[0]=${arrayKey[3]}*A
		let arrayInverseKey[3]=${arrayKey[0]}*A
		let arrayInverseKey[1]=${arrayKey[1]}*-1
		let arrayInverseKey[2]=${arrayKey[2]}*-1

		for (( i = 1; i < 3; i++ )); do
			mod26 ${arrayInverseKey[$i]}
			mapped=$?
			arrayInverseKey[$i]=$mapped*$A
		done


		for (( i = 0; i < 4; i++ )); do
			mod26 ${arrayInverseKey[$i]}
			mapped=$?
			arrayInverseKey[$i]=$mapped
		done

		echo " Step 1: Inverse key."
		DisplayMatrix ${arrayInverseKey[@]}
		echo
		# ----------------------------------------|
		# ---------- Mulitply matrix with inversed key ----------------

		# Print the array of cipher text (letter); after translated into alphabet.
		echo "Cipher (letter) array: "
		DisplayTextMatrix ${arrayCipher[@]}

		echo " Step 2: Conver char->int."
		#Translate the Text into numerical and swap the value into the array
		for (( i = 0; i < ${#arrayCipher[@]}; i++ )); do
			charToInt ${arrayCipher[$i]}
			mapped=$?
			arrayCipher[$i]=$mapped
		done

		# Print the array of cipher text (letter); after translated into alphabet.
		echo "Cipher (int) array: "
		DisplayTextMatrix ${arrayCipher[@]} 
		echo

		# Inverse key * cipher matrix:
		# Multiply key * matrices.
		for (( i = 0; i < ${#arrayCipher[@]}; i++ )); do
			MultiplyMatrix ${arrayInverseKey[@]} ${arrayCipher[$i]} ${arrayCipher[$(($i+1))]}
			arrayCipherDecrypt[$i]=${temp[0]}
			((i++))
			arrayCipherDecrypt[$i]=${temp[1]}
		done

		echo " Step 3: Multiply inversekey * ciphertext"
		DisplayTextMatrix ${arrayCipherDecrypt[@]} 
		echo

		echo " Step 4: [Matrix] Mod 26"
		# Perform mod 26 to the decrypted array.
		for (( i = 0; i < ${#arrayCipher[@]}; i++ )); do
			mod26 ${arrayCipherDecrypt[$i]}
			mapped=$?
			arrayCipherDecrypt[$i]=$mapped
		done
		DisplayTextMatrix ${arrayCipherDecrypt[@]}
		echo

		echo " Step 5: Convert int -> char."
		# Translate the number into alphabet.
		for (( i = 0; i < ${#arrayCipherDecrypt[@]}; i++ )); do
			p=${arrayCipherDecrypt[$i]}
			l=`printf "\x$(printf %x $(($p+65)))"`
			arrayCipherDecrypt[$i]=$l
		done

		echo "Cipher text after decrypted: "  
		DisplayTextMatrix ${arrayCipherDecrypt[@]}
		echo
		echo -n "Decrypted text: "
		for (( i = 0; i < ${#arrayCipherDecrypt[@]}; i++ )); do
		 	echo -n "${arrayCipherDecrypt[$i]}, "
		done 
		echo
	elif [[ $functionPerform == "e" ]]; then
		echo 
		echo " Encryption start: --------------------------------"
		echo " Step 1: Multiplying matrices."
		echo

		echo "Cipher text = Key * Plaintext: "
		echo "Key: "
		DisplayMatrix ${arrayKey[*]}

		echo "Text (integer) matrix: "
		DisplayTextMatrix ${arrayText[@]} 
	
		# Multiply key * matrices.
		for (( i = 0; i < ${#arrayText[@]}; i++ )); do
			MultiplyMatrix ${arrayKey[@]} ${arrayText[$i]} ${arrayText[$(($i+1))]}
			arrayCipher[$i]=${temp[0]}
			((i++))
			arrayCipher[$i]=${temp[1]}
		done

		# Print all the cipher text (number); the array; arrayCipher[]
		echo "----------------------------"
		DisplayTextMatrix ${arrayCipher[@]}
		echo "----------------------------"
		echo

		echo " Step 2: [Matrix] Mod 26 ---------"

		# Perform mod 26 to all the number in the array.
		for (( i = 0; i < ${#arrayCipher[@]}; i++ )); do
		 	mod26 ${arrayCipher[$i]}
		 	mapped=$?
		 	arrayCipher[$i]=$mapped
		done 

		# Print the array of the cipher (number) after mod 26.
		echo "Array of ciphered-text (after mod26): "
		DisplayTextMatrix ${arrayCipher[@]} 
		echo

		echo " Step 3: Convert int->char: "
		# Translate the number into alphabet.
		for (( i = 0; i < ${#arrayCipher[@]}; i++ )); do
			p=${arrayCipher[$i]}
			l=`printf "\x$(printf %x $(($p+65)))"`
			arrayCipher[$i]=$l
		done

		# Print the array of cipher text (letter); after translated into alphabet.
		echo "Array of ciphered-text (translated): "
		DisplayTextMatrix ${arrayCipher[@]}
		echo
		echo -n "Cipher text: "
		for (( i = 0; i < ${#arrayCipher[@]}; i++ )); do
		 	echo -n "${arrayCipher[$i]}, "
		done 
		echo
	elif [[ $functionPerform == "d" ]]; then
		echo 
		echo " Decryption start:   --------------------------------"
	
		# inverse key -------------------------------|
		let x=${arrayKey[0]}*${arrayKey[3]}
		let y=${arrayKey[1]}*${arrayKey[2]}
		let a=$x-$y

		if [[ $a -lt 0 || $a -gt 26 ]]; then
			mod26 $a
			mapped=$?
			a=$mapped
		fi

		# Refer at crypto.interactive-maths.com
		# To find the inverse determinant
		inverseDeterminant $a
		mapped=$?
		A=$mapped

		let arrayInverseKey[0]=${arrayKey[3]}*A
		let arrayInverseKey[3]=${arrayKey[0]}*A
		let arrayInverseKey[1]=${arrayKey[1]}*-1
		let arrayInverseKey[2]=${arrayKey[2]}*-1

		for (( i = 1; i < 3; i++ )); do
			mod26 ${arrayInverseKey[$i]}
			mapped=$?
			arrayInverseKey[$i]=$mapped*$A
		done


		for (( i = 0; i < 4; i++ )); do
			mod26 ${arrayInverseKey[$i]}
			mapped=$?
			arrayInverseKey[$i]=$mapped
		done

		echo " Step 1: Inverse key."
		DisplayMatrix ${arrayInverseKey[@]}
		echo
		# ----------------------------------------|
		# ---------- Mulitply matrix with inversed key ----------------
		echo " Step 2: Conver char->int."
		# Print the array of cipher text (letter); after translated into alphabet.
		echo "Cipher (int) array: "
		DisplayTextMatrix ${arrayText[@]} 
		echo

		# Inverse key * cipher matrix:
		# Multiply key * matrices.
		for (( i = 0; i < ${#arrayText[@]}; i++ )); do
			MultiplyMatrix ${arrayInverseKey[@]} ${arrayText[$i]} ${arrayText[$(($i+1))]}
			arrayCipherDecrypt[$i]=${temp[0]}
			((i++))
			arrayCipherDecrypt[$i]=${temp[1]}
		done

		echo " Step 3: Multiply inversekey * ciphertext"
		DisplayTextMatrix ${arrayCipherDecrypt[@]} 
		echo

		echo " Step 4: [Matrix] Mod 26"
		# Perform mod 26 to the decrypted array.
		for (( i = 0; i < ${#arrayText[@]}; i++ )); do
			mod26 ${arrayCipherDecrypt[$i]}
			mapped=$?
			arrayCipherDecrypt[$i]=$mapped
		done
		DisplayTextMatrix ${arrayCipherDecrypt[@]}
		echo

		echo " Step 5: Convert int -> char."
		# Translate the number into alphabet.
		for (( i = 0; i < ${#arrayCipherDecrypt[@]}; i++ )); do
			p=${arrayCipherDecrypt[$i]}
			l=`printf "\x$(printf %x $(($p+65)))"`
			arrayCipherDecrypt[$i]=$l
		done

		echo "Cipher text after decrypted: "  
		DisplayTextMatrix ${arrayCipherDecrypt[@]}
		echo
		echo -n "Decrypted text: "
		for (( i = 0; i < ${#arrayCipherDecrypt[@]}; i++ )); do
		 	echo -n "${arrayCipherDecrypt[$i]}, "
		done 
		echo
	fi

	if [[ $functionPerform == "e" ]]; then
		echo -n "Do you want to save the encrypted text (y/n): "
		read answer
	fi

}

loop=0
while [[ loop -eq 0 ]]; do
	Start_hill_cipher

	echo 
	echo "Run again? (y/n):"
	read r

	if [[ r == "n" ]]; then
		((loop++))
	fi
done
