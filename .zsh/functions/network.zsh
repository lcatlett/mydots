# Network and Debugging Functions
# Source: Modularized from ~/.functions

## curlheader will return only a specific response header or all response headers for a given URL
## usage: curlheader $header $url
## usage: curlheader $url
curlheader() {
  if [[ -z "$2" ]]; then
    echo "curl -k -s -D - $1 -o /dev/null"
    curl -k -s -D - $1 -o /dev/null:
  else
    echo "curl -k -s -D - $2 -o /dev/null | grep $1:"
    curl -k -s -D - $2 -o /dev/null | grep $1:
  fi
}

## get the timings for a curl to a URL
## usage: curltime $url
curltime(){
  curl -w "   time_namelookup:  %{time_namelookup}\n\
      time_connect:  %{time_connect}\n\
   time_appconnect:  %{time_appconnect}\n\
  time_pretransfer:  %{time_pretransfer}\n\
     time_redirect:  %{time_redirect}\n\
time_starttransfer:  %{time_starttransfer}\n\
--------------------------\n\
        time_total:  %{time_total}\n" -o /dev/null -s "$1"
}

# httpDebug: Function to download a web page and show info on what took time
httpDebug() { 
  /usr/bin/curl "$@" -o /dev/null -w "dns: %{time_namelookup} connect: %{time_connect} pretransfer: %{time_pretransfer} starttransfer: %{time_starttransfer} total: %{time_total}\\n"
}
