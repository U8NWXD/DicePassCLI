# DicePassCLI: A command-line interface for generating random passphrases
# Copyright (C) 2017 U8N WXD
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Arguments:
#   -l [Number of Words to Include]
#   -b [Bits of Entropy Required]
#   -e for extended version
#   -h for help

# Note that either -l or -b must be supplied and must be >0

echo "DicePassCLI Copyright (C) U8N WXD"
echo "This program comes with ABSOLUTELY NO WARRANTY"
echo "This is free software, and you are welcome to redistribute it"
echo "under the conditions of the Affero General Public License."
echo "License: <http://www.gnu.org/licenses/>"
echo

# Set lengths of wordlists
originalWords=7776
extendedWords=545178

# Reset getopts index variable to 1 so it looks at the first argument
OPTIND=1

# Initialize variables for argument parsing
length=0
bits=0
extended=false

# Parse arguments
# SOURCE: http://wiki.bash-hackers.org/howto/getopts_tutorial
while getopts ":l:eb:h" opt; do
  case $opt in
    l)
      length=$OPTARG
      ;;
    b)
      bits=$OPTARG
      ;;
    e)
      extended=true
      ;;
    h)
      echo "DicePassCLI Usage: ./dicepass.sh [-b [bits] | -l [words]] [-e]"
      echo "-e uses the extended wordlist"
      echo "-h displays this help text"
      exit 0
      ;;
    \?)
      echo "Invalid Option: -$OPTARG"
      echo "Run ./dicepass.sh -h for help"
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument"
      echo "Run ./dicepass.sh -h for help"
      exit 1
      ;;
  esac
done

if (( $# < 1 ))
  then {
    echo "Insufficient options provided. -b or -l required"
    echo "Run ./dicepass.sh -h for help"
    exit 1
  }
fi

# Determine path to data directory based on trial-and-error
# SOURCE: https://stackoverflow.com/questions/59838/check-if-a-directory-exists-in-a-shell-script
if [ -d ~/"Library/Application Support/com.icloud.cs_temporary/DicePassCLI/data" ]
  then dataPath=~/"Library/Application Support/com.icloud.cs_temporary/DicePassCLI/data"
elif [ -d "data" ]
  then dataPath="data"
else {
  echo "ERROR: The 'data' directory containing wordlists cannot be found."
  echo "It can be placed in your current working directory."
  exit 1
}
fi

# Determine path to words file and entropyPerWord based on extended/original choice
if $extended
  then {
    dict=$dataPath/extended.txt
    dictLength=$extendedWords
  } else {
    dict=$dataPath/original.txt
    dictLength=$originalWords
  }
fi
# SOURCE: https://stackoverflow.com/questions/6022384/bash-tool-to-get-nth-line-from-a-file
# SOURCE: http://www.tldp.org/LDP/abs/html/arithexp.html
entropyPerWord=$( echo "scale=10; l($dictLength) / l(2)" | bc -l )

# Check that either bits or length specified
if (( $bits + $length <= 0 ))
  then {
    echo "Invalid Options: Either length (-l) or bits (-b) must be supplied > 0"
    exit 1
  }
fi

# Calculate length needed based on bits requiested
# SOURCE: http://www.tldp.org/LDP/abs/html/comparison-ops.html
if (( $bits > 0 ))
  then length=$( echo "scale=0; $bits / $entropyPerWord + 1" | bc)
fi

# Calculate bits based on length
bitsActual=$( echo "scale=3; $entropyPerWord * $length" | bc )

# Generate and display passphrase
echo -n "Generated Passphrase: "
i=0;
while (( i < $length ))
  do {
    numHex=$( echo "scale=0; l($dictLength) / l(16)" | bc -l )
    index=$dictLength
    while (( $index >= $dictLength ))
      do {
        rand=$(openssl rand -hex $numHex 2>/dev/null )
        rand=$( echo $rand | tr [a-z] [A-Z] )
        index=$( echo "ibase=16; $rand" | BC_LINE_LENGTH=9999999999999 bc )
        if (( $( echo "$index - $dictLength" | bc ) >= $dictLength ))
          then index=$( echo "$index % $dictLength" | bc )
        fi
      }
    done
    word=$(sed "$(BC_LINE_LENGTH=9999999999999 bc <<< $index)q;d" "$dict")
    echo -n "$word "
    let i=i+1
  }
done

# Report entropy of generated passphrase to user
echo
echo "Bits: $bitsActual"

exit 0
