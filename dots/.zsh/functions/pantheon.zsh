# Pantheon-specific Functions  
# Source: Modularized from ~/.functions

# Get Terminus authentication token
terminus_token() {
  TOKEN=$(grep -o '"token":"[^"]*' ~/.terminus/cache/tokens/lindsey.catlett@getpantheon.com | grep -o '[^"]*$')
  echo $TOKEN
}
alias terminus-token='terminus_token'

# Run MySQLTuner on a Pantheon site
db_tuner_full() {
  SITE=$1
  TERM_DATA=$(terminus connection:info $SITE --format=string --fields=mysql_host,mysql_username,mysql_password,mysql_port)
  DB_FIELDS=($(echo $TERM_DATA))

    /opt/homebrew/bin/mysqltuner \
    --forcemem 32000 \
    --host ${DB_FIELDS[1]} \
    --user ${DB_FIELDS[2]} \
    --pass ${DB_FIELDS[3]} \
    --port ${DB_FIELDS[4]} \
    --verbose \
    --outputfile $SITE-db-tuner-$(date +"%Y-%m-%d-%H-%M-%S").txt
}
alias db-tuner-full='db_tuner_full'

# Run MySQLTuner with index stats
db-tuner-idx() {
  SITE=$1
  TERM_DATA=$(terminus connection:info $SITE --format=string --fields=mysql_host,mysql_username,mysql_password,mysql_port)
  DB_FIELDS=($(echo $TERM_DATA))

   /opt/homebrew/bin/mysqltuner \
    --forcemem 32000 \
    --host ${DB_FIELDS[1]} \
    --user ${DB_FIELDS[2]} \
    --pass ${DB_FIELDS[3]} \
    --port ${DB_FIELDS[4]} \
    --buffers --dbstat --idxstat --sysstat --pfstat \
    --outputfile $SITE-db-tuner-idx-$(date +"%Y-%m-%d-%H-%M-%S").txt
}

# Percona Toolkit MySQL summary
pat-mysql-summary() {
  SITE=$1
  TERM_DATA=$(terminus connection:info $SITE --format=string --fields=mysql_host,mysql_username,mysql_password,mysql_port)
  DB_FIELDS=($(echo $TERM_DATA))

  pt-mysql-summary \
    --host ${DB_FIELDS[1]} \
    --user ${DB_FIELDS[2]} \
    --password ${DB_FIELDS[3]} \
    --port ${DB_FIELDS[4]} \
    --databases pantheon
}

# Percona Toolkit variable advisor
pat-variable-advisor() {
  SITE=$1
  TERM_DATA=$(terminus connection:info $SITE --format=string --fields=mysql_host,mysql_username,mysql_password,mysql_port)
  DB_FIELDS=($(echo $TERM_DATA))

  pt-variable-advisor \
    --host ${DB_FIELDS[1]} \
    --user ${DB_FIELDS[2]} \
    --password ${DB_FIELDS[3]} \
    --port ${DB_FIELDS[4]}
}

# Percona Toolkit index usage
pat-index-usage() {
   SITE=$1
  TERM_DATA=$(terminus connection:info $SITE --format=string --fields=mysql_host,mysql_username,mysql_password,mysql_port)
  DB_FIELDS=($(echo $TERM_DATA))

  pt-index-usage \
    pt-index-usage \
    --host ${DB_FIELDS[1]} \
    --user ${DB_FIELDS[2]} \
    --password ${DB_FIELDS[3]} \
    --port ${DB_FIELDS[4]} \
    --databases pantheon
}
