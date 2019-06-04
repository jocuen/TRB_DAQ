#!/bin/bash
# Created  04/08/2017 Marcos Seco

PATH=$PATH:/home/trasgo/bin
INPUTPATH="/home/trasgo/data/test01"
#=========================================================

if [[ ".$1" == "." ]]; then
   fileList="$INPUTPATH/done1/*"
else
   fileList="$@"
fi

for trFile in ${fileList};do
  fileName=$(basename ${trFile})
  mv -v ${trFile} $INPUTPATH/done
  ln -v $INPUTPATH/done/${fileName} $INPUTPATH/done/alberto/T01T02T03/20150107/done
  chmod g+w $INPUTPATH/done/${fileName}
done
