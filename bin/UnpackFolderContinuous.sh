#cd $1
clear

doall=0
case $2 in
  -a)
  doall=1
esac

source ~/bin/env-standalone-32bits.sh

while [ 1 ]
do
ls -l *.hld*
echo
for file in *.hld
  do 
  filesize=$(stat -c%s "$file")
  echo "Size of $file = $filesize bytes."
  if (($filesize > 1610600000 || doall))
  then
    echo "doing $file"
    mv $file $file.processing 
    unpackerpetDAQ_v2_Deployed_32bits $file.processing 1e7 ./ ./ 
    rm $file.processing
#    gzip -v *.processed
  else
    echo "Skipping"
  fi
done
sleep 60
echo 
done
