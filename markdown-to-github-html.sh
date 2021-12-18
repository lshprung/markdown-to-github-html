#!/usr/bin/sh

NAME="$0"
CSS_LINK="https://raw.githubusercontent.com/sindresorhus/github-markdown-css/gh-pages/github-markdown.css"
INPUT="/dev/stdin"
CUSTOM_INPUT=0
OUTPUT="/dev/stdout"
CUSTOM_OUTPUT=0
COMPILER="marked --gfm"
YES=0 #Set to 1 for --yes flag

print_help() {
	echo "Usage: $NAME [OPTION]... [INPUT]"
	echo "Compile INPUT markdown file to github-styled html"
	echo ""
	echo "      --compiler [COMPILER]	set the markdown compiler to use. Default is marked --gfm"
	echo "  -h, --help			print this help message"
	echo "  -i, --input [INPUT]		specify INPUT file"
	echo "  -o, --output [OUTPUT]		output to specified OUTPUT file"
	echo "  -y, --yes 			automatic yes to prompts"
}

# Parse arguments
while [ $# -gt 0 ]; do
	case $1 in
		--compiler)
			COMPILER="$2"
			shift 2
			;;
		-h | --help)
			print_help
			exit 1
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

# Prompt to download CSS file if not in CWD or same directory as NAME
if [ ! -e "github-markdown.css" ] || [ ! -e "$(dirname "$NAME")/github-markdown.css" ]; then
	if [ $YES -eq 0 ]; then
		echo -n "Download github-markdown.css to current working directory? [Y/n] "
		read -r PROMPT
	fi
	if [ ! "$PROMPT" = "n" ]; then
		wget "$CSS_LINK"
	fi
fi

# Add meta, link, and style lines to OUTPUT
echo "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">" >> "$OUTPUT"
echo "<link rel=\"stylesheet\" href=\"github-markdown.css\">" >> "$OUTPUT"
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
# TODO work on getting syntax highlighting support
$COMPILER "$INPUT" >> "$OUTPUT"

# Close output
echo "</article>" >> "$OUTPUT"
