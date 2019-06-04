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
    unpackerpetDAQ_v2b_Deployed_32bits $file 1e7 ./ ./ 
    rm $file
#    mv $file $file.processed 
#    gzip -v *.processed
  else
    echo "Skipping"
  fi
done
sleep 60
echo 
done
