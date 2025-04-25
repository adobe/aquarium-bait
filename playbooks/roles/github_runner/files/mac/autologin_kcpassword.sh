#!/bin/bash
# kcpasswordEncode (20210911) Copyright (c) 2021 Joel Bruner (https://github.com/brunerd)
# Licensed under the MIT License
# From: https://gist.github.com/brunerd/d60343434a8a5121db423bf21025ea66

#given a string creates data for /etc/kcpassword
function kcpasswordCreate {

    #ascii string
    local thisString="${1}"
    local i

    #macOS cipher hex ascii representation array
    local cipherHex_array=( 7D 89 52 23 D2 BC DD EA A3 B9 1F )

    #converted to hex representation with spaces
    local thisStringHex_array=( $(echo -n "${thisString}" | xxd -p -u | sed 's/../& /g') )

    #get padding by subtraction if under 12
    if [ "${#thisStringHex_array[@]}" -lt 12  ]; then
        local padding=$(( 12 -  ${#thisStringHex_array[@]} ))
    #get padding by subtracting remainder of modulo 12 if over 12
    elif [ "$(( ${#thisStringHex_array[@]} % 12 ))" -ne 0  ]; then
        local padding=$(( (12 - ${#thisStringHex_array[@]} % 12) ))
    #otherwise even multiples of 12 still need 12 padding
    else
        local padding=12
    fi

    #cycle through each element of the array + padding
    for ((i=0; i < $(( ${#thisStringHex_array[@]} + ${padding})); i++)); do
        #use modulus to loop through the cipher array elements
        local charHex_cipher=${cipherHex_array[$(( $i % 11 ))]}

        #get the current hex representation element
        local charHex=${thisStringHex_array[$i]}

        #use $(( shell Aritmethic )) to ^ XOR the two 0x## values (extra padding is 0x00)
        #take decimal value and printf convert to two char hex value
        #use xxd to convert hex to actual value and append to the encodedString variable
        local encodedString+=$(printf "%02X" "$(( 0x${charHex_cipher} ^ 0x${charHex:-00} ))" | xxd -r -p)
    done

    #create the kcpassord file
    echo -n "${encodedString}" > /etc/kcpassword
}

read password
kcpasswordCreate "$password"
