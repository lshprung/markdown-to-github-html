#!/usr/bin/bash

NAME="$0"
CSS_LINK_DIR="https://raw.githubusercontent.com/sindresorhus/github-markdown-css/main"
CSS_PATH=("./github-markdown-light.css")
CUSTOM_CSS_PATH=0
INPUT="/dev/stdin"
CUSTOM_INPUT=0
OUTPUT="/dev/stdout"
CUSTOM_OUTPUT=0
COMPILER="marked --gfm"
ENABLE_JS=0 #Set to 1 for --highlight flag
THEME="light"     
YES=0       #Set to 1 for --yes flag

print_help() {
	echo "Usage: $NAME [OPTION]... [INPUT]"
	echo "Compile INPUT markdown file to github-styled html"
	echo ""
	echo "      --compiler COMPILER	set the markdown compiler to use. Default is marked --gfm"
	echo "  -c, --css CSS_PATH		set the github-markdown.css file path (by default github-markdown-light.css in the CWD). This option can be invoked multiple times for multiple css links"
	echo "  -h, --help			print this help message"
	echo "      --highlight 		enable highlight.js support for code blocks (uses cdnjs as source)"
	echo "  -i, --input INPUT		specify INPUT file"
	echo "  -o, --output OUTPUT		output to specified OUTPUT file"
	echo "  -t, --theme light|dark	Set whether the css theme should match github light or dark mode (default is light)"
	echo "  -y, --yes 			automatic yes to prompts"
}

# Parse arguments
while [ $# -gt 0 ]; do
	case $1 in
		--compiler)
			COMPILER="$2"
			shift 2
			;;
		-c | --css)
			if [ $CUSTOM_CSS_PATH -eq 1 ]; then
				CSS_PATH+=("$2")
			else
				CSS_PATH=("$2")
				CUSTOM_CSS_PATH=1
			fi
			shift 2
			;;
		-h | --help)
			print_help
			exit 1
			;;
		--highlight)
			ENABLE_JS=1
			shift
			;;
		-i | --input)
			INPUT="$2"
			CUSTOM_INPUT=1
			shift 2
			;;
		-o | --output)
			OUTPUT="$2"
			CUSTOM_OUTPUT=1
			shift 2
			;;
		-t | --theme)
			if [ "$2" = "dark" ]; then
				THEME="dark"
				if [ $CUSTOM_CSS_PATH -eq 0 ]; then
					CSS_PATH=("./github-markdown-dark.css")
				fi
			fi
			shift 2
			;;
		-y | --yes)
			PROMPT="y"
			YES=1
			shift
			;;
		*)
			INPUT="$1"
			CUSTOM_INPUT=1
			shift
			;;
	esac
done

# Check if overwrite
if [ $CUSTOM_OUTPUT -eq 1 ] && [ -e "$OUTPUT" ]; then
	if [ $YES -eq 0 ]; then
		echo -n "File $OUTPUT already exists. Overwrite it? [y/N] "
		read -r PROMPT
	fi
	if [ "$PROMPT" = "y" ]; then
		echo -n "" > "$OUTPUT"
	else
		exit 1
	fi
fi

# Prompt to download CSS file if not in CWD/specified CSS_PATH (don't try if css link is a URL)
for path in "${CSS_PATH[@]}"; do
	echo "$path" | grep -Eq "http[s]?://"
	if [ $? -eq 1 ] && [ ! -e "$path" ]; then
		if [ $YES -eq 0 ]; then
			echo -n "Download github-markdown-$THEME.css to $path? [Y/n] "
			read -r PROMPT
		fi
		if [ ! "$PROMPT" = "n" ]; then
			wget "$CSS_LINK_DIR/github-markdown-$THEME.css" -O "$path"
		fi
	fi
done

# Add meta lines to OUTPUT
echo "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">" >> "$OUTPUT"

# Add each specified CSS source

for path in "${CSS_PATH[@]}"; do
	echo "<link rel=\"stylesheet\" href=\"$path\">" >> "$OUTPUT"
done

# Add JS script sources, if enabled
if [ $ENABLE_JS ]; then
	if [ "$THEME" = dark ]; then
		echo "<link rel=\"stylesheet\" href=\"https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.3.1/styles/github-dark.min.css\">" >> "$OUTPUT"
	else
		echo "<link rel=\"stylesheet\" href=\"https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.3.1/styles/github.min.css\">" >> "$OUTPUT"
	fi
	echo "<script src=\"https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.3.1/highlight.min.js\"></script>" >> "$OUTPUT"
	echo "<script>hljs.highlightAll();</script>" >> "$OUTPUT"
fi

echo "<style>" >> "$OUTPUT"
echo "	.markdown-body {" >> "$OUTPUT"
echo "		box-sizing: border-box;" >> "$OUTPUT"
echo "		min-width: 200px;" >> "$OUTPUT"
echo "		max-width: 980px;" >> "$OUTPUT"
echo "		margin: 0 auto;" >> "$OUTPUT"
echo "		padding: 45px;" >> "$OUTPUT"
echo "	}" >> "$OUTPUT"
echo "" >> "$OUTPUT"
echo "	@media (max-width: 767px) {" >> "$OUTPUT"
echo "		.markdown-body {" >> "$OUTPUT"
echo "			padding: 15px;" >> "$OUTPUT"
echo "		}" >> "$OUTPUT"
echo "	}" >> "$OUTPUT"
echo "</style>" >> "$OUTPUT"
echo "<article class=\"markdown-body\">" >> "$OUTPUT"

# Add body (from markdown) using compiler (default is marked --gfm)
$COMPILER "$INPUT" >> "$OUTPUT"

# Close output
echo "</article>" >> "$OUTPUT"
