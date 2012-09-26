web: bundle exec thin start -p $PORT -l -
resque: bundle exec rake environment resque:work VVERBOSE=1 TERM_CHILD=1 QUEUE=send_sms
