create_email()
{
	# Subject will have format <abbreviated revid>: <First line of commit comment>
	subj="$SERVER ($TYPE from $OLD ENCRYPTION=$ENCRYPTION COMPRESSION=$COMPRESSION PAGE_SIZE=$PAGE_SIZE)"

	cat <<-EOF
	To: $EMAIL_NOTIFICATION
	Subject: $subj
	MIME-Version: 1.0
	Content-Type: text/plain; charset=utf-8
	Content-Transfer-Encoding: 8bit

	EOF
	perl $TRAVIS_BUILD_DIR/scripts/parse_upgrade_logs.pl --mode=kb --nowarnings $HOME/logs/trial*

}

if [ -n "$EMAIL_NOTIFICATION" ] ; then
  create_email | ${mailer:-/usr/sbin/sendmail} -t -f "$sender"
fi
