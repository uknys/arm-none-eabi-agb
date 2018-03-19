
#!/bin/bash
#---------------------------------------------------------------------------------
# strip binaries
# strip has trouble using wildcards so do it this way instead
#---------------------------------------------------------------------------------

if [ ! -z $CROSSBUILD ]; then
	HOST_STRIP=$CROSSBUILD-strip
else
	HOST_STRIP=strip
fi

for f in /opt/devkitAGB/bin/* \
         /opt/devkitAGB/arm-none-eabi/bin/* \
         /opt/devkitAGB/libexec/gcc/arm-none-eabi/7.3.0/*
do
	# exclude dll for windows, so for linux/osx, directories .la files, embedspu script & the gccbug text file
	if  ! [[ "$f" == *.dll || "$f" == *.so || -d $f || "$f" == *.la || "$f" == *-embedspu || "$f" == *-gccbug ]]
	then
		$HOST_STRIP $f
	fi
	if [[ "$f" == *.dll ]]
	then
		$HOST_STRIP -d $f
	fi
done

if [ $VERSION -eq 2 ]; then
	for f in	/opt/devkitAGB/mn10200/bin/*
	do
		$HOST_STRIP $f
	done
fi


#---------------------------------------------------------------------------------
# strip debug info from libraries
#---------------------------------------------------------------------------------
find /opt/devkitAGB/lib/gcc/arm-none-eabi -name *.a -exec arm-none-eabi-strip -d {} \;
find /opt/devkitAGB/arm-none-eabi -name *.a -exec arm-none-eabi-strip -d {} \;
