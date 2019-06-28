#!/bin/bash
# Based on a post in 
# https://stackoverflow.com/questions/33466130/linux-create-animated-gif-with-pan-and-zoom
usage()
{
    cat <<EOF
Usage: $0 -f filename -z zoom_factor -x x_center -y y_center -t gif_duration [-d delay] [-h show help]

OPTIONS:
-h Show this message
-f Name of the file to be parsed
-z how much to zoom (divide the dimension by this argument)
-x which x of the point to center to
-y which y of the point to center to
-t duration of the new gif
-d delay of each frame of the gif in cs
EOF
}

#default values
filename=test.gif
zoom_factor=2
x=50
y=50
time=2
delay=0

while getopts "hf:z:x:y:t:d:" OPTION; do
    case $OPTION in
        h) usage
           exit
            ;;
        f) filename=$OPTARG
            ;;
        z) zoom_factor=$OPTARG
            ;;
        x) x=$OPTARG
            ;;
        y) y=$OPTARG
            ;;
        t) time=$OPTARG
            ;;
        d) delay=$OPTARG
            ;;
    esac
done


if [[ $delay -eq 0 ]]; then
    delay=$(identify -verbose -format "Frame %s: %Tcs | Duration: %[Iterations]\n" $filename | grep -P -o "(?<=Frame 0: )\d+")
fi
# if no delay has been set, revert to a default
if [[ $delay -eq 0 ]]; then
    delay=3
fi

steps=$(( time * 100 / delay))

frames=$(identify $filename | wc -l)

temp=$(identify -format "%[w] x %[h]\n" $filename)
initw=$(echo $temp | grep -P -o  "[0-9^\t]+" | head -n 1)
inith=$(echo $temp | grep -P -o  "[0-9^\t]+" | tail -n 1)


# Initial & Final width
finalw=$(( initw / zoom_factor ))
# Initial & Final height
finalh=$(( inith / zoom_factor ))

echo $finalw
echo $finalh

# Final x offset from top left
finalx=$(( x - finalw / 2 ))
# Final y offset from top left
finaly=$(( y - finalh / 2 ))

if [[ $finalx -lt 0 ]]; then
    finalx=0
fi

if [[ $finaly -lt 0 ]]; then
    finaly=0
fi

convert -coalesce $filename out%d.jpeg

# Remove anything from previous attempts
rm frame-*jpg 2> /dev/null
for i in $(seq 0 $steps); do
    ((x=finalx*i/steps))
    ((y=finaly*i/steps))
    ((w=initw-(i*(initw-finalw)/steps)))
    ((h=inith-(i*(inith-finalh)/steps)))
    echo $i,$x,$y,$w,$h
    name=$(printf "frame-%03d.jpg" $i)
    let filenumber=$(($i%$frames))
    convert out${filenumber}.jpeg -crop ${w}x${h}+${x}+${y} -resize ${initw}x${inith} "$name"
done
convert -delay $delay frame* anim.gif

convert anim.gif -coalesce -fuzz 2% +dither -remap anim.gif[0] -layers Optimize result.gif
convert -rotate 90 result.gif result1.gif
convert -rotate 180 result.gif result2.gif
convert -rotate 270 result.gif result3.gif
convert -rotate 125 result.gif result4.gif

rm frame*
rm out*