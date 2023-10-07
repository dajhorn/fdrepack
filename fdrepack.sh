#!/bin/bash
# fdrepack.sh: FreeDOS repository repacking script.
#
# This script recompresses zip files to make them smaller.

shopt -s nocaseglob nocasematch

fdrepack ()
{
	TMPDIR=$(mktemp -d)
	pushd "$TMPDIR" >/dev/null
	unzip -q "$1"

	if [[ -d 'SOURCE' ]]
	then
		pushd 'SOURCE' >/dev/null
		for ii in *.7z
		do
			if [[ -r "$ii" ]]
			then
				# Force the source package name to uppercase.
				mkdir $(basename "${ii@U}" '.7Z')
				pushd $(basename "${ii@U}" '.7Z') >/dev/null
				7z x "../$ii"
				popd >/dev/null
				rm "$ii"
			fi
		done
		
		for ii in *.zip
		do
			if [[ -r "$ii" ]]
			then
				# Force the source package name to uppercase.
				mkdir $(basename "${ii@U}" '.ZIP')
				pushd $(basename "${ii@U}" '.ZIP') >/dev/null
				unzip -q "../$ii"
				popd >/dev/null
				rm "$ii"
			fi
		done

		for ii in *
		do
			[[ -d "$ii" ]] || continue
			if pushd "$ii" >/dev/null
			then				
				for jj in *
				do
					# Unpack and delete old LFN source archives.
					case "$jj" in
						SOURCES.7Z)
							7z x "$jj"
							rm "$jj"
							;;
						SOURCES.ZIP)
							unzip -q "$jj"
							rm "$jj"
							;;
					esac				
				done
				
				# Using the store method here makes upstream sources solid in the package zip.
				advzip --add --shrink-store --quiet "../${ii@U}.ZIP" *
				
				popd >/dev/null
				rm -r "$ii"
			fi
		done
		popd >/dev/null
	fi

	# REARJ 3.10 (nb: the Linux build has janky date and path handling)
	#arj a -jm "${1}.repack" $(find -type f)

	# RAR 2.90 for Linux is compatible with the 16-bit RAR 2.50 for DOS.
	#/opt/rarlnx29/rar a -idp -m5 -mdE -s -r "${1}.repack"

	# 7-Zip LZMA1 (nb: this slightly outperforms the default LZMA2 configuration)
	#7z a -t7z -bd -m0=lzma -myx=9 -mfb=255 -md=1G -ms=on -mqs=on -mlc=4 -mmc=65536 -mf=off -mtm=on -y -r "${1}.repack" 

	# InfoZIP Deflate 
	#zip -0Xkoqr "${1}.repack"

	# InfoZIP BZIP2
	#zip -Zb -9Xkoqr "${1}.repack"
	
	# AdvanceCOMP zopfli
	#advzip --add --shrink-insane -i 255 --quiet "${1}.repack" *

	# AdvanceCOMP libdeflate
	advzip --add --shrink-normal --quiet "${1}.repack" *
	
	mv -f "${1}.repack" "${1}"
	popd >/dev/null
	rm -r "$TMPDIR"
}

export -f fdrepack

find ~+ -type f -iname \*.zip | parallel --verbose fdrepack